/* ============================================================================
 *  text_extraction2 -- C (x64) port of the VB6 mirror
 *  examples\Vb6\content_parser\text_extraction2\text_extraction2.bas
 *  Extracts the text of a PDF file by driving pdfParseContent() with a
 *  TPDFParseInterface of stdcall callbacks. The single CPDFToText/CStack
 *  instance is flattened into module-level globals. Output is out.txt as
 *  UTF-16LE (with BOM).
 * ========================================================================== */
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include "lumaspdf.h"

#define IN_FILE "E:\\LUMASPDFSDK\\sample_multipage.pdf"

/* TTextDir */
#define tfNotInitialized 5

#define MAX_LINE_ERROR 4.0    /* square of the allowed error (2 * 2) */

typedef struct {
    PFNT   ActiveFont;
    float  CharSpacing;
    float  FontSize;
    SI32   FontType;
    TCTM   Matrix;
    float  SpaceWidth;
    SI32   TextDrawMode;
    float  TextScale;
    float  WordSpacing;
} TGState;

/* CPDFToText member fields (flattened). */
static PPDF    m_PDF;
static FILE*   m_File;
static TGState m_GState;
static SI32    m_LastTextDir;
static double  m_LastTextEndX, m_LastTextEndY;
static double  m_LastTextInfX, m_LastTextInfY;

/* CStack (flattened). */
static TGState* m_StackItems = NULL;
static SI32     m_StackCount = 0;
static SI32     m_StackCapacity = 0;

/* ------------------------- error callback ------------------------- */
static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    printf("%s\n", ErrMessage ? ErrMessage : "");
    return 0;
}

static void exedir(const char* a0, char* out, size_t n)
{
    char* s;
    strncpy(out, a0, n - 1); out[n - 1] = 0;
    s = strrchr(out, '\\'); if (!s) s = strrchr(out, '/');
    if (s) *s = 0; else strcpy(out, ".");
}

/* ------------------------- output helpers ------------------------- */
static void WriteWStr(const char* s)
{
    unsigned char two[2];
    while (*s) {
        two[0] = (unsigned char)*s++;
        two[1] = 0;
        fwrite(two, 1, 2, m_File);
    }
}

static void WriteWCharsFromPtr(LWCHAR* Ptr, SI32 WCharCount)
{
    if (Ptr == NULL || WCharCount <= 0) return;
    fwrite(Ptr, 2, (size_t)WCharCount, m_File);
}

/* ------------------------- CStack ------------------------- */
static int StackRestore(TGState* F)
{
    if (m_StackCount > 0) {
        m_StackCount--;
        *F = m_StackItems[m_StackCount];
        return 1;
    }
    return 0;
}

static SI32 StackSave(const TGState* F)
{
    if (m_StackCount == m_StackCapacity) {
        m_StackCapacity += 28;
        m_StackItems = (TGState*)realloc(m_StackItems, m_StackCapacity * sizeof(TGState));
    }
    m_StackItems[m_StackCount] = *F;
    m_StackCount++;
    return 0;
}

/* ------------------------- matrix helpers ------------------------- */
static TCTM MulMatrix(const TCTM* M1, const TCTM* M2)
{
    TCTM r;
    r.a = M2->a * M1->a + M2->b * M1->c;
    r.b = M2->a * M1->b + M2->b * M1->d;
    r.c = M2->c * M1->a + M2->d * M1->c;
    r.d = M2->c * M1->b + M2->d * M1->d;
    r.x = M2->x * M1->a + M2->y * M1->c + M1->x;
    r.y = M2->x * M1->b + M2->y * M1->d + M1->y;
    return r;
}

static void Transform(const TCTM* M, double* x, double* y)
{
    double tx = *x;
    *x = tx * M->a + *y * M->c + M->x;
    *y = tx * M->b + *y * M->d + M->y;
}

static double CalcDistance(double x1, double y1, double x2, double y2)
{
    double dx = x2 - x1, dy = y2 - y1;
    return sqrt(dx * dx + dy * dy);
}

static int IsPointOnLine(double x, double y, double x0, double y0, double x1, double y1)
{
    double dx, dy, di;
    x = x - x0; y = y - y0;
    dx = x1 - x0; dy = y1 - y0;
    di = (x * dx + y * dy) / (dx * dx + dy * dy);
    if (di < 0.0) di = 0.0;
    else if (di > 1.0) di = 1.0;
    dx = x - di * dx;
    dy = y - di * dy;
    di = dx * dx + dy * dy;
    return (di < MAX_LINE_ERROR);
}

/* ------------------------- CPDFToText methods ------------------------- */
static int DoRestoreGState(void) { return StackRestore(&m_GState); }
static SI32 DoSaveGState(void) { return StackSave(&m_GState); }

static void ResetGState(void)
{
    m_GState.ActiveFont = NULL;
    m_GState.CharSpacing = 0.0f;
    m_GState.FontSize = 1.0f;
    m_GState.FontType = ftType1;
    m_GState.Matrix.a = 1.0; m_GState.Matrix.b = 0.0;
    m_GState.Matrix.c = 0.0; m_GState.Matrix.d = 1.0;
    m_GState.Matrix.x = 0.0; m_GState.Matrix.y = 0.0;
    m_GState.SpaceWidth = 0.0f;
    m_GState.TextDrawMode = dmNormal;
    m_GState.TextScale = 100.0f;
    m_GState.WordSpacing = 0.0f;
}

static void DoInit(void)
{
    while (DoRestoreGState()) { }
    ResetGState();
    m_LastTextDir = tfNotInitialized;
    m_LastTextEndX = 0.0; m_LastTextEndY = 0.0;
    m_LastTextInfX = 0.0; m_LastTextInfY = 0.0;
}

static void DoSetFont(PFNT IFont, SI32 FontType, double FontSize)
{
    m_GState.ActiveFont = IFont;
    m_GState.FontSize = (float)FontSize;
    m_GState.FontType = FontType;
    m_GState.SpaceWidth = (float)fntGetSpaceWidth(IFont, FontSize);
    if (FontSize < 0.0) m_GState.SpaceWidth = -m_GState.SpaceWidth;
}

static void DoWritePageIdentifier(SI32 PageNum)
{
    char buf[128];
    if (PageNum > 1) WriteWStr("\r\n");
    sprintf(buf, "%%----------------------- Page %d -----------------------------\r\n", PageNum);
    WriteWStr(buf);
}

/* ------------------------- text reconstruction (AddText) ------------------------- */
static SI32 DoAddText(const TCTM* Matrix, TTextRecordWPtr Kerning, UI32 Count,
                      double Widen, LBOOL Decoded)
{
    UI32 i;
    double x1, x2, x3, y1, y2, y3, distance, spaceWidth;
    SI32 textDir;
    TCTM m;
    float spw;

    if (Decoded == 0) return 0;

    x1 = 0.0; y1 = 0.0;
    x2 = 0.0; y2 = m_GState.FontSize;
    m = MulMatrix(&m_GState.Matrix, Matrix);
    Transform(&m, &x1, &y1);
    Transform(&m, &x2, &y2);

    if (y1 == y2)
        textDir = ((x1 > x2 ? 1 : 0) + 1) * 2;
    else
        textDir = (y1 > y2 ? 1 : 0);

    if ((textDir != m_LastTextDir) ||
        (!IsPointOnLine(x1, y1, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY))) {
        m_LastTextInfX = 1000000.0;
        m_LastTextInfY = 0.0;
        Transform(&m, &m_LastTextInfX, &m_LastTextInfY);
        if (m_LastTextDir != tfNotInitialized) WriteWStr("\r\n");
    } else {
        x3 = m_GState.SpaceWidth; y3 = 0.0;
        Transform(&m, &x3, &y3);
        spaceWidth = CalcDistance(x1, y1, x3, y3);
        distance = CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1);
        if (distance > spaceWidth) WriteWStr(" ");
    }

    spw = -m_GState.SpaceWidth * 0.5f;
    for (i = 0; i < Count; i++) {
        TTextRecordW rec = Kerning[i];
        if (rec.Advance < spw) WriteWStr(" ");
        WriteWCharsFromPtr(rec.Text, rec.Length);
    }

    m_LastTextEndX = Widen + spw;   /* spw is negative */
    m_LastTextEndY = 0.0;
    m_LastTextDir = textDir;
    Transform(&m, &m_LastTextEndX, &m_LastTextEndY);
    return 0;
}

/* ============================================================================
 *  parse* callback thunks (Data pointer is ignored).
 * ========================================================================== */
static SI32 PDF_CALL parseBeginTemplate(void* Data, void* PDFObject, SI32 Handle,
                                        TPDFRect* BBox, PCTM Matrix)
{
    (void)Data; (void)PDFObject; (void)Handle; (void)BBox;
    if (DoSaveGState() < 0) return -1;
    if (Matrix != NULL)
        m_GState.Matrix = MulMatrix(&m_GState.Matrix, Matrix);
    return 0;
}
static void PDF_CALL parseEndTemplate(void* Data) { (void)Data; DoRestoreGState(); }
static void PDF_CALL parseMulMatrix(void* Data, void* PDFObject, TCTM* Matrix)
{ (void)Data; (void)PDFObject; m_GState.Matrix = MulMatrix(&m_GState.Matrix, Matrix); }
static SI32 PDF_CALL parseRestoreGraphicState(void* Data) { (void)Data; DoRestoreGState(); return 0; }
static SI32 PDF_CALL parseSaveGraphicState(void* Data) { (void)Data; DoSaveGState(); return 0; }
static void PDF_CALL parseSetCharSpacing(void* Data, void* PDFObject, double Value)
{ (void)Data; (void)PDFObject; m_GState.CharSpacing = (float)Value; }
static void PDF_CALL parseSetFont(void* Data, void* PDFObject, TFontType FontType, LBOOL Embedded,
                                  const char* FontName, TFStyle Style, double FontSize, PFNT Font)
{ (void)Data; (void)PDFObject; (void)Embedded; (void)FontName; (void)Style;
  DoSetFont(Font, FontType, FontSize); }
static void PDF_CALL parseSetTextDrawMode(void* Data, void* PDFObject, TDrawMode Mode)
{ (void)Data; (void)PDFObject; m_GState.TextDrawMode = Mode; }
static void PDF_CALL parseSetTextScale(void* Data, void* PDFObject, double Value)
{ (void)Data; (void)PDFObject; m_GState.TextScale = (float)Value; }
static void PDF_CALL parseSetWordSpacing(void* Data, void* PDFObject, double Value)
{ (void)Data; (void)PDFObject; m_GState.WordSpacing = (float)Value; }
static SI32 PDF_CALL parseShowTextArrayW(void* Data, TTextRecordAPtr Source, TCTM* Matrix,
                                         TTextRecordWPtr Kerning, UI32 Count, double Width, LBOOL Decoded)
{ (void)Data; (void)Source; return DoAddText(Matrix, Kerning, Count, Width, Decoded); }

/* ============================================================================
 *  Main flow
 * ========================================================================== */
int main(int argc, char** argv)
{
    PPDF pdf;
    TPDFParseInterface stack;
    char dir[1024], inFile[1200], outFile[1200], cmapDir[1200];
    unsigned char bom[2];
    int i, pc;

    exedir(argv[0], dir, sizeof(dir));

    pdf = pdfNewPDF();
    m_PDF = pdf;
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    sprintf(cmapDir, "%s\\CMap", dir);
    pdfSetCMapDirA(pdf, cmapDir, lcmRecursive | lcmDelayed);

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);

    strcpy(inFile, IN_FILE);
    if (pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0) {
        printf("Input file \"%s\" not found!\n", inFile);
        pdfDeletePDF(pdf);
        return 0;
    }
    if (pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0) {
        pdfDeletePDF(pdf);
        return 0;
    }

    pdfFlattenAnnots(pdf, affMarkupAnnots);
    pdfFlattenForm(pdf);

    memset(&stack, 0, sizeof(stack));
    stack.BeginTemplate = parseBeginTemplate;
    stack.EndTemplate = parseEndTemplate;
    stack.MulMatrix = parseMulMatrix;
    stack.RestoreGraphicState = parseRestoreGraphicState;
    stack.SaveGraphicState = parseSaveGraphicState;
    stack.SetCharSpacing = parseSetCharSpacing;
    stack.SetFont = parseSetFont;
    stack.SetTextDrawMode = parseSetTextDrawMode;
    stack.SetTextScale = parseSetTextScale;
    stack.SetWordSpacing = parseSetWordSpacing;
    stack.ShowTextArrayW = parseShowTextArrayW;

    sprintf(outFile, "%s\\out.txt", dir);
    m_File = fopen(outFile, "wb");
    if (!m_File) {
        printf("Cannot create output file %s\n", outFile);
        pdfDeletePDF(pdf);
        return 0;
    }
    bom[0] = 0xFF; bom[1] = 0xFE;     /* UTF-16LE BOM */
    fwrite(bom, 1, 2, m_File);

    pc = pdfGetPageCount(pdf);
    for (i = 1; i <= pc; i++) {
        pdfEditPage(pdf, i);
        DoInit();
        DoWritePageIdentifier(i);
        pdfParseContent(pdf, 0, &stack, pfNone);
        pdfEndPage(pdf);
    }
    fclose(m_File);

    printf("Text successfully extracted to %s\n", outFile);
    pdfDeletePDF(pdf);
    return 0;
}

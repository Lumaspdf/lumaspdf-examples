/* ============================================================================
 *  text_coordinates -- C (x64) port of the VB6 mirror
 *  examples\Vb6\content_parser\text_coordinates\text_coordinates.bas
 *  Imports dynapdf_help.pdf; for every page runs pdfParseContent with a
 *  callback interface. The MarkText callback draws lines under each text record
 *  to visualise the computed text coordinates, alternating stroke colour
 *  blue/red for successive text records. Output is out.pdf.
 *  The single OO instance is flattened to module-level globals.
 * ========================================================================== */
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include "lumaspdf.h"

#define IN_FILE "E:\\LUMASPDFSDK\\dynapdf_help.pdf"

/* VCL COLORREF colours (BGR). */
#define clRed  0x0000FFu
#define clBlue 0xFF0000u

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

/* CTextCoordinates state (single instance). */
static PPDF    m_PDF;
static SI32    m_Count;
static TGState m_GState;

/* CStack state. */
static TGState* m_Items = NULL;
static SI32     m_StackCap = 0;
static SI32     m_StackCount = 0;

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

static void Transform(const TCTM* m, double* x, double* y)
{
    double tx = *x;
    *x = tx * m->a + *y * m->c + m->x;
    *y = tx * m->b + *y * m->d + m->y;
}

/* ------------------------- CStack ------------------------- */
static int RestoreGState(void)
{
    if (m_StackCount > 0) {
        m_StackCount--;
        m_GState = m_Items[m_StackCount];
        return 1;
    }
    return 0;
}

static SI32 SaveGState(void)
{
    if (m_StackCount == m_StackCap) {
        m_StackCap += 28;
        m_Items = (TGState*)realloc(m_Items, m_StackCap * sizeof(TGState));
    }
    m_Items[m_StackCount] = m_GState;
    m_StackCount++;
    return 0;
}

/* ------------------------- CTextCoordinates ------------------------- */
static void ResetGState(void)
{
    m_GState.ActiveFont = NULL;
    m_GState.CharSpacing = 0.0f;
    m_GState.FontSize = 1.0f;
    m_GState.FontType = ftType1;
    m_GState.Matrix.a = 1.0; m_GState.Matrix.b = 0.0;
    m_GState.Matrix.c = 0.0; m_GState.Matrix.d = 1.0;
    m_GState.Matrix.x = 0.0; m_GState.Matrix.y = 0.0;
    m_GState.TextDrawMode = dmNormal;
    m_GState.TextScale = 100.0f;
    m_GState.WordSpacing = 0.0f;
}

static void TCInit(void)
{
    while (RestoreGState()) { }
    m_Count = 0;
    ResetGState();
}

static SI32 BeginTemplateImpl(PCTM Matrix)
{
    if (SaveGState() < 0) return -1;
    if (Matrix != NULL)
        m_GState.Matrix = MulMatrix(&m_GState.Matrix, Matrix);
    return 0;
}

static void SetFontImpl(PFNT IFont, SI32 FontType, double FontSize)
{
    m_GState.ActiveFont = IFont;
    m_GState.FontSize = (float)FontSize;
    m_GState.FontType = FontType;
    m_GState.SpaceWidth = (float)fntGetSpaceWidth(IFont, FontSize);
}

/* CTextCoordinates.MarkText */
static SI32 MarkText(const TCTM* Matrix, TTextRecordAPtr Source, TTextRecordWPtr Kerning,
                     UI32 Count, double AWidth, LBOOL Decoded)
{
    UI32 i; SI32 j, last, rlen;
    double x1, x2, y1, y2, textWidth;
    TCTM m;
    (void)AWidth;

    if (Decoded == 0) return 0;

    x1 = 0.0; y1 = 0.0;
    m = MulMatrix(&m_GState.Matrix, Matrix);
    Transform(&m, &x1, &y1);

    textWidth = 0.0;
    x2 = 0.0; y2 = 0.0;

    if (m_GState.FontType == ftType0) {
        /* Word spacing must be ignored if a CID font is selected! */
        for (i = 0; i < Count; i++) {
            TTextRecordW krec = Kerning[i];
            if (krec.Advance != 0.0f) {
                textWidth = textWidth - krec.Advance;
                x1 = textWidth; y1 = 0.0;
                Transform(&m, &x1, &y1);
            }
            textWidth = textWidth + krec.Width;
            x2 = textWidth; y2 = 0.0;
            Transform(&m, &x2, &y2);
            pdfMoveTo(m_PDF, x1, y1);
            pdfLineTo(m_PDF, x2, y2);
            pdfSetStrokeColor(m_PDF, (m_Count & 1) ? clRed : clBlue);
            if (pdfStrokePath(m_PDF) == 0) return -1;
            x1 = x2; y1 = y2;
        }
    } else {
        for (i = 0; i < Count; i++) {
            TTextRecordA srec = Source[i];
            j = 0; last = 0;
            if (srec.Advance != 0.0f) {
                textWidth = textWidth - srec.Advance;
                x1 = textWidth; y1 = 0.0;
                Transform(&m, &x1, &y1);
            }
            rlen = srec.Length;
            if (srec.Text == NULL) rlen = 0;
            while (j < rlen) {
                if ((unsigned char)srec.Text[j] != 32) {
                    j++;
                } else {
                    if (j > last) {
                        textWidth += fntGetTextWidth(m_GState.ActiveFont, srec.Text + last,
                            (UI32)(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale);
                        x2 = textWidth; y2 = 0.0;
                        Transform(&m, &x2, &y2);
                        pdfMoveTo(m_PDF, x1, y1);
                        pdfLineTo(m_PDF, x2, y2);
                        pdfSetStrokeColor(m_PDF, (m_Count & 1) ? clRed : clBlue);
                        if (pdfStrokePath(m_PDF) == 0) return -1;
                    }
                    last = j;
                    j++;
                    while (j < rlen && (unsigned char)srec.Text[j] == 32) j++;
                    textWidth += fntGetTextWidth(m_GState.ActiveFont, srec.Text + last,
                        (UI32)(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale);
                    last = j;
                    x1 = textWidth; y1 = 0.0;
                    Transform(&m, &x1, &y1);
                }
            }
            if (j > last) {
                textWidth += fntGetTextWidth(m_GState.ActiveFont, srec.Text + last,
                    (UI32)(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale);
                x2 = textWidth; y2 = 0.0;
                Transform(&m, &x2, &y2);
                pdfMoveTo(m_PDF, x1, y1);
                pdfLineTo(m_PDF, x2, y2);
                pdfSetStrokeColor(m_PDF, (m_Count & 1) ? clRed : clBlue);
                if (pdfStrokePath(m_PDF) == 0) return -1;
            }
            x1 = x2; y1 = y2;
        }
    }
    m_Count++;
    return 0;
}

/* ------------------------- parse* callback thunks ------------------------- */
static SI32 PDF_CALL parseBeginTemplate(void* Data, void* PDFObject, SI32 Handle,
                                        TPDFRect* BBox, PCTM Matrix)
{
    (void)Data; (void)PDFObject; (void)Handle; (void)BBox;
    return BeginTemplateImpl(Matrix);
}
static void PDF_CALL parseEndTemplate(void* Data) { (void)Data; RestoreGState(); }
static void PDF_CALL parseMulMatrix(void* Data, void* PDFObject, TCTM* Matrix)
{
    (void)Data; (void)PDFObject;
    m_GState.Matrix = MulMatrix(&m_GState.Matrix, Matrix);
}
static SI32 PDF_CALL parseRestoreGraphicState(void* Data) { (void)Data; RestoreGState(); return 0; }
static SI32 PDF_CALL parseSaveGraphicState(void* Data) { (void)Data; SaveGState(); return 0; }
static void PDF_CALL parseSetCharSpacing(void* Data, void* PDFObject, double Value)
{ (void)Data; (void)PDFObject; m_GState.CharSpacing = (float)Value; }
static void PDF_CALL parseSetFont(void* Data, void* PDFObject, TFontType FontType, LBOOL Embedded,
                                  const char* FontName, TFStyle Style, double FontSize, PFNT Font)
{ (void)Data; (void)PDFObject; (void)Embedded; (void)FontName; (void)Style;
  SetFontImpl(Font, FontType, FontSize); }
static void PDF_CALL parseSetTextDrawMode(void* Data, void* PDFObject, TDrawMode Mode)
{ (void)Data; (void)PDFObject; m_GState.TextDrawMode = Mode; }
static void PDF_CALL parseSetTextScale(void* Data, void* PDFObject, double Value)
{ (void)Data; (void)PDFObject; m_GState.TextScale = (float)Value; }
static void PDF_CALL parseSetWordSpacing(void* Data, void* PDFObject, double Value)
{ (void)Data; (void)PDFObject; m_GState.WordSpacing = (float)Value; }
static SI32 PDF_CALL parseShowTextArrayW(void* Data, TTextRecordAPtr Source, TCTM* Matrix,
                                         TTextRecordWPtr Kerning, UI32 Count, double Width, LBOOL Decoded)
{ (void)Data; return MarkText(Matrix, Source, Kerning, Count, Width, Decoded); }

/* ------------------------- main ------------------------- */
int main(int argc, char** argv)
{
    PPDF pdf;
    TPDFParseInterface stack;
    char dir[1024], inFile[1200], outFile[1200], cmapDir[1200];
    int i, pc;

    exedir(argv[0], dir, sizeof(dir));

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

    pdf = pdfNewPDF();
    m_PDF = pdf;
    m_StackCount = 0;
    m_StackCap = 0;
    m_Count = 0;
    ResetGState();

    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    /* External cmaps should always be loaded when extracting text. */
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

    pc = pdfGetPageCount(pdf);
    for (i = 1; i <= pc; i++) {
        pdfEditPage(pdf, i);
        pdfSetLineWidth(pdf, 0.5);
        TCInit();
        pdfParseContent(pdf, 0, &stack, pfNone);
        pdfEndPage(pdf);
    }

    outFile[0] = 0;
    if (pdfHaveOpenDoc(pdf) != 0) {
        sprintf(outFile, "%s\\out.pdf", dir);
        if (pdfOpenOutputFileA(pdf, outFile) == 0) {
            pdfDeletePDF(pdf);
            return 0;
        }
    }
    if (pdfCloseFile(pdf) != 0)
        printf("PDF file \"%s\" successfully created!\n", outFile);

    pdfDeletePDF(pdf);
    return 0;
}

/* ============================================================================
 *  text_search -- C (x64) port of the VB6 mirror
 *  examples\Vb6\content_parser\text_search\text_search.bas
 *  Imports sample_multipage.pdf, searches for the Unicode string "PDF" across the
 *  content stream via pdfParseContent + a flattened CTextSearch state machine,
 *  and draws yellow multiply-blend rectangles over each match. Prints per-page
 *  and total hit counts. Output out.pdf.
 *
 *  IsPointOnLine keeps the div-by-zero guard for degenerate segments. C's ||
 *  already short-circuits, so the "wrong line" test is a direct translation.
 * ========================================================================== */
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include "lumaspdf.h"

#define IN_FILE "E:\\LUMASPDFSDK\\sample_multipage.pdf"

#define RGB(r,g,b) ((UI32)((unsigned char)(r) | ((unsigned char)(g) << 8) | ((unsigned char)(b) << 16)))

#define tfNotInitialized 5
#define MAX_LINE_ERROR 4.0

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
} GStateT;

/* CTextSearch flattened fields. */
static PPDF   m_PDF;

static PFNT   m_ActiveFont;
static float  m_CharSpacing;
static float  m_FontSize;
static SI32   m_FontType;
static TCTM   m_Matrix;
static float  m_SpaceWidth;
static SI32   m_TextDrawMode;
static float  m_TextScale;
static float  m_WordSpacing;

/* CStack. */
static GStateT* m_Items = NULL;
static SI32     m_Count = 0;
static SI32     m_Capacity = 0;

/* search / hit-tracking. */
static double  m_EndX1, m_EndY1, m_EndX4, m_EndY4;
static int     m_HavePos;
static SI32    m_LastTextDir;
static double  m_LastTextInfX, m_LastTextInfY;
static LWCHAR  m_OutBuf[32];
static LWCHAR* m_SearchChars = NULL;
static SI32    m_SearchTextLen;
static SI32    m_SearchPos;
static SI32    m_SelCount;
static double  m_x1, m_y1, m_x4, m_y4;

/* ------------------------- error callback + helpers ------------------------- */
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

/* ------------------------- matrix / geometry ------------------------- */
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
    if ((dx * dx + dy * dy) == 0.0) {
        /* Degenerate segment (single point); "on" it only if coincident. */
        return ((x * x + y * y) < MAX_LINE_ERROR);
    }
    di = (x * dx + y * dy) / (dx * dx + dy * dy);
    if (di < 0.0) di = 0.0;
    else if (di > 1.0) di = 1.0;
    dx = x - di * dx;
    dy = y - di * dy;
    di = dx * dx + dy * dy;
    return (di < MAX_LINE_ERROR);
}

/* ------------------------- search string handling ------------------------- */
static void SetSearchText(const char* Txt)
{
    SI32 i;
    m_SearchTextLen = (SI32)strlen(Txt);
    if (m_SearchTextLen > 0) {
        m_SearchChars = (LWCHAR*)realloc(m_SearchChars, m_SearchTextLen * sizeof(LWCHAR));
        for (i = 0; i < m_SearchTextLen; i++)
            m_SearchChars[i] = (LWCHAR)(unsigned char)Txt[i];
    }
    m_SearchPos = 0;
}

/* Code of the WideChar at the current search position, or 0 for terminator. */
static int SPCode(void)
{
    if (m_SearchPos >= m_SearchTextLen) return 0;
    return (int)m_SearchChars[m_SearchPos];
}

static void Reset_(void)
{
    m_HavePos = 0;
    m_SearchPos = 0;
}

/* Compares decoded WideChars against the search string, advancing position. */
static int Compare(LWCHAR* TextPtr, SI32 Len_)
{
    LWCHAR* endPtr = TextPtr + Len_;
    while (TextPtr < endPtr) {
        int wc = (int)*TextPtr;
        if (SPCode() != wc) {
            m_HavePos = 0;
            m_SearchPos = 0;
            return 0;
        }
        TextPtr++;
        m_SearchPos++;
        if (SPCode() == 0) {
            m_SearchPos = 0;
            return (TextPtr == endPtr);
        }
    }
    return 1;
}

/* ------------------------- graphics-state stack ------------------------- */
static SI32 SaveGState(void)
{
    GStateT* g;
    if (m_Count == m_Capacity) {
        m_Capacity += 28;
        m_Items = (GStateT*)realloc(m_Items, m_Capacity * sizeof(GStateT));
    }
    g = &m_Items[m_Count];
    g->ActiveFont = m_ActiveFont;
    g->CharSpacing = m_CharSpacing;
    g->FontSize = m_FontSize;
    g->FontType = m_FontType;
    g->Matrix = m_Matrix;
    g->SpaceWidth = m_SpaceWidth;
    g->TextDrawMode = m_TextDrawMode;
    g->TextScale = m_TextScale;
    g->WordSpacing = m_WordSpacing;
    m_Count++;
    return 0;
}

static int RestoreGState(void)
{
    GStateT* g;
    if (m_Count > 0) {
        m_Count--;
        g = &m_Items[m_Count];
        m_ActiveFont = g->ActiveFont;
        m_CharSpacing = g->CharSpacing;
        m_FontSize = g->FontSize;
        m_FontType = g->FontType;
        m_Matrix = g->Matrix;
        m_SpaceWidth = g->SpaceWidth;
        m_TextDrawMode = g->TextDrawMode;
        m_TextScale = g->TextScale;
        m_WordSpacing = g->WordSpacing;
        return 1;
    }
    return 0;
}

/* ------------------------- rectangle drawing ------------------------- */
static void SetStartCoord(const TCTM* Matrix, double x)
{
    m_x1 = x; m_y1 = 0.0;
    m_x4 = x; m_y4 = m_FontSize;
    Transform(Matrix, &m_x1, &m_y1);
    Transform(Matrix, &m_x4, &m_y4);
    m_HavePos = 1;
}

static int DrawRectEx(double x2, double y2, double x3, double y3)
{
    pdfMoveTo(m_PDF, m_x1, m_y1);
    pdfLineTo(m_PDF, x2, y2);
    pdfLineTo(m_PDF, x3, y3);
    pdfLineTo(m_PDF, m_x4, m_y4);
    m_HavePos = 0;
    m_SelCount++;
    return (pdfClosePath(m_PDF, fmFill) != 0);
}

static int DrawRect(const TCTM* Matrix, double EndX)
{
    double x2 = EndX, y2 = 0.0, x3 = EndX, y3 = m_FontSize;
    Transform(Matrix, &x2, &y2);
    Transform(Matrix, &x3, &y3);
    return DrawRectEx(x2, y2, x3, y3);
}

/* ------------------------- init / reset ------------------------- */
static void InitGState(void)
{
    while (RestoreGState()) { }
    m_ActiveFont = NULL;
    m_CharSpacing = 0.0f;
    m_FontSize = 1.0f;
    m_Matrix.a = 1.0; m_Matrix.b = 0.0; m_Matrix.c = 0.0;
    m_Matrix.d = 1.0; m_Matrix.x = 0.0; m_Matrix.y = 0.0;
    m_SpaceWidth = 0.0f;
    m_TextDrawMode = dmNormal;
    m_TextScale = 100.0f;
    m_WordSpacing = 0.0f;
    m_LastTextDir = tfNotInitialized;
    m_LastTextInfX = 0.0;
    m_LastTextInfY = 0.0;
}

static void TS_Create(void)
{
    m_ActiveFont = NULL;
    m_CharSpacing = 0.0f;
    m_FontSize = 1.0f;
    m_FontType = ftType1;
    m_Matrix.a = 1.0; m_Matrix.b = 0.0; m_Matrix.c = 0.0;
    m_Matrix.d = 1.0; m_Matrix.x = 0.0; m_Matrix.y = 0.0;
    m_SpaceWidth = 0.0f;
    m_TextDrawMode = dmNormal;
    m_TextScale = 100.0f;
    m_WordSpacing = 0.0f;
    m_Count = 0;
    m_Capacity = 0;
}

static void TS_Init(void)
{
    InitGState();
    Reset_();
    m_SelCount = 0;
}

/* ------------------------- text-matching core ------------------------- */
static int MarkSubString(double* x, const TCTM* Matrix, TTextRecordA* srec)
{
    SI32 i, maxLen, outLen;
    SI32 decoded;
    float spaceWidth2;
    double w;
    UI32 consumed;
    char* srcPtr;

    i = 0;
    spaceWidth2 = -m_SpaceWidth * 6.0f;
    maxLen = srec->Length;
    srcPtr = srec->Text;
    if (srec->Advance < -m_SpaceWidth) {
        /* If the distance is too large then no space was emulated here. */
        if ((srec->Advance > spaceWidth2) && (SPCode() == 32)) {
            if (!m_HavePos) {
                SetStartCoord(Matrix, *x);
                m_SearchPos++;
                if (SPCode() == 0) {
                    if (!DrawRect(Matrix, *x - srec->Advance)) return 0;
                    Reset_();
                }
            } else if (SPCode() == 0) {
                if (!DrawRect(Matrix, 0.0)) return 0;
                Reset_();
            } else {
                m_SearchPos++;
            }
        } else {
            Reset_();
        }
    }
    *x = *x - srec->Advance;
    outLen = 0;
    while (i < maxLen) {
        w = 0.0; decoded = 0;
        consumed = fntTranslateRawCode(m_ActiveFont, srcPtr + i, (UI32)(maxLen - i),
            &w, m_OutBuf, &outLen, &decoded, m_CharSpacing, m_WordSpacing, m_TextScale);
        if ((SI32)consumed <= 0) break;    /* safety: never let i stall */
        i += (SI32)consumed;
        if (decoded == 0) return 1;        /* skip record; must return TRUE */
        if (Compare(m_OutBuf, outLen)) {
            if (!m_HavePos) SetStartCoord(Matrix, *x);
            *x = *x + w;
            if (m_SearchPos == 0) {
                if (!DrawRect(Matrix, *x - m_CharSpacing)) return 0;
            }
        } else {
            *x = *x + w;
        }
    }
    return 1;
}

static SI32 MarkText(const TCTM* Matrix, TTextRecordAPtr Source, UI32 Count, double Width_)
{
    UI32 i;
    double x, x1, x2, x3, y1, y2, y3, distance, spaceWidth;
    SI32 textDir;
    TCTM m;
    int wrongLine;

    x1 = 0.0; y1 = 0.0;
    x2 = 0.0; y2 = m_FontSize;
    m = MulMatrix(&m_Matrix, Matrix);
    Transform(&m, &x1, &y1);
    Transform(&m, &x2, &y2);
    if (y1 == y2)
        textDir = ((x1 > x2 ? 1 : 0) + 1) * 2;
    else
        textDir = (y1 > y2 ? 1 : 0);

    /* C's || short-circuits, so IsPointOnLine (with its div-by-zero guard) is
       skipped when the direction already differs. */
    wrongLine = (textDir != m_LastTextDir) ||
                (!IsPointOnLine(x1, y1, m_EndX1, m_EndY1, m_LastTextInfX, m_LastTextInfY));
    if (wrongLine) {
        m_LastTextInfX = 1000000.0;
        m_LastTextInfY = 0.0;
        Transform(&m, &m_LastTextInfX, &m_LastTextInfY);
        Reset_();
    } else {
        x3 = m_SpaceWidth; y3 = 0.0;
        Transform(&m, &x3, &y3);
        spaceWidth = CalcDistance(x1, y1, x3, y3);
        distance = CalcDistance(m_EndX1, m_EndY1, x1, y1);
        if (distance > spaceWidth) {
            if ((distance < spaceWidth * 6.0) && (SPCode() == 32)) {
                if (!m_HavePos) {
                    m_HavePos = 1;
                    m_SearchPos++;
                    if (SPCode() == 0) {
                        m_x1 = m_EndX1; m_y1 = m_EndY1;
                        m_x4 = m_EndX4; m_y4 = m_EndY4;
                        if (!DrawRectEx(x1, y1, x2, y2)) return -1;
                        Reset_();
                    }
                } else if (SPCode() == 32) {
                    if (!DrawRectEx(x1, y1, x2, y2)) return -1;
                    Reset_();
                } else {
                    m_SearchPos++;
                }
            } else {
                Reset_();
            }
        }
    }

    x = 0.0;
    for (i = 0; i < Count; i++) {
        if (!MarkSubString(&x, &m, &Source[i])) return -1;
    }
    m_LastTextDir = textDir;
    m_EndX1 = Width_; m_EndY1 = 0.0;
    m_EndX4 = 0.0;    m_EndY4 = m_FontSize;
    Transform(&m, &m_EndX1, &m_EndY1);
    Transform(&m, &m_EndX4, &m_EndY4);
    return 0;
}

/* ------------------------- CTextSearch state methods ------------------------- */
static SI32 BeginTemplate(PCTM MatrixPtr)
{
    if (SaveGState() < 0) return -1;
    if (MatrixPtr != NULL)
        m_Matrix = MulMatrix(&m_Matrix, MatrixPtr);
    return 0;
}

static void TS_SetFont(PFNT IFont, SI32 FontType, double FontSize)
{
    m_ActiveFont = IFont;
    m_FontSize = (float)FontSize;
    m_FontType = FontType;
    m_SpaceWidth = (float)(fntGetSpaceWidth(IFont, FontSize) * 0.5);
}

/* ------------------------- parse* callback thunks ------------------------- */
static SI32 PDF_CALL parseBeginTemplate(void* Data, void* PDFObject, SI32 Handle,
                                        TPDFRect* BBox, PCTM Matrix)
{ (void)Data; (void)PDFObject; (void)Handle; (void)BBox; return BeginTemplate(Matrix); }
static void PDF_CALL parseEndTemplate(void* Data) { (void)Data; RestoreGState(); }
static void PDF_CALL parseMulMatrix(void* Data, void* PDFObject, TCTM* Matrix)
{ (void)Data; (void)PDFObject; m_Matrix = MulMatrix(&m_Matrix, Matrix); }
static SI32 PDF_CALL parseRestoreGraphicState(void* Data) { (void)Data; RestoreGState(); return 0; }
static SI32 PDF_CALL parseSaveGraphicState(void* Data) { (void)Data; return SaveGState(); }
static void PDF_CALL parseSetCharSpacing(void* Data, void* PDFObject, double Value)
{ (void)Data; (void)PDFObject; m_CharSpacing = (float)Value; }
static void PDF_CALL parseSetFont(void* Data, void* PDFObject, TFontType FontType, LBOOL Embedded,
                                  const char* FontName, TFStyle Style, double FontSize, PFNT Font)
{ (void)Data; (void)PDFObject; (void)Embedded; (void)FontName; (void)Style;
  TS_SetFont(Font, FontType, FontSize); }
static void PDF_CALL parseSetTextDrawMode(void* Data, void* PDFObject, TDrawMode Mode)
{ (void)Data; (void)PDFObject; m_TextDrawMode = Mode; }
static void PDF_CALL parseSetTextScale(void* Data, void* PDFObject, double Value)
{ (void)Data; (void)PDFObject; m_TextScale = (float)Value; }
static void PDF_CALL parseSetWordSpacing(void* Data, void* PDFObject, double Value)
{ (void)Data; (void)PDFObject; m_WordSpacing = (float)Value; }
static SI32 PDF_CALL parseShowTextArrayA(void* Data, char* Obj, TCTM* Matrix,
                                         TTextRecordAPtr Source, UI32 Count, double Width)
{ (void)Data; (void)Obj; return MarkText(Matrix, Source, Count, Width); }

/* ------------------------- main ------------------------- */
int main(int argc, char** argv)
{
    PPDF pdf;
    TPDFParseInterface stack;
    TPDFExtGState g;
    SI32 gs;
    SI32 selCount = 0;
    char dir[1024], inFile[1200], outFile[1200], cmapDir[1200];
    int i, pc;

    exedir(argv[0], dir, sizeof(dir));

    m_PDF = NULL;
    TS_Create();

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
    stack.ShowTextArrayA = parseShowTextArrayA;   /* this example uses the A slot */

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

    /* The search text must be defined in Unicode. */
    SetSearchText("PDF");

    /* Use blend mode bmMultiply so the background text stays visible. */
    pdfInitExtGState(&g);
    g.BlendMode = bmMultiply;
    gs = pdfCreateExtGState(pdf, &g);

    pc = pdfGetPageCount(pdf);
    for (i = 1; i <= pc; i++) {
        pdfEditPage(pdf, i);
        pdfSetExtGState(pdf, gs);
        pdfSetFillColor(pdf, RGB(255, 255, 0));

        TS_Init();
        pdfParseContent(pdf, 0, &stack, pfNone);
        pdfEndPage(pdf);
        if (m_SelCount > 0) {
            selCount += m_SelCount;
            printf("Found string on Page: %d %d times!\n", i, m_SelCount);
        }
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
    printf("\nFound string in the file %d times!\n", selCount);

    pdfDeletePDF(pdf);
    return 0;
}

/* text_extraction -- C port of examples\Vb6\text_extraction
   Imports a PDF and extracts its text with GetPageText()/TPDFStack, rebuilding
   text lines and word boundaries by transforming each text record to user
   space. Output is written to out.txt as UTF-16LE (with BOM). */
#include <stdio.h>
#include <math.h>
#include <wchar.h>
#include "lumaspdf.h"

/* TTextDir */
#define tfNotInitialized 5
#define MAX_LINE_ERROR 4.0   /* square of the allowed error (2*2) */

static PPDF m_PDF;
static FILE* m_File;
static TPDFStack m_Stack;
static SI32 m_LastTextDir;
static double m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY;

/* CIntList (template handle list) */
static SI32 m_Templates[4096];
static SI32 m_TemplCount;

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

/* ---------------- output helpers ---------------- */
static void WriteWStr(const wchar_t* s) {
    if (s && *s) fwrite(s, 2, wcslen(s), m_File);
}
static void WriteWCharsFromPtr(const LWCHAR* p, SI32 count) {
    if (p && count > 0) fwrite(p, 2, count, m_File);
}

/* ---------------- CIntList ---------------- */
static void ListClear(void) { m_TemplCount = 0; }
static void ListAdd(SI32 v) { if (m_TemplCount < 4096) m_Templates[m_TemplCount++] = v; }
static SI32 ListFind(SI32 v) {
    SI32 i;
    for (i = 0; i < m_TemplCount; i++) if (m_Templates[i] == v) return i;
    return -1;
}

/* ---------------- matrix helpers ---------------- */
static TCTM MulMatrix(const TCTM* M1, const TCTM* M2) {
    TCTM r;
    r.a = M2->a * M1->a + M2->b * M1->c;
    r.b = M2->a * M1->b + M2->b * M1->d;
    r.c = M2->c * M1->a + M2->d * M1->c;
    r.d = M2->c * M1->b + M2->d * M1->d;
    r.x = M2->x * M1->a + M2->y * M1->c + M1->x;
    r.y = M2->x * M1->b + M2->y * M1->d + M1->y;
    return r;
}
static void Transform(const TCTM* M, double* x, double* y) {
    double tx = *x;
    *x = tx * M->a + (*y) * M->c + M->x;
    *y = tx * M->b + (*y) * M->d + M->y;
}
static double CalcDistance(double x1, double y1, double x2, double y2) {
    double dx = x2 - x1, dy = y2 - y1;
    return sqrt(dx * dx + dy * dy);
}
static int IsPointOnLine(double x, double y, double x0, double y0, double x1, double y1) {
    double dx, dy, di;
    x -= x0; y -= y0;
    dx = x1 - x0; dy = y1 - y0;
    if ((dx * dx + dy * dy) == 0.0) return 0;   /* div-by-zero guard */
    di = (x * dx + y * dy) / (dx * dx + dy * dy);
    if (di < 0.0) di = 0.0; else if (di > 1.0) di = 1.0;
    dx = x - di * dx; dy = y - di * dy;
    di = dx * dx + dy * dy;
    return di < MAX_LINE_ERROR;
}

/* ---------------- text reconstruction ---------------- */
static void AddText(void) {
    SI32 i;
    double x1, x2, y1, y2, x3, y3, distance, spaceWidth;
    SI32 textDir; TCTM m; double spw;
    TTextRecordW* recs;

    x1 = 0.0; y1 = 0.0;
    x2 = 0.0; y2 = m_Stack.FontSize;
    m = MulMatrix(&m_Stack.ctm, &m_Stack.tm);
    Transform(&m, &x1, &y1);
    Transform(&m, &x2, &y2);
    if (y1 == y2) textDir = ((x1 > x2 ? 1 : 0) + 1) * 2;
    else          textDir = (y1 > y2 ? 1 : 0);

    if ((textDir != m_LastTextDir) ||
        (!IsPointOnLine(x1, y1, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY))) {
        m_LastTextInfX = 1000000.0;
        m_LastTextInfY = 0.0;
        Transform(&m, &m_LastTextInfX, &m_LastTextInfY);
        if (m_LastTextDir != tfNotInitialized) WriteWStr(L"\r\n");
    } else {
        x3 = m_Stack.SpaceWidth; y3 = 0.0;
        Transform(&m, &x3, &y3);
        spaceWidth = CalcDistance(x1, y1, x3, y3);
        distance = CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1);
        if (distance > spaceWidth) WriteWStr(L" ");
    }

    spw = -m_Stack.SpaceWidth * 0.5;
    recs = (TTextRecordW*)m_Stack.Kerning;
    for (i = 0; i < (SI32)m_Stack.KerningCount; i++) {
        if (recs[i].Advance < spw) WriteWStr(L" ");
        WriteWCharsFromPtr(recs[i].Text, recs[i].Length);
    }

    m_LastTextEndX = m_Stack.TextWidth + spw;   /* spw is negative */
    m_LastTextEndY = 0.0;
    m_LastTextDir = textDir;
    Transform(&m, &m_LastTextEndX, &m_LastTextEndY);
}

static void ParseText(void) {
    int haveMore = (pdfGetPageText(m_PDF, &m_Stack) != 0);
    if (!haveMore && m_Stack.TextLen == 0) return;
    AddText();
    if (haveMore) {
        while (pdfGetPageText(m_PDF, &m_Stack) != 0) AddText();
    }
}

static void ParseTemplates(void) {
    SI32 i, j, tmpl, tmplCount, tmplCount2;
    tmplCount = pdfGetTemplCount(m_PDF);
    for (i = 0; i < tmplCount; i++) {
        if (pdfEditTemplate(m_PDF, i) == 0) return;
        tmpl = pdfGetTemplHandle(m_PDF);
        if (ListFind(tmpl) < 0) {
            ListAdd(tmpl);
            if (pdfInitStack(m_PDF, &m_Stack) == 0) return;
            ParseText();
            tmplCount2 = pdfGetTemplCount(m_PDF);
            for (j = 0; j < tmplCount2; j++) ParseTemplates();
            pdfEndTemplate(m_PDF);
        } else {
            pdfEndTemplate(m_PDF);
        }
    }
}

static void ParsePage(void) {
    ListClear();
    if (pdfInitStack(m_PDF, &m_Stack) == 0) {
        char* em = pdfGetErrorMessage(m_PDF);
        if (em) printf("%s\n", em);
        return;
    }
    m_LastTextEndX = 0.0; m_LastTextEndY = 0.0;
    m_LastTextDir = tfNotInitialized;
    m_LastTextInfX = 0.0; m_LastTextInfY = 0.0;
    ParseText();
    ParseTemplates();
}

int main(void) {
    int i, cnt;
    unsigned char bom[2] = { 0xFF, 0xFE };
    wchar_t hdr[96];

    m_PDF = pdfNewPDF();
    pdfCreateNewPDFA(m_PDF, "");
    pdfSetOnErrorProc(m_PDF, 0, ErrProc);

    pdfSetCMapDirA(m_PDF, "CMap", lcmRecursive | lcmDelayed);

    pdfSetImportFlags(m_PDF, ifImportAll | ifImportAsPage);
    if (pdfOpenImportFileA(m_PDF, "in.pdf", ptOpen, "") < 0) { pdfDeletePDF(m_PDF); return 1; }
    pdfImportPDFFile(m_PDF, 1, 1.0, 1.0);
    pdfCloseImportFile(m_PDF);

    pdfFlattenAnnots(m_PDF, affMarkupAnnots);
    pdfFlattenForm(m_PDF);

    m_File = fopen("out.txt", "wb");
    if (!m_File) { pdfDeletePDF(m_PDF); return 1; }
    fwrite(bom, 1, 2, m_File);

    cnt = pdfGetPageCount(m_PDF);
    for (i = 1; i <= cnt; i++) {
        pdfEditPage(m_PDF, i);
        swprintf(hdr, 96, L"%ls%%----------------------- Page %d -----------------------------\r\n",
                 (i > 1 ? L"\r\n" : L""), i);
        WriteWStr(hdr);
        ParsePage();
        pdfEndPage(m_PDF);
    }
    fclose(m_File);

    printf("Text successfully extracted to out.txt\n");
    pdfDeletePDF(m_PDF);
    return 0;
}

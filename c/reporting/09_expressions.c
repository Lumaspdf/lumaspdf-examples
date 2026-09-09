/* LumasReport example 09 -- Expression function tour (C port). */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define PDF_DEMO_KEY "LUMAS-LumasReportExamples-DD5D40E0"
#define RPT_DEMO_KEY "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

static PPDF mPdf;
static TRPT mEng;

static void WriteText(const char* path, const char* content) {
    FILE* f = fopen(path, "wb");
    if (f) { fputs(content, f); fclose(f); }
}

static void DumpRptError(TRPT eng) {
    TRptErrorInfoC info;
    memset(&info, 0, sizeof(info));
    if (rptGetLastError(eng, &info) != 0 && info.Code != 0)
        printf("  ! rpt error %d [%.16s] at %.64s: %.256s\n", info.Code, info.Module_, info.Location, info.Msg);
}

static int BootEngine(void) {
    mPdf = pdfNewPDF();
    if (!mPdf) { printf("pdfNewPDF failed\n"); return 0; }
    pdfSetLicenseKey(mPdf, PDF_DEMO_KEY);
    rptSetRptLicenseKeyA(mPdf, RPT_DEMO_KEY);
    mEng = rptCreateEngineA(mPdf, NULL);
    if (!mEng) { printf("rptCreateEngine failed:\n"); DumpRptError(0); return 0; }
    return 1;
}

static int g_y;
static void LineEl(char* buf, size_t cap, size_t* n, const char* label, const char* expr) {
    *n += (size_t)snprintf(buf + *n, cap - *n,
        "   <text name=\"l%d\" x=\"0\" y=\"%d\" w=\"185\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">%s -&gt; {{expr: %s}}</text>\n",
        g_y, g_y, label, expr);
    g_y += 5;
}

int main(void) {
    TRPTJOB job;
    char body[8192];
    char xml[10240];
    size_t bn = 0;
    const char* lrpt = "09_expr.lrpt";
    const char* outPdf = "09_expr.pdf";
    const char* outTxt = "09_expr.txt";

    if (!BootEngine()) return 1;

    g_y = 0;
    body[0] = 0;
    LineEl(body, sizeof(body), &bn, "UPPER", "UPPER('abc')");
    LineEl(body, sizeof(body), &bn, "LOWER", "LOWER('ABC')");
    LineEl(body, sizeof(body), &bn, "LEFT", "LEFT('LumasReport', 5)");
    LineEl(body, sizeof(body), &bn, "RIGHT", "RIGHT('LumasReport', 6)");
    LineEl(body, sizeof(body), &bn, "SUBSTR", "SUBSTR('LumasReport', 6, 6)");
    LineEl(body, sizeof(body), &bn, "LEN", "LEN('LumasReport')");
    LineEl(body, sizeof(body), &bn, "TRIM", "'[' + TRIM('  hi  ') + ']'");
    LineEl(body, sizeof(body), &bn, "REPLACE", "REPLACE('a-b-c', '-', '+')");
    LineEl(body, sizeof(body), &bn, "PADL", "PADL('7', 4, '0')");
    LineEl(body, sizeof(body), &bn, "POS", "POS('Report', 'LumasReport')");
    LineEl(body, sizeof(body), &bn, "REVERSE", "REVERSE('abc')");
    LineEl(body, sizeof(body), &bn, "REPLICATE", "REPLICATE('ab', 3)");
    LineEl(body, sizeof(body), &bn, "CONTAINS", "CONTAINS('LumasReport', 'Rep')");
    LineEl(body, sizeof(body), &bn, "STARTSWITH", "STARTSWITH('LumasReport', 'Lumas')");
    LineEl(body, sizeof(body), &bn, "ENDSWITH", "ENDSWITH('LumasReport', 'port')");
    LineEl(body, sizeof(body), &bn, "ABS", "ABS(-42)");
    LineEl(body, sizeof(body), &bn, "ROUND", "ROUND(3.14159, 2)");
    LineEl(body, sizeof(body), &bn, "FLOOR", "FLOOR(3.9)");
    LineEl(body, sizeof(body), &bn, "CEIL", "CEIL(3.1)");
    LineEl(body, sizeof(body), &bn, "SQRT", "SQRT(144)");
    LineEl(body, sizeof(body), &bn, "POWER", "POWER(2, 10)");
    LineEl(body, sizeof(body), &bn, "MIN", "MIN(5, 3)");
    LineEl(body, sizeof(body), &bn, "MAX", "MAX(5, 3)");
    LineEl(body, sizeof(body), &bn, "SIGN", "SIGN(-7)");
    LineEl(body, sizeof(body), &bn, "TRUNC", "TRUNC(9.87)");
    LineEl(body, sizeof(body), &bn, "MOD_op", "17 % 5");
    LineEl(body, sizeof(body), &bn, "YEAR", "YEAR(TODAY())");
    LineEl(body, sizeof(body), &bn, "FORMATDATE", "FORMATDATE('yyyy-mm-dd', TODAY())");
    LineEl(body, sizeof(body), &bn, "ADDDAYS", "FORMATDATE('yyyy-mm-dd', ADDDAYS(TODAY(), 7))");
    LineEl(body, sizeof(body), &bn, "DATEDIFF", "DATEDIFF('d', TODAY(), ADDDAYS(TODAY(), 30))");
    LineEl(body, sizeof(body), &bn, "CSTR", "CSTR(123)");
    LineEl(body, sizeof(body), &bn, "CINT", "CINT('45')");
    LineEl(body, sizeof(body), &bn, "CFLOAT", "CFLOAT('3.5') * 2");
    LineEl(body, sizeof(body), &bn, "VAL", "VAL('19') + 1");
    LineEl(body, sizeof(body), &bn, "FORMATNUM", "FORMATNUM('#,##0.00', 1234.5)");
    LineEl(body, sizeof(body), &bn, "ISNULL", "ISNULL(NULLIF(3, 3))");
    LineEl(body, sizeof(body), &bn, "IFNULL", "IFNULL(NULLIF(3, 3), 'was-null')");
    LineEl(body, sizeof(body), &bn, "COALESCE", "COALESCE(NULLIF(1,1), NULLIF(2,2), 'fallback')");
    LineEl(body, sizeof(body), &bn, "REGEXMATCH", "REGEXMATCH('abc123', '[a-z]+[0-9]+')");
    LineEl(body, sizeof(body), &bn, "REGEXREPLACE", "REGEXREPLACE('a1b2c3', '[0-9]', '#')");
    LineEl(body, sizeof(body), &bn, "REGEXEXTRACT", "REGEXEXTRACT('order 4567 ok', '[0-9]+')");

    snprintf(xml, sizeof(xml),
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Expressions\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"12\" marginTop=\"12\" marginRight=\"12\" marginBottom=\"12\"/>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"%d\">\n"
        "%s"
        "  </band>\n"
        " </bands>\n"
        "</report>\n", g_y + 4, body);
    WriteText(lrpt, xml);

    job = rptOpenReportA(mEng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(mEng); goto cleanup; }
    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    rptExportA(job, RPT_EXP_PDF, outPdf);
    rptExportA(job, RPT_EXP_TEXT, outTxt);
    printf("rendered %d page(s); 41 expression lines -> %s\n", rptGetPageCount(job), outTxt);
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

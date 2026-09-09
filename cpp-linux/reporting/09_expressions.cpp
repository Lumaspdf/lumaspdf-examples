// 09_expressions -- C++ port of examples\Vb6\reporting\09_expressions.bas
#include "rptcommon.h"

static std::string LineEl(int& y, const char* Label_, const char* Expr) {
    char buf[512];
    snprintf(buf, sizeof(buf),
        "   <text name=\"l%d\" x=\"0\" y=\"%d\" w=\"185\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">%s -&gt; {{expr: %s}}</text>\n",
        y, y, Label_, Expr);
    y += 5;
    return buf;
}

static std::string BuildReport() {
    int y = 0;
    std::string s;
    s += LineEl(y, "UPPER", "UPPER('abc')");
    s += LineEl(y, "LOWER", "LOWER('ABC')");
    s += LineEl(y, "LEFT", "LEFT('LumasReport', 5)");
    s += LineEl(y, "RIGHT", "RIGHT('LumasReport', 6)");
    s += LineEl(y, "SUBSTR", "SUBSTR('LumasReport', 6, 6)");
    s += LineEl(y, "LEN", "LEN('LumasReport')");
    s += LineEl(y, "TRIM", "'[' + TRIM('  hi  ') + ']'");
    s += LineEl(y, "REPLACE", "REPLACE('a-b-c', '-', '+')");
    s += LineEl(y, "PADL", "PADL('7', 4, '0')");
    s += LineEl(y, "POS", "POS('Report', 'LumasReport')");
    s += LineEl(y, "REVERSE", "REVERSE('abc')");
    s += LineEl(y, "REPLICATE", "REPLICATE('ab', 3)");
    s += LineEl(y, "CONTAINS", "CONTAINS('LumasReport', 'Rep')");
    s += LineEl(y, "STARTSWITH", "STARTSWITH('LumasReport', 'Lumas')");
    s += LineEl(y, "ENDSWITH", "ENDSWITH('LumasReport', 'port')");
    s += LineEl(y, "ABS", "ABS(-42)");
    s += LineEl(y, "ROUND", "ROUND(3.14159, 2)");
    s += LineEl(y, "FLOOR", "FLOOR(3.9)");
    s += LineEl(y, "CEIL", "CEIL(3.1)");
    s += LineEl(y, "SQRT", "SQRT(144)");
    s += LineEl(y, "POWER", "POWER(2, 10)");
    s += LineEl(y, "MIN", "MIN(5, 3)");
    s += LineEl(y, "MAX", "MAX(5, 3)");
    s += LineEl(y, "SIGN", "SIGN(-7)");
    s += LineEl(y, "TRUNC", "TRUNC(9.87)");
    s += LineEl(y, "MOD_op", "17 % 5");
    s += LineEl(y, "YEAR", "YEAR(TODAY())");
    s += LineEl(y, "FORMATDATE", "FORMATDATE('yyyy-mm-dd', TODAY())");
    s += LineEl(y, "ADDDAYS", "FORMATDATE('yyyy-mm-dd', ADDDAYS(TODAY(), 7))");
    s += LineEl(y, "DATEDIFF", "DATEDIFF('d', TODAY(), ADDDAYS(TODAY(), 30))");
    s += LineEl(y, "CSTR", "CSTR(123)");
    s += LineEl(y, "CINT", "CINT('45')");
    s += LineEl(y, "CFLOAT", "CFLOAT('3.5') * 2");
    s += LineEl(y, "VAL", "VAL('19') + 1");
    s += LineEl(y, "FORMATNUM", "FORMATNUM('#,##0.00', 1234.5)");
    s += LineEl(y, "ISNULL", "ISNULL(NULLIF(3, 3))");
    s += LineEl(y, "IFNULL", "IFNULL(NULLIF(3, 3), 'was-null')");
    s += LineEl(y, "COALESCE", "COALESCE(NULLIF(1,1), NULLIF(2,2), 'fallback')");
    s += LineEl(y, "REGEXMATCH", "REGEXMATCH('abc123', '[a-z]+[0-9]+')");
    s += LineEl(y, "REGEXREPLACE", "REGEXREPLACE('a1b2c3', '[0-9]', '#')");
    s += LineEl(y, "REGEXEXTRACT", "REGEXEXTRACT('order 4567 ok', '[0-9]+')");
    char hdr[128];
    snprintf(hdr, sizeof(hdr),
        "  <band kind=\"reportheader\" name=\"rh\" height=\"%d\">\n", y + 4);
    std::string Xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Expressions\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"12\" marginTop=\"12\" marginRight=\"12\" marginBottom=\"12\"/>\n"
        " <bands>\n";
    Xml += hdr;
    Xml += s;
    Xml += "  </band>\n"
           " </bands>\n"
           "</report>\n";
    return Xml;
}

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    std::string Xml = BuildReport();
    const char* Lrpt = "09_expr.lrpt";
    const char* OutPdf = "09_expr.pdf";
    const char* OutTxt = "09_expr.txt";
    WriteText(Lrpt, Xml);

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    rptExportA(Job, RPT_EXP_PDF, OutPdf);
    rptExportA(Job, RPT_EXP_TEXT, OutTxt);
    printf("rendered %d page(s); 41 expression lines -> %s\n", (int)rptGetPageCount(Job), OutTxt);
    rptCloseReport(Job);
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

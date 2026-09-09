// 15_tags_and_formatting -- C++ port of examples\Vb6\reporting\15_tags_and_formatting.bas
#include "rptcommon.h"
#include <ctime>

static std::string CsvData() {
    return "Col,Note\nAlpha,first\nBeta,second\n";
}

// %CSV% is replaced with the csv path at runtime.
static std::string ReportTmpl() {
    return
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"TagTour\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"12\" marginTop=\"12\" marginRight=\"12\" marginBottom=\"12\"/>\n"
        " <datasources>\n"
        "  <datasource alias=\"d\" provider=\"csv\" conn=\"%CSV%\"/>\n"
        " </datasources>\n"
        " <params>\n"
        "  <param name=\"Name\" default=\"(unset)\"/>\n"
        " </params>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"120\">\n"
        "   <text name=\"h\"   x=\"0\" y=\"0\"  w=\"186\" h=\"8\" fontSize=\"16\" hAlign=\"center\">Tag &amp; formatting tour</text>\n"
        "   <text name=\"ex\"  x=\"0\" y=\"12\" w=\"186\" h=\"6\" fontSize=\"11\">expr 2+3*4 = {{expr: 2+3*4 }}</text>\n"
        "   <text name=\"vr\"  x=\"0\" y=\"20\" w=\"186\" h=\"6\" fontSize=\"11\">var:Name = {{var:Name}}</text>\n"
        "   <text name=\"fn\"  x=\"0\" y=\"28\" w=\"186\" h=\"6\" fontSize=\"11\">FORMATNUM = {{expr: FORMATNUM('#,##0.00', 1234.5) }}</text>\n"
        "   <text name=\"fd\"  x=\"0\" y=\"36\" w=\"186\" h=\"6\" fontSize=\"11\">FORMATDATE = {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }}</text>\n"
        "   <text name=\"esc\" x=\"0\" y=\"44\" w=\"186\" h=\"6\" fontSize=\"11\">escape literal = {{{{ }}</text>\n"
        "   <text name=\"a0\" x=\"0\" y=\"56\" w=\"186\" h=\"6\" fontSize=\"10\" hAlign=\"0\">hAlign 0 = left</text>\n"
        "   <text name=\"a1\" x=\"0\" y=\"63\" w=\"186\" h=\"6\" fontSize=\"10\" hAlign=\"1\">hAlign 1 = center</text>\n"
        "   <text name=\"a2\" x=\"0\" y=\"70\" w=\"186\" h=\"6\" fontSize=\"10\" hAlign=\"2\">hAlign 2 = right</text>\n"
        "   <text name=\"a3\" x=\"0\" y=\"77\" w=\"186\" h=\"6\" fontSize=\"10\" hAlign=\"3\">hAlign 3 = justify this line so it spreads across the whole width of the box evenly</text>\n"
        "   <text name=\"v0\" x=\"0\"   y=\"92\" w=\"60\" h=\"20\" fontSize=\"9\" vAlign=\"0\">vAlign 0 top</text>\n"
        "   <text name=\"v1\" x=\"63\"  y=\"92\" w=\"60\" h=\"20\" fontSize=\"9\" vAlign=\"1\">vAlign 1 middle</text>\n"
        "   <text name=\"v2\" x=\"126\" y=\"92\" w=\"60\" h=\"20\" fontSize=\"9\" vAlign=\"2\">vAlign 2 bottom</text>\n"
        "  </band>\n"
        "  <band kind=\"detail\" name=\"rows\" height=\"7\" data=\"d\">\n"
        "   <text name=\"r\" x=\"0\" y=\"0\" w=\"186\" h=\"6\" fontSize=\"11\">row: fields.d.Col={{fields.d.Col}}  bare d.Col={{d.Col}}  note={{d.Note}}</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";
}

static std::string ReplaceAll(std::string s, const std::string& from, const std::string& to) {
    size_t p = 0;
    while ((p = s.find(from, p)) != std::string::npos) { s.replace(p, from.size(), to); p += to.size(); }
    return s;
}

static std::string ReadAllText(const char* Path) {
    FILE* f = fopen(Path, "rb");
    if (!f) return "";
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    std::string s; if (n > 0) { s.resize(n); fread(&s[0], 1, n, f); }
    fclose(f);
    return s;
}

static void Prove(const char* What, const char* Needle, const std::string& Hay) {
    if (Hay.find(Needle) != std::string::npos) printf("  OK   %s found \"%s\"\n", What, Needle);
    else printf("  MISS %s expected \"%s\"\n", What, Needle);
}

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    const char* Csv = "15_data.csv";
    const char* OutPdf = "15_tags.pdf";
    const char* OutTxt = "15_tags.txt";

    WriteText(Csv, CsvData());
    std::string Xml = ReplaceAll(ReportTmpl(), "%CSV%", Csv);

    TRPTJOB Job = rptOpenReportMem(mEng, (void*)Xml.data(), (SI32)Xml.size());
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }

    rptSetParamStr(Job, "Name", "Ada_Lovelace");

    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); goto CloseJob; }
    printf("rendered %d page(s)\n", (int)rptGetPageCount(Job));

    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("PDF export failed\n"); DumpRptError(mEng); goto CloseJob; }
    printf("wrote %s\n", OutPdf);
    if (rptExportA(Job, RPT_EXP_TEXT, OutTxt) == 0) { printf("TEXT export failed\n"); DumpRptError(mEng); goto CloseJob; }
    printf("wrote %s\n", OutTxt);
CloseJob:
    rptCloseReport(Job);
    {
    printf("== Proof (grep the TEXT export) ==\n");
    std::string Txt = ReadAllText(OutTxt);
    time_t t = time(nullptr);
    char iso[16]; strftime(iso, sizeof(iso), "%Y-%m-%d", localtime(&t));

    Prove("expr 2+3*4", "= 14", Txt);
    Prove("var:Name", "Ada_Lovelace", Txt);
    Prove("FORMATNUM", "1,234.50", Txt);
    Prove("FORMATDATE", iso, Txt);
    Prove("escape {{}}", "{{ }}", Txt);
    Prove("fields.d.Col", "Alpha", Txt);
    Prove("bare d.Col", "Beta", Txt);
    }
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

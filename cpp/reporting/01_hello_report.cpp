// 01_hello_report -- C++ port of examples\Vb6\reporting\01_hello_report.bas
#include "rptcommon.h"

int main() {
    ChdirToExe();
    SI32 Mj = 0, Mn = 0, Pt = 0;
    rptGetVersion(&Mj, &Mn, &Pt);
    printf("LumasReport v%d.%d.%d\n", (int)Mj, (int)Mn, (int)Pt);

    if (!BootEngine()) return 0;

    const char* Lrpt = "01_hello.lrpt";
    const char* OutPdf = "01_hello.pdf";
    std::string Xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Hello\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"20\">\n"
        "   <text name=\"title\" x=\"0\" y=\"0\" w=\"180\" h=\"10\" fontSize=\"20\" hAlign=\"center\">Hello, LumasReport!</text>\n"
        "   <text name=\"sub\"   x=\"0\" y=\"12\" w=\"180\" h=\"6\" fontSize=\"10\" hAlign=\"center\">The minimal engine -&gt; render -&gt; PDF flow.</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";
    WriteText(Lrpt, Xml);

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("rendered %d page(s)\n", (int)rptGetPageCount(Job));
    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("export failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("wrote %s\n", OutPdf);
    rptCloseReport(Job);
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

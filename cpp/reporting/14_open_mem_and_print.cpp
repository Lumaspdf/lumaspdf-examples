// 14_open_mem_and_print -- C++ port of examples\Vb6\reporting\14_open_mem_and_print.bas
#include "rptcommon.h"

static bool FileExists(const char* p) { FILE* f = fopen(p, "rb"); if (f) { fclose(f); return true; } return false; }

static std::string BuildXml() {
    return
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"InMem\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"24\">\n"
        "   <text name=\"title\" x=\"0\" y=\"0\"  w=\"180\" h=\"12\" fontSize=\"20\" hAlign=\"center\">In-memory report</text>\n"
        "   <text name=\"sub\"   x=\"0\" y=\"14\" w=\"180\" h=\"6\"  fontSize=\"10\" hAlign=\"center\">Opened with rptOpenReportMem -- no file on disk.</text>\n"
        "  </band>\n"
        "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n"
        "   <text name=\"ph1\" x=\"0\" y=\"0\" w=\"180\" h=\"6\" fontSize=\"9\" hAlign=\"left\">LumasReport example 14</text>\n"
        "  </band>\n"
        "  <band kind=\"detail\" name=\"det\" height=\"8\">\n"
        "   <text name=\"d1\" x=\"0\" y=\"0\" w=\"180\" h=\"6\" fontSize=\"11\" hAlign=\"left\">This band was rendered from bytes handed to the engine directly.</text>\n"
        "  </band>\n"
        "  <band kind=\"pagefooter\" name=\"pf\" height=\"8\">\n"
        "   <text name=\"pf1\" x=\"0\" y=\"0\" w=\"180\" h=\"6\" fontSize=\"8\" hAlign=\"right\">page {{var:PageNo}} of {{var:TotalPages}}</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";
}

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    const char* OutPdf = "14_open_mem.pdf";
    const char* OutPrint = "14_printed.pdf";
    SI32 Pages = 0;

    printf("== Open from memory ==\n");
    std::string Xml = BuildXml();
    SI32 nBytes = (SI32)Xml.size();
    printf("  blob is %d bytes\n", (int)nBytes);
    TRPTJOB Job = rptOpenReportMem(mEng, (void*)Xml.data(), nBytes);
    if (Job == 0) { printf("  rptOpenReportMem failed\n"); DumpRptError(mEng); goto Cleanup; }

    if (rptRender(Job) == 0) { printf("  render failed\n"); DumpRptError(mEng); goto CloseJob; }
    Pages = rptGetPageCount(Job);
    printf("  rendered %d page(s) from the in-memory report\n", (int)Pages);

    printf("== Export ==\n");
    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("  export failed\n"); DumpRptError(mEng); goto CloseJob; }
    printf("  wrote %s\n", OutPdf);

    printf("== Headless print ==\n");
    if (rptPrintA(Job, "Microsoft Print to PDF", OutPrint) != 0) {
        printf("  \"Microsoft Print to PDF\" -> %s\n", OutPrint);
    } else {
        printf("  \"Microsoft Print to PDF\" not available / print failed (continuing -- not fatal):\n");
        DumpRptError(mEng);
    }
    // rptPreviewA(Job, "In-memory report") is documented but deliberately not called.
CloseJob:
    rptCloseReport(Job);

    printf("== Verify ==\n");
    if (FileExists(OutPdf) && Pages >= 1)
        printf("  OK: %s exists, report has %d page(s)\n", OutPdf, (int)Pages);
    else
        printf("  VERIFY FAILED: in-memory PDF missing or zero pages\n");
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

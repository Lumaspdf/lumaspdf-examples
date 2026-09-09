/* LumasReport example 14 -- In-memory open + headless print (C port). */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define PDF_DEMO_KEY "LUMAS-LumasReportExamples-DD5D40E0"
#define RPT_DEMO_KEY "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

static void DumpRptError(TRPT eng) {
    TRptErrorInfoC info;
    memset(&info, 0, sizeof(info));
    if (rptGetLastError(eng, &info) != 0 && info.Code != 0)
        printf("  ! rpt error %d [%.16s] at %.64s: %.256s\n", info.Code, info.Module_, info.Location, info.Msg);
}

static int BootEngine(PPDF* pdf, TRPT* eng) {
    *pdf = pdfNewPDF();
    if (!*pdf) { printf("pdfNewPDF failed\n"); return 0; }
    pdfSetLicenseKey(*pdf, PDF_DEMO_KEY);
    rptSetRptLicenseKeyA(*pdf, RPT_DEMO_KEY);
    *eng = rptCreateEngineA(*pdf, NULL);
    if (!*eng) { printf("rptCreateEngine failed\n"); return 0; }
    return 1;
}

static int FileExists(const char* path) {
    FILE* f = fopen(path, "rb");
    if (f) { fclose(f); return 1; }
    return 0;
}

static const char* BuildXml(void) {
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

int main(void) {
    PPDF pdf; TRPT eng; TRPTJOB job;
    const char* outPdf = "14_open_mem.pdf";
    const char* outPrint = "14_printed.pdf";
    const char* xml;
    int nBytes, pages = 0;
    if (!BootEngine(&pdf, &eng)) return 1;

    printf("== Open from memory ==\n");
    xml = BuildXml();
    nBytes = (int)strlen(xml);
    printf("  blob is %d bytes\n", nBytes);
    job = rptOpenReportMem(eng, (void*)xml, nBytes);
    if (!job) { printf("  rptOpenReportMem failed\n"); DumpRptError(eng); goto cleanup; }

    if (rptRender(job) == 0) { printf("  render failed\n"); DumpRptError(eng); goto closejob; }
    pages = rptGetPageCount(job);
    printf("  rendered %d page(s) from the in-memory report\n", pages);

    printf("== Export ==\n");
    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("  export failed\n"); DumpRptError(eng); goto closejob; }
    printf("  wrote %s\n", outPdf);

    printf("== Headless print ==\n");
    if (rptPrintA(job, "Microsoft Print to PDF", outPrint) != 0)
        printf("  \"Microsoft Print to PDF\" -> %s\n", outPrint);
    else {
        printf("  \"Microsoft Print to PDF\" not available / print failed (continuing -- not fatal):\n");
        DumpRptError(eng);
    }
closejob:
    rptCloseReport(job);

    printf("== Verify ==\n");
    if (FileExists(outPdf) && pages >= 1)
        printf("  OK: %s exists, report has %d page(s)\n", outPdf, pages);
    else
        printf("  VERIFY FAILED: in-memory PDF missing or zero pages\n");
cleanup:
    rptDeleteEngine(eng);
    pdfDeletePDF(pdf);
    return 0;
}

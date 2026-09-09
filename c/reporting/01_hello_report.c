/* LumasReport example 01 -- Hello report (C port of VB6 mirror). */
#include <stdio.h>
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
    if (rptGetLastError(eng, &info) != 0 && info.Code != 0) {
        printf("  ! rpt error %d [%.16s] at %.64s: %.256s\n",
               info.Code, info.Module_, info.Location, info.Msg);
    }
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

int main(void) {
    TRPTJOB job;
    int mj = 0, mn = 0, pt = 0;
    const char* lrpt = "01_hello.lrpt";
    const char* outPdf = "01_hello.pdf";
    const char* xml =
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

    rptGetVersion(&mj, &mn, &pt);
    printf("LumasReport v%d.%d.%d\n", mj, mn, pt);

    if (!BootEngine()) return 1;

    WriteText(lrpt, xml);

    job = rptOpenReportA(mEng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(mEng); goto cleanup; }
    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    printf("rendered %d page(s)\n", rptGetPageCount(job));
    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("export failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    printf("wrote %s\n", outPdf);
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

/* LumasReport example 03 -- Export to all targets (C port). */
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

static long FileSizeOf(const char* path) {
    FILE* f = fopen(path, "rb");
    long n;
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    n = ftell(f);
    fclose(f);
    return n;
}

static int FileExists(const char* path) {
    FILE* f = fopen(path, "rb");
    if (f) { fclose(f); return 1; }
    return 0;
}

int main(void) {
    TRPTJOB job;
    int i;
    char outFile[64];
    const char* csv = "03_data.csv";
    const char* lrpt = "03_report.lrpt";
    const char* csvData =
        "product,qty,price\n"
        "Widget,4,9.95\n"
        "Gadget,2,19.50\n"
        "Sprocket,7,3.25\n";
    int targets[10] = { RPT_EXP_PDF, RPT_EXP_HTML, RPT_EXP_CSV, RPT_EXP_JSON, RPT_EXP_XML,
                        RPT_EXP_TEXT, RPT_EXP_SVG, RPT_EXP_XLSX, RPT_EXP_PNG, RPT_EXP_BMP };
    const char* exts[10] = { "pdf", "html", "csv", "json", "xml", "txt", "svg", "xlsx", "png", "bmp" };
    char xml[1024];

    if (!BootEngine()) return 1;

    WriteText(csv, csvData);
    snprintf(xml, sizeof(xml),
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"ExportDemo\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"%s\"/></datasources>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"14\">\n"
        "   <text name=\"ttl\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\">Order Lines</text>\n"
        "  </band>\n"
        "  <band kind=\"detail\" name=\"det\" height=\"7\" data=\"d\">\n"
        "   <text name=\"p\" x=\"0\"   y=\"0\" w=\"90\" h=\"6\" fontSize=\"10\" wordWrap=\"0\">{{d.product}}</text>\n"
        "   <text name=\"q\" x=\"90\"  y=\"0\" w=\"30\" h=\"6\" fontSize=\"10\" hAlign=\"right\" wordWrap=\"0\">{{d.qty}}</text>\n"
        "   <text name=\"r\" x=\"120\" y=\"0\" w=\"60\" h=\"6\" fontSize=\"10\" hAlign=\"right\" wordWrap=\"0\">{{d.price}}</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n", csv);
    WriteText(lrpt, xml);

    job = rptOpenReportA(mEng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(mEng); goto cleanup; }
    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    printf("rendered %d page(s)\n", rptGetPageCount(job));
    printf("== Exporting to all targets ==\n");
    for (i = 0; i < 10; i++) {
        snprintf(outFile, sizeof(outFile), "03_out.%s", exts[i]);
        if (rptExportA(job, targets[i], outFile) != 0 && FileExists(outFile))
            printf("  [%s] id=%d  OK  %ld bytes\n", exts[i], targets[i], FileSizeOf(outFile));
        else { printf("  [%s] id=%d  FAILED\n", exts[i], targets[i]); DumpRptError(mEng); }
    }
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

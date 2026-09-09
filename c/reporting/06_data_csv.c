/* LumasReport example 06 -- CSV data provider (C port). */
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

int main(void) {
    TRPTJOB job;
    char xml[2048];
    const char* lrpt = "06_data.lrpt";
    const char* csv = "06_data.csv";
    const char* outPdf = "06_data.pdf";
    const char* outCsv = "06_data_out.csv";
    const char* outTxt = "06_data.txt";
    const char* csvData =
        "Region,Product,Qty,Price\n"
        "North,Widget,10,2.50\n"
        "North,Gadget,4,9.99\n"
        "South,Widget,7,2.50\n"
        "South,Sprocket,20,1.25\n"
        "East,Gadget,3,9.99\n"
        "West,Sprocket,15,1.25\n";

    if (!BootEngine()) return 1;

    WriteText(csv, csvData);
    snprintf(xml, sizeof(xml),
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"CsvSales\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"%s\"/></datasources>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"12\">\n"
        "   <text name=\"ttl\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\">Sales by Region</text>\n"
        "  </band>\n"
        "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n"
        "   <text name=\"h1\" x=\"0\"   y=\"0\" w=\"50\" h=\"6\" fontSize=\"9\" style=\"\">REGION</text>\n"
        "   <text name=\"h2\" x=\"50\"  y=\"0\" w=\"60\" h=\"6\" fontSize=\"9\">PRODUCT</text>\n"
        "   <text name=\"h3\" x=\"110\" y=\"0\" w=\"30\" h=\"6\" fontSize=\"9\" hAlign=\"right\">QTY</text>\n"
        "   <text name=\"h4\" x=\"140\" y=\"0\" w=\"40\" h=\"6\" fontSize=\"9\" hAlign=\"right\">PRICE</text>\n"
        "   <line name=\"hl\" x=\"0\" y=\"7\" w=\"180\" h=\"0.3\" toX=\"180\" toY=\"0\"/>\n"
        "  </band>\n"
        "  <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n"
        "   <text name=\"c1\" x=\"0\"   y=\"0\" w=\"50\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{d.Region}}</text>\n"
        "   <text name=\"c2\" x=\"50\"  y=\"0\" w=\"60\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{d.Product}}</text>\n"
        "   <text name=\"c3\" x=\"110\" y=\"0\" w=\"30\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{d.Qty}}</text>\n"
        "   <text name=\"c4\" x=\"140\" y=\"0\" w=\"40\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{d.Price}}</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n", csv);
    WriteText(lrpt, xml);

    job = rptOpenReportA(mEng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(mEng); goto cleanup; }
    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    printf("rendered %d page(s)\n", rptGetPageCount(job));
    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("pdf export failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    if (rptExportA(job, RPT_EXP_CSV, outCsv) == 0) { printf("csv export failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    if (rptExportA(job, RPT_EXP_TEXT, outTxt) == 0) { printf("text export failed\n"); DumpRptError(mEng); rptCloseReport(job); goto cleanup; }
    printf("wrote %s\n", outPdf);
    printf("wrote %s\n", outCsv);
    printf("wrote %s\n", outTxt);
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

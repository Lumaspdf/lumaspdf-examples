/* LumasReport example 11 -- Report parameters, rendered twice (C port). */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define PDF_DEMO_KEY "LUMAS-LumasReportExamples-DD5D40E0"
#define RPT_DEMO_KEY "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

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

static int BootEngine(PPDF* pdf, TRPT* eng) {
    *pdf = pdfNewPDF();
    if (!*pdf) { printf("pdfNewPDF failed\n"); return 0; }
    pdfSetLicenseKey(*pdf, PDF_DEMO_KEY);
    rptSetRptLicenseKeyA(*pdf, RPT_DEMO_KEY);
    *eng = rptCreateEngineA(*pdf, NULL);
    if (!*eng) { printf("rptCreateEngine failed\n"); return 0; }
    return 1;
}

static const char* BuildXml(void) {
    return
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Params\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <params>\n"
        "  <param name=\"Customer\" default=\"ACME (default)\"/>\n"
        "  <param name=\"UnitPrice\" default=\"0\"/>\n"
        "  <param name=\"Qty\" default=\"0\"/>\n"
        " </params>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"30\">\n"
        "   <text name=\"title\" x=\"0\" y=\"0\" w=\"180\" h=\"10\" fontSize=\"18\" hAlign=\"center\">Invoice for {{var:Customer}}</text>\n"
        "   <text name=\"line1\" x=\"0\" y=\"14\" w=\"180\" h=\"6\" fontSize=\"11\">Unit price: {{var:UnitPrice}}   Quantity: {{var:Qty}}</text>\n"
        "   <text name=\"line2\" x=\"0\" y=\"22\" w=\"180\" h=\"6\" fontSize=\"11\">TOTAL = {{expr: UnitPrice * Qty}}</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";
}

static int RunOnce(TRPT eng, const char* lrpt, const char* outPdf, const char* outTxt,
                   const char* customer, double unitPrice, long qty) {
    TRPTJOB job = rptOpenReportA(eng, lrpt);
    if (!job) { printf("  open failed\n"); DumpRptError(eng); return 0; }
    if (rptSetParamStr(job, "Customer", customer) == 0) { printf("  SetParamStr failed\n"); DumpRptError(eng); rptCloseReport(job); return 0; }
    if (rptSetParamNum(job, "UnitPrice", unitPrice) == 0) { printf("  SetParamNum failed\n"); DumpRptError(eng); rptCloseReport(job); return 0; }
    if (rptSetParamInt(job, "Qty", qty) == 0) { printf("  SetParamInt failed\n"); DumpRptError(eng); rptCloseReport(job); return 0; }
    if (rptRender(job) == 0) { printf("  render failed\n"); DumpRptError(eng); rptCloseReport(job); return 0; }
    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("  export PDF failed\n"); DumpRptError(eng); rptCloseReport(job); return 0; }
    if (rptExportA(job, RPT_EXP_TEXT, outTxt) == 0) { printf("  export TEXT failed\n"); DumpRptError(eng); rptCloseReport(job); return 0; }
    printf("  wrote %s  (Customer=\"%s\" UnitPrice=%g Qty=%ld TOTAL=%g)\n", outPdf, customer, unitPrice, qty, unitPrice * qty);
    rptCloseReport(job);
    return 1;
}

int main(void) {
    PPDF pdf; TRPT eng;
    const char* lrpt = "11_parameters.lrpt";
    if (!BootEngine(&pdf, &eng)) return 1;
    WriteText(lrpt, BuildXml());

    printf("Run #1:\n");
    if (!RunOnce(eng, lrpt, "11_run1.pdf", "11_run1.txt", "Globex Corporation", 12.5, 4)) goto cleanup;
    printf("Run #2:\n");
    if (!RunOnce(eng, lrpt, "11_run2.pdf", "11_run2.txt", "Initech LLC", 9.99, 10)) goto cleanup;
    printf("OK\n");
cleanup:
    rptDeleteEngine(eng);
    pdfDeletePDF(pdf);
    return 0;
}

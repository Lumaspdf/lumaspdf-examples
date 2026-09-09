// 11_parameters -- C++ port of examples\Vb6\reporting\11_parameters.bas
#include "rptcommon.h"

static std::string BuildXml() {
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

static bool RunOnce(const char* Lrpt, const char* OutPdf, const char* OutTxt,
                    const char* Customer, double UnitPrice, long Qty) {
    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("  open failed\n"); DumpRptError(mEng); return false; }
    bool ok = false;
    if (rptSetParamStr(Job, "Customer", Customer) == 0) { printf("  SetParamStr failed\n"); DumpRptError(mEng); goto Done; }
    if (rptSetParamNum(Job, "UnitPrice", UnitPrice) == 0) { printf("  SetParamNum failed\n"); DumpRptError(mEng); goto Done; }
    if (rptSetParamInt(Job, "Qty", Qty) == 0) { printf("  SetParamInt failed\n"); DumpRptError(mEng); goto Done; }
    if (rptRender(Job) == 0) { printf("  render failed\n"); DumpRptError(mEng); goto Done; }
    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("  export PDF failed\n"); DumpRptError(mEng); goto Done; }
    if (rptExportA(Job, RPT_EXP_TEXT, OutTxt) == 0) { printf("  export TEXT failed\n"); DumpRptError(mEng); goto Done; }
    printf("  wrote %s  (Customer=\"%s\" UnitPrice=%g Qty=%ld TOTAL=%g)\n",
           OutPdf, Customer, UnitPrice, Qty, UnitPrice * Qty);
    ok = true;
Done:
    rptCloseReport(Job);
    return ok;
}

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;
    const char* Lrpt = "11_parameters.lrpt";
    WriteText(Lrpt, BuildXml());

    printf("Run #1:\n");
    if (!RunOnce(Lrpt, "11_run1.pdf", "11_run1.txt", "Globex Corporation", 12.5, 4)) goto Cleanup;

    printf("Run #2:\n");
    if (!RunOnce(Lrpt, "11_run2.pdf", "11_run2.txt", "Initech LLC", 9.99, 10)) goto Cleanup;

    printf("OK\n");
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

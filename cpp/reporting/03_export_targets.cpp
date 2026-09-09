// 03_export_targets -- C++ port of examples\Vb6\reporting\03_export_targets.bas
#include "rptcommon.h"

static bool FileExists(const char* Path) {
    FILE* f = fopen(Path, "rb");
    if (f) { fclose(f); return true; }
    return false;
}
static long FileSizeOf(const char* Path) {
    FILE* f = fopen(Path, "rb");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fclose(f);
    return n;
}

int main() {
    ChdirToExe();
    SI32 Targets[10] = { RPT_EXP_PDF, RPT_EXP_HTML, RPT_EXP_CSV, RPT_EXP_JSON, RPT_EXP_XML,
                         RPT_EXP_TEXT, RPT_EXP_SVG, RPT_EXP_XLSX, RPT_EXP_PNG, RPT_EXP_BMP };
    const char* Exts[10] = { "pdf", "html", "csv", "json", "xml", "txt", "svg", "xlsx", "png", "bmp" };

    if (!BootEngine()) return 0;

    const char* Csv = "03_data.csv";
    const char* Lrpt = "03_report.lrpt";
    std::string CsvData =
        "product,qty,price\n"
        "Widget,4,9.95\n"
        "Gadget,2,19.50\n"
        "Sprocket,7,3.25\n";
    WriteText(Csv, CsvData);
    std::string Xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"ExportDemo\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"" + std::string(Csv) + "\"/></datasources>\n"
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
        "</report>\n";
    WriteText(Lrpt, Xml);

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("rendered %d page(s)\n", (int)rptGetPageCount(Job));
    printf("== Exporting to all targets ==\n");
    for (int i = 0; i < 10; ++i) {
        std::string OutFile = std::string("03_out.") + Exts[i];
        if (rptExportA(Job, Targets[i], OutFile.c_str()) != 0 && FileExists(OutFile.c_str()))
            printf("  [%s] id=%d  OK  %ld bytes\n", Exts[i], (int)Targets[i], FileSizeOf(OutFile.c_str()));
        else {
            printf("  [%s] id=%d  FAILED\n", Exts[i], (int)Targets[i]);
            DumpRptError(mEng);
        }
    }
    rptCloseReport(Job);
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

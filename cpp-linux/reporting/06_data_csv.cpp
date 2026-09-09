// 06_data_csv -- C++ port of examples\Vb6\reporting\06_data_csv.bas
#include "rptcommon.h"

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    const char* Lrpt = "06_data.lrpt";
    const char* Csv = "06_data.csv";
    const char* OutPdf = "06_data.pdf";
    const char* OutCsv = "06_data_out.csv";
    const char* OutTxt = "06_data.txt";

    std::string CsvData =
        "Region,Product,Qty,Price\n"
        "North,Widget,10,2.50\n"
        "North,Gadget,4,9.99\n"
        "South,Widget,7,2.50\n"
        "South,Sprocket,20,1.25\n"
        "East,Gadget,3,9.99\n"
        "West,Sprocket,15,1.25\n";
    WriteText(Csv, CsvData);
    std::string Xml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"CsvSales\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"" + std::string(Csv) + "\"/></datasources>\n"
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
        "</report>\n";
    WriteText(Lrpt, Xml);

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("rendered %d page(s)\n", (int)rptGetPageCount(Job));
    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("pdf export failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    if (rptExportA(Job, RPT_EXP_CSV, OutCsv) == 0) { printf("csv export failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    if (rptExportA(Job, RPT_EXP_TEXT, OutTxt) == 0) { printf("text export failed\n"); DumpRptError(mEng); rptCloseReport(Job); goto Cleanup; }
    printf("wrote %s\n", OutPdf);
    printf("wrote %s\n", OutCsv);
    printf("wrote %s\n", OutTxt);
    rptCloseReport(Job);
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

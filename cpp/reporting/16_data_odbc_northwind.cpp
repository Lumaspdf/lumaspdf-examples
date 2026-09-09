// 16_data_odbc_northwind -- C++ port of examples\Vb6\reporting\16_data_odbc_northwind.bas
// x64 build: use the 64-bit ACE "Microsoft Access Driver (*.mdb, *.accdb)".
#include "rptcommon.h"
#include "repo_root.h"

static const char* MDB = LUMAS_REPO_ROOT "/wrappers/vcl/Examples/Northwind.mdb";

static bool FileExists(const char* p) { FILE* f = fopen(p, "rb"); if (f) { fclose(f); return true; } return false; }

static std::string BuildXml() {
    std::string conn = std::string("Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=") + MDB + ";";
    return
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Northwind\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources>\n"
        "  <datasource alias=\"d\" provider=\"odbc\"\n"
        "    conn=\"" + conn + "\"\n"
        "    query=\"SELECT c.CategoryName, p.ProductName, p.UnitPrice, p.UnitsInStock FROM Categories c INNER JOIN Products p ON c.CategoryID = p.CategoryID ORDER BY c.CategoryName, p.ProductName\"/>\n"
        " </datasources>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"14\">\n"
        "   <text name=\"t\" x=\"0\" y=\"0\" w=\"180\" h=\"10\" fontSize=\"18\" hAlign=\"center\" wordWrap=\"0\">Northwind Product Catalog</text>\n"
        "  </band>\n"
        "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n"
        "   <text name=\"c1\" x=\"0\"   y=\"0\" w=\"110\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">Product</text>\n"
        "   <text name=\"c2\" x=\"120\" y=\"0\" w=\"30\"  h=\"5\" fontSize=\"9\" bold=\"1\" hAlign=\"right\" wordWrap=\"0\">Price</text>\n"
        "   <text name=\"c3\" x=\"152\" y=\"0\" w=\"28\"  h=\"5\" fontSize=\"9\" bold=\"1\" hAlign=\"right\" wordWrap=\"0\">Stock</text>\n"
        "  </band>\n"
        "  <band kind=\"groupheader\" name=\"gh\" group=\"d.CategoryName\" height=\"8\">\n"
        "   <text name=\"g\" x=\"0\" y=\"1\" w=\"180\" h=\"6\" fontSize=\"12\" bold=\"1\" wordWrap=\"0\">{{expr: d.CategoryName}}</text>\n"
        "  </band>\n"
        "  <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n"
        "   <text name=\"p\"  x=\"4\"   y=\"0\" w=\"110\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{ProductName}}</text>\n"
        "   <text name=\"pr\" x=\"120\" y=\"0\" w=\"30\"  h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', UnitPrice) }}</text>\n"
        "   <text name=\"sk\" x=\"152\" y=\"0\" w=\"28\"  h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{UnitsInStock}}</text>\n"
        "  </band>\n"
        "  <band kind=\"groupfooter\" name=\"gf\" group=\"d.CategoryName\" height=\"4\">\n"
        "   <text name=\"ge\" x=\"4\" y=\"0\" w=\"176\" h=\"4\" fontSize=\"7\" wordWrap=\"0\">-- end of {{expr: d.CategoryName}} --</text>\n"
        "  </band>\n"
        "  <band kind=\"pagefooter\" name=\"pf\" height=\"6\">\n"
        "   <text name=\"f\" x=\"0\" y=\"0\" w=\"180\" h=\"5\" fontSize=\"7\" hAlign=\"right\" wordWrap=\"0\">printed {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }}</text>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";
}

int main() {
    ChdirToExe();
    if (!FileExists(MDB)) { printf("Northwind.mdb not found: %s\n", MDB); return 0; }
    if (!BootEngine()) return 0;

    const char* Lrpt = "16_northwind.lrpt";
    const char* OutPdf = "16_northwind.pdf";
    const char* OutTxt = "16_northwind.txt";
    WriteText(Lrpt, BuildXml());

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); goto CloseJob; }
    printf("rendered %d page(s) from Northwind.mdb (odbc)\n", (int)rptGetPageCount(Job));
    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("pdf export failed\n"); DumpRptError(mEng); goto CloseJob; }
    if (rptExportA(Job, RPT_EXP_TEXT, OutTxt) == 0) { printf("text export failed\n"); DumpRptError(mEng); goto CloseJob; }
    printf("wrote %s  +  %s\n", OutPdf, OutTxt);
CloseJob:
    rptCloseReport(Job);
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

/* LumasReport example 16 -- ODBC data provider over Northwind.mdb (C port, x64). */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define PDF_DEMO_KEY "LUMAS-LumasReportExamples-DD5D40E0"
#define RPT_DEMO_KEY "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

#define MDB "E:\\LUMASPDFSDK\\wrappers\\vcl\\Examples\\Northwind.mdb"

static void WriteText(const char* path, const char* content) {
    FILE* f = fopen(path, "wb");
    if (f) { fputs(content, f); fclose(f); }
}

static int FileExists(const char* path) {
    FILE* f = fopen(path, "rb");
    if (f) { fclose(f); return 1; }
    return 0;
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

/* x64 build -> use the ACE "(*.mdb, *.accdb)" driver. */
static const char* BuildXml(void) {
    return
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Northwind\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources>\n"
        "  <datasource alias=\"d\" provider=\"odbc\"\n"
        "    conn=\"Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=" MDB ";\"\n"
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

int main(void) {
    PPDF pdf; TRPT eng; TRPTJOB job;
    const char* lrpt = "16_northwind.lrpt";
    const char* outPdf = "16_northwind.pdf";
    const char* outTxt = "16_northwind.txt";
    if (!FileExists(MDB)) { printf("Northwind.mdb not found: %s\n", MDB); return 0; }
    if (!BootEngine(&pdf, &eng)) return 1;

    WriteText(lrpt, BuildXml());
    job = rptOpenReportA(eng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(eng); goto cleanup; }
    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(eng); goto closejob; }
    printf("rendered %d page(s) from Northwind.mdb (odbc)\n", rptGetPageCount(job));
    if (rptExportA(job, RPT_EXP_PDF, outPdf) == 0) { printf("pdf export failed\n"); DumpRptError(eng); goto closejob; }
    if (rptExportA(job, RPT_EXP_TEXT, outTxt) == 0) { printf("text export failed\n"); DumpRptError(eng); goto closejob; }
    printf("wrote %s  +  %s\n", outPdf, outTxt);
closejob:
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(eng);
    pdfDeletePDF(pdf);
    return 0;
}

// 19_northwind_preview -- C++ port of examples\Vb6\reporting\19_northwind_preview.bas
// x64 build: use the 64-bit ACE "Microsoft Access Driver (*.mdb, *.accdb)".
#include "rptcommon.h"
#include "repo_root.h"
#include <ctime>

static const char* MDB = LUMAS_REPO_ROOT "/wrappers/vcl/Examples/Northwind.mdb";

static bool FileExists(const char* p) { FILE* f = fopen(p, "rb"); if (f) { fclose(f); return true; } return false; }

static std::string BuildReportXml() {
    std::string conn = std::string("Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=") + MDB + ";";
    std::string s;
    s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    s += "<report name=\"Northwind Catalog\" tagLangVersion=\"1\">\n";
    s += "  <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\"\n";
    s += "        marginRight=\"15\" marginBottom=\"15\"/>\n";
    s += "  <datasources>\n";
    s += "    <datasource alias=\"d\" provider=\"odbc\"\n";
    s += std::string("      conn=\"") + conn + "\"\n";
    s += "      query=\"SELECT c.CategoryName, p.ProductName, p.QuantityPerUnit,\n";
    s += "                    p.UnitPrice, p.UnitsInStock\n";
    s += "             FROM Categories c INNER JOIN Products p\n";
    s += "               ON c.CategoryID = p.CategoryID\n";
    s += "             ORDER BY c.CategoryName, p.ProductName\"/>\n";
    s += "  </datasources>\n";
    s += "  <params>\n";
    s += "    <param name=\"Title\"   default=\"'Northwind Product Catalog'\"/>\n";
    s += "    <param name=\"Company\" default=\"'LumasPDF Trading Co.'\"/>\n";
    s += "  </params>\n";
    s += "  <styles>\n";
    s += "    <style name=\"Bar\"     backColor=\"005F3A1F\" borderWidth=\"0\"/>\n";
    s += "    <style name=\"GrpBar\"  backColor=\"002A170F\" borderWidth=\"0\"/>\n";
    s += "    <style name=\"Title\"   fontName=\"Helvetica\" fontSize=\"22\" bold=\"1\" textColor=\"00FFFFFF\" vAlign=\"1\"/>\n";
    s += "    <style name=\"Sub\"     fontName=\"Helvetica\" fontSize=\"9\"  textColor=\"00FFFFFF\" hAlign=\"2\" vAlign=\"1\"/>\n";
    s += "    <style name=\"ColH\"    fontName=\"Helvetica\" fontSize=\"8\"  bold=\"1\" textColor=\"00FFFFFF\" vAlign=\"1\"/>\n";
    s += "    <style name=\"ColHR\"   fontName=\"Helvetica\" fontSize=\"8\"  bold=\"1\" textColor=\"00FFFFFF\" hAlign=\"2\" vAlign=\"1\"/>\n";
    s += "    <style name=\"Grp\"     fontName=\"Helvetica\" fontSize=\"12\" bold=\"1\" textColor=\"00FFFFFF\" vAlign=\"1\"/>\n";
    s += "    <style name=\"Cell\"    fontName=\"Helvetica\" fontSize=\"9\"  textColor=\"002A170F\" vAlign=\"1\"/>\n";
    s += "    <style name=\"CellR\"   fontName=\"Helvetica\" fontSize=\"9\"  textColor=\"002A170F\" hAlign=\"2\" vAlign=\"1\"/>\n";
    s += "    <style name=\"Muted\"   fontName=\"Helvetica\" fontSize=\"8\"  textColor=\"008B7464\" vAlign=\"1\"/>\n";
    s += "    <style name=\"Sub L\"   fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"005F3A1F\"/>\n";
    s += "    <style name=\"SubR\"    fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"005F3A1F\" hAlign=\"2\"/>\n";
    s += "    <style name=\"GTotL\"   fontName=\"Helvetica\" fontSize=\"11\" bold=\"1\" textColor=\"00FFFFFF\"/>\n";
    s += "    <style name=\"GTotR\"   fontName=\"Helvetica\" fontSize=\"11\" bold=\"1\" textColor=\"00FFFFFF\" hAlign=\"2\"/>\n";
    s += "    <style name=\"Foot\"    fontName=\"Helvetica\" fontSize=\"7.5\" textColor=\"008B7464\"/>\n";
    s += "    <style name=\"FootR\"   fontName=\"Helvetica\" fontSize=\"7.5\" textColor=\"008B7464\" hAlign=\"2\"/>\n";
    s += "  </styles>\n";
    s += "  <bands>\n";
    s += "    <band kind=\"reportheader\" name=\"rh\" height=\"26\">\n";
    s += "      <shape name=\"hbar\"  x=\"0\" y=\"0\" w=\"180\" h=\"18\" style=\"Bar\" shape=\"0\"/>\n";
    s += "      <text  name=\"ttl\"   x=\"5\"  y=\"1\"  w=\"120\" h=\"10\" style=\"Title\" wordWrap=\"0\">{{var:Title}}</text>\n";
    s += "      <text  name=\"sub\"   x=\"95\" y=\"6\"  w=\"80\"  h=\"6\"  style=\"Sub\"   wordWrap=\"0\">{{var:Company}}</text>\n";
    s += "      <text  name=\"asof\"  x=\"0\"  y=\"20\" w=\"180\" h=\"4\"  style=\"Muted\" wordWrap=\"0\">Generated {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }} from Northwind.mdb (live ODBC)</text>\n";
    s += "    </band>\n";
    s += "    <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n";
    s += "      <shape name=\"cbar\" x=\"0\" y=\"0\" w=\"180\" h=\"7\" style=\"GrpBar\" shape=\"0\"/>\n";
    s += "      <text name=\"hP\"  x=\"3\"   y=\"1.5\" w=\"64\" h=\"4\" style=\"ColH\"  wordWrap=\"0\">PRODUCT</text>\n";
    s += "      <text name=\"hK\"  x=\"69\"  y=\"1.5\" w=\"44\" h=\"4\" style=\"ColH\"  wordWrap=\"0\">PACK</text>\n";
    s += "      <text name=\"hU\"  x=\"114\" y=\"1.5\" w=\"21\" h=\"4\" style=\"ColHR\" wordWrap=\"0\">PRICE</text>\n";
    s += "      <text name=\"hS\"  x=\"137\" y=\"1.5\" w=\"18\" h=\"4\" style=\"ColHR\" wordWrap=\"0\">STOCK</text>\n";
    s += "      <text name=\"hV\"  x=\"157\" y=\"1.5\" w=\"20\" h=\"4\" style=\"ColHR\" wordWrap=\"0\">VALUE</text>\n";
    s += "    </band>\n";
    s += "    <band kind=\"groupheader\" name=\"gh\" group=\"d.CategoryName\" height=\"9\">\n";
    s += "      <shape name=\"gbar\" x=\"0\" y=\"1\" w=\"180\" h=\"7\" style=\"GrpBar\" shape=\"0\"/>\n";
    s += "      <text  name=\"gname\" x=\"4\" y=\"1.7\" w=\"140\" h=\"5\" style=\"Grp\" wordWrap=\"0\">{{expr: d.CategoryName}}</text>\n";
    s += "    </band>\n";
    s += "    <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n";
    s += "      <shape name=\"zebra\" x=\"0\" y=\"0\" w=\"180\" h=\"6\" shape=\"0\" backColor=\"00F9F5F1\" visible=\"RowNum % 2 = 0\"/>\n";
    s += "      <text name=\"cP\" x=\"3\"   y=\"1\" w=\"64\" h=\"4\" style=\"Cell\"  wordWrap=\"0\">{{ProductName}}</text>\n";
    s += "      <text name=\"cK\" x=\"69\"  y=\"1\" w=\"44\" h=\"4\" style=\"Muted\" wordWrap=\"0\">{{QuantityPerUnit}}</text>\n";
    s += "      <text name=\"cU\" x=\"114\" y=\"1\" w=\"21\" h=\"4\" style=\"CellR\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', UnitPrice) }}</text>\n";
    s += "      <text name=\"cS\" x=\"137\" y=\"1\" w=\"18\" h=\"4\" style=\"CellR\" wordWrap=\"0\">{{UnitsInStock}}</text>\n";
    s += "      <text name=\"cV\" x=\"157\" y=\"1\" w=\"20\" h=\"4\" style=\"CellR\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0', UnitPrice*UnitsInStock) }}</text>\n";
    s += "      <line name=\"drow\" orient=\"h\" scope=\"section\" vAlign=\"bottom\" width=\"0.15\" color=\"00E2D8CE\"/>\n";
    s += "    </band>\n";
    s += "    <band kind=\"groupfooter\" name=\"gf\" group=\"d.CategoryName\" height=\"7\">\n";
    s += "      <line name=\"gtop\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.4\" color=\"005F3A1F\"/>\n";
    s += "      <text name=\"sl\" x=\"3\"   y=\"1.5\" w=\"110\" h=\"4\" style=\"Sub L\" wordWrap=\"0\">Subtotal -- {{expr: d.CategoryName}} ({{expr: COUNT()}} products)</text>\n";
    s += "      <text name=\"sv\" x=\"137\" y=\"1.5\" w=\"40\"  h=\"4\" style=\"SubR\"  wordWrap=\"0\">{{expr: FORMATNUM('#,##0', SUM(UnitPrice*UnitsInStock)) }}</text>\n";
    s += "    </band>\n";
    s += "    <band kind=\"summary\" name=\"sm\" height=\"16\">\n";
    s += "      <shape name=\"tbar\" x=\"0\" y=\"2\" w=\"180\" h=\"10\" style=\"Bar\" shape=\"0\"/>\n";
    s += "      <text name=\"gl\" x=\"4\"   y=\"4.2\" w=\"120\" h=\"6\" style=\"GTotL\" wordWrap=\"0\">GRAND TOTAL -- {{expr: COUNT()}} products in {{expr: COUNTDISTINCT(d.CategoryName)}} categories</text>\n";
    s += "      <text name=\"gv\" x=\"120\" y=\"4.2\" w=\"56\"  h=\"6\" style=\"GTotR\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0', SUM(UnitPrice*UnitsInStock)) }}</text>\n";
    s += "    </band>\n";
    s += "    <band kind=\"pagefooter\" name=\"pf\" height=\"9\">\n";
    s += "      <line name=\"ft\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.3\" color=\"00B9B9B9\"/>\n";
    s += "      <text name=\"fl\" x=\"0\"   y=\"2.5\" w=\"120\" h=\"4\" style=\"Foot\"  wordWrap=\"0\">{{var:Company}} -- confidential</text>\n";
    s += "      <text name=\"fr\" x=\"120\" y=\"2.5\" w=\"57\"  h=\"4\" style=\"FootR\" wordWrap=\"0\">Page {{var:PageNo}} of {{var:TotalPages}}</text>\n";
    s += "    </band>\n";
    s += "  </bands>\n";
    s += "</report>\n";
    return s;
}

static bool IsHeadless(int argc, char** argv) {
    for (int i = 1; i < argc; ++i) {
        std::string c = argv[i];
        for (char& ch : c) ch = (char)tolower((unsigned char)ch);
        if (c.find("--headless") != std::string::npos || c.find("--no-preview") != std::string::npos || c.find("/headless") != std::string::npos)
            return true;
    }
    return false;
}

int main(int argc, char** argv) {
    ChdirToExe();
    if (!FileExists(MDB)) { printf("Northwind.mdb not found: %s\n", MDB); return 0; }
    if (!BootEngine()) return 0;

    const char* Lrpt = "19_northwind.lrpt";
    const char* OutPdf = "19_northwind.pdf";
    const char* OutTxt = "19_northwind.txt";
    SI32 Pages = 0;

    std::string Xml = BuildReportXml();
    WriteText(Lrpt, Xml);
    printf("STEP 1-14: wrote %s (%d bytes)\n", Lrpt, (int)Xml.size());

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }

    rptSetParamStr(Job, "Title", "Northwind Product Catalog");
    rptSetParamStr(Job, "Company", "LumasPDF Trading Co.");

    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); goto CloseJob; }
    Pages = rptGetPageCount(Job);
    printf("RENDER: %d page(s) bound from Northwind.mdb\n", (int)Pages);

    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("pdf export failed\n"); DumpRptError(mEng); goto CloseJob; }
    if (rptExportA(Job, RPT_EXP_TEXT, OutTxt) == 0) { printf("text export failed\n"); DumpRptError(mEng); goto CloseJob; }
    printf("EXPORT: %s  +  %s\n", OutPdf, OutTxt);

    if (IsHeadless(argc, argv)) {
        printf("PREVIEW: skipped (--headless). Open %s to view.\n", OutPdf);
    } else {
        printf("PREVIEW: opening the embedded viewer -- close the window to continue...\n");
        if (rptPreviewA(Job, "Northwind Product Catalog") == 0) {
            printf("  preview failed (continuing -- not fatal):\n");
            DumpRptError(mEng);
        }
    }
CloseJob:
    rptCloseReport(Job);

    if (FileExists(OutPdf) && Pages >= 1)
        printf("OK: %s exists, %d page(s).\n", OutPdf, (int)Pages);
    else
        printf("VERIFY FAILED: PDF missing or zero pages\n");
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

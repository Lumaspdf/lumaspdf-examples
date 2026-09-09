// 18_invoice_pro -- C++ port of examples\Vb6\reporting\18_invoice_pro.bas
#include "rptcommon.h"

// Colours are COLORREF 00BBGGRR (low byte = red).
#define NAVY  "005F3A1F"
#define INK   "00222222"
#define GREY  "00808080"
#define GRID  "00B9B9B9"
#define HAIR  "00D8D8D8"
#define SHADE "00F4F1EC"
#define WHITE "00FFFFFF"

// middle dot: VB6 wrote ChrW(183) through the ANSI codepage -> single byte 0xB7.
static const char* DOT = "\xB7";

static std::string CsvData() {
    return
        "Item,Qty,Price\n"
        "Precision Widget Assembly,4,42.50\n"
        "Gadget Control Module,2,149.50\n"
        "Shielded Signal Cable (3m),10,4.75\n"
        "Universal Power Adapter,3,28.00\n"
        "Steel Mounting Bracket,12,3.25\n"
        "Thermal Interface Kit,5,11.20\n";
}

static std::string ColGrid(const char* Tag) {
    std::string s;
    s += std::string("   <line name=\"") + Tag + "a\" orient=\"v\" scope=\"section\" x=\"0\"   width=\"0.35\" color=\"" GRID "\"/>\n";
    s += std::string("   <line name=\"") + Tag + "b\" orient=\"v\" scope=\"section\" x=\"95\"  width=\"0.35\" color=\"" GRID "\"/>\n";
    s += std::string("   <line name=\"") + Tag + "c\" orient=\"v\" scope=\"section\" x=\"117\" width=\"0.35\" color=\"" GRID "\"/>\n";
    s += std::string("   <line name=\"") + Tag + "d\" orient=\"v\" scope=\"section\" x=\"149\" width=\"0.35\" color=\"" GRID "\"/>\n";
    s += std::string("   <line name=\"") + Tag + "e\" orient=\"v\" scope=\"section\" x=\"182\" width=\"0.35\" color=\"" GRID "\"/>\n";
    return s;
}

static std::string BuildXml(const char* Csv) {
    std::string d = DOT;
    std::string s;
    s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    s += "<report name=\"InvoicePro\" tagLangVersion=\"1\">\n";
    s += " <page width=\"210\" height=\"297\" marginLeft=\"14\" marginTop=\"14\" marginRight=\"14\" marginBottom=\"16\"/>\n";
    s += std::string(" <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"") + Csv + "\"/></datasources>\n";
    s += " <variables><variable name=\"PageNo\" init=\"1\"/></variables>\n";
    s += " <styles>\n";
    s += "  <style name=\"brand\"  fontName=\"Helvetica\" fontSize=\"20\" bold=\"1\" textColor=\"" NAVY "\"/>\n";
    s += "  <style name=\"addr\"   fontName=\"Helvetica\" fontSize=\"8\"  textColor=\"" GREY "\"/>\n";
    s += "  <style name=\"title\"  fontName=\"Helvetica\" fontSize=\"30\" bold=\"1\" textColor=\"" NAVY "\" hAlign=\"right\"/>\n";
    s += "  <style name=\"mlbl\"   fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"" GREY "\" hAlign=\"right\"/>\n";
    s += "  <style name=\"mval\"   fontName=\"Helvetica\" fontSize=\"8.5\" textColor=\"" INK "\" hAlign=\"right\"/>\n";
    s += "  <style name=\"billto\" fontName=\"Helvetica\" fontSize=\"8\" bold=\"1\" textColor=\"" NAVY "\"/>\n";
    s += "  <style name=\"cust\"   fontName=\"Helvetica\" fontSize=\"9.5\" textColor=\"" INK "\"/>\n";
    s += "  <style name=\"colh\"   fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"" WHITE "\"/>\n";
    s += "  <style name=\"colhr\"  fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"" WHITE "\" hAlign=\"right\"/>\n";
    s += "  <style name=\"cell\"   fontName=\"Helvetica\" fontSize=\"9.5\" textColor=\"" INK "\"/>\n";
    s += "  <style name=\"cellr\"  fontName=\"Helvetica\" fontSize=\"9.5\" textColor=\"" INK "\" hAlign=\"right\"/>\n";
    s += "  <style name=\"tlbl\"   fontName=\"Helvetica\" fontSize=\"9.5\" bold=\"1\" textColor=\"" INK "\" hAlign=\"right\"/>\n";
    s += "  <style name=\"tval\"   fontName=\"Helvetica\" fontSize=\"9.5\" textColor=\"" INK "\" hAlign=\"right\"/>\n";
    s += "  <style name=\"glbl\"   fontName=\"Helvetica\" fontSize=\"13\" bold=\"1\" textColor=\"" WHITE "\"/>\n";
    s += "  <style name=\"gval\"   fontName=\"Helvetica\" fontSize=\"13\" bold=\"1\" textColor=\"" WHITE "\" hAlign=\"right\"/>\n";
    s += "  <style name=\"note\"   fontName=\"Helvetica\" fontSize=\"8.5\" textColor=\"" GREY "\"/>\n";
    s += "  <style name=\"foot\"   fontName=\"Helvetica\" fontSize=\"8\" textColor=\"" GREY "\"/>\n";
    s += "  <style name=\"footr\"  fontName=\"Helvetica\" fontSize=\"8\" textColor=\"" GREY "\" hAlign=\"right\"/>\n";
    s += " </styles>\n";
    s += " <bands>\n";
    s += "  <band kind=\"reportheader\" name=\"rh\" height=\"42\">\n";
    s += "   <text name=\"co\"   x=\"0\"  y=\"0\"  w=\"110\" h=\"9\" style=\"brand\" wordWrap=\"0\">ACME Corporation</text>\n";
    s += "   <text name=\"a1\"   x=\"0\"  y=\"10\" w=\"120\" h=\"4\" style=\"addr\" wordWrap=\"0\">123 Industrial Way  " + d + "  Springfield, IL 62704</text>\n";
    s += "   <text name=\"a2\"   x=\"0\"  y=\"14\" w=\"120\" h=\"4\" style=\"addr\" wordWrap=\"0\">+1 (555) 018-2245  " + d + "  billing@acme.example</text>\n";
    s += "   <text name=\"ti\"   x=\"92\" y=\"0\"  w=\"90\"  h=\"13\" style=\"title\" wordWrap=\"0\">INVOICE</text>\n";
    s += "   <text name=\"ml1\"  x=\"108\" y=\"15\" w=\"40\" h=\"4\" style=\"mlbl\" wordWrap=\"0\">INVOICE #</text>\n";
    s += "   <text name=\"mv1\"  x=\"150\" y=\"15\" w=\"32\" h=\"4\" style=\"mval\" wordWrap=\"0\">INV-1042</text>\n";
    s += "   <text name=\"ml2\"  x=\"108\" y=\"20\" w=\"40\" h=\"4\" style=\"mlbl\" wordWrap=\"0\">ISSUE DATE</text>\n";
    s += "   <text name=\"mv2\"  x=\"150\" y=\"20\" w=\"32\" h=\"4\" style=\"mval\" wordWrap=\"0\">2026-07-19</text>\n";
    s += "   <text name=\"ml3\"  x=\"108\" y=\"25\" w=\"40\" h=\"4\" style=\"mlbl\" wordWrap=\"0\">DUE DATE</text>\n";
    s += "   <text name=\"mv3\"  x=\"150\" y=\"25\" w=\"32\" h=\"4\" style=\"mval\" wordWrap=\"0\">2026-08-18</text>\n";
    s += "   <text name=\"bt\"   x=\"0\"  y=\"25\" w=\"60\" h=\"4\" style=\"billto\" wordWrap=\"0\">BILL TO</text>\n";
    s += "   <text name=\"c1\"   x=\"0\"  y=\"29.5\" w=\"95\" h=\"4.5\" style=\"cust\" wordWrap=\"0\">Globex Manufacturing Co.</text>\n";
    s += "   <text name=\"c2\"   x=\"0\"  y=\"33.5\" w=\"95\" h=\"4\" style=\"addr\" wordWrap=\"0\">500 Commerce Blvd, Metropolis, NY 10001</text>\n";
    s += "   <line name=\"rht\" orient=\"h\" scope=\"section\" vAlign=\"top\"    width=\"0.3\" color=\"" HAIR "\"/>\n";
    s += "   <line name=\"rhb\" orient=\"h\" scope=\"section\" vAlign=\"bottom\" width=\"1.1\" color=\"" NAVY "\"/>\n";
    s += "  </band>\n";
    s += "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n";
    s += "   <shape name=\"bar\" x=\"0\" y=\"0\" w=\"182\" h=\"8\" shape=\"0\" backColor=\"" NAVY "\"/>\n";
    s += "   <text name=\"hI\" x=\"3\"   y=\"2\" w=\"88\" h=\"5\" style=\"colh\"  wordWrap=\"0\">DESCRIPTION</text>\n";
    s += "   <text name=\"hQ\" x=\"97\"  y=\"2\" w=\"16\" h=\"5\" style=\"colhr\" wordWrap=\"0\">QTY</text>\n";
    s += "   <text name=\"hP\" x=\"119\" y=\"2\" w=\"26\" h=\"5\" style=\"colhr\" wordWrap=\"0\">UNIT PRICE</text>\n";
    s += "   <text name=\"hA\" x=\"151\" y=\"2\" w=\"29\" h=\"5\" style=\"colhr\" wordWrap=\"0\">AMOUNT</text>\n";
    s += ColGrid("phg");
    s += " </band>\n";
    s += "  <band kind=\"detail\" name=\"det\" height=\"7\" data=\"d\">\n";
    s += "   <shape name=\"zebra\" x=\"0\" y=\"0\" w=\"182\" h=\"7\" shape=\"0\" backColor=\"" SHADE "\" visible=\"RowNum % 2 = 0\"/>\n";
    s += "   <text name=\"dI\" x=\"3\"   y=\"1.6\" w=\"90\" h=\"4\" style=\"cell\"  wordWrap=\"0\">{{Item}}</text>\n";
    s += "   <text name=\"dQ\" x=\"97\"  y=\"1.6\" w=\"16\" h=\"4\" style=\"cellr\" wordWrap=\"0\">{{Qty}}</text>\n";
    s += "   <text name=\"dP\" x=\"119\" y=\"1.6\" w=\"26\" h=\"4\" style=\"cellr\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', Price)}}</text>\n";
    s += "   <text name=\"dA\" x=\"151\" y=\"1.6\" w=\"29\" h=\"4\" style=\"cellr\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', Qty*Price)}}</text>\n";
    s += ColGrid("dg");
    s += "   <line name=\"drb\" orient=\"h\" scope=\"section\" vAlign=\"bottom\" width=\"0.2\" color=\"" HAIR "\"/>\n";
    s += "  </band>\n";
    s += "  <band kind=\"summary\" name=\"sm\" height=\"46\">\n";
    s += "   <line name=\"stop\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.6\" color=\"" NAVY "\"/>\n";
    s += "   <text name=\"nh\" x=\"0\" y=\"4\"  w=\"95\" h=\"4\" style=\"billto\" wordWrap=\"0\">NOTES</text>\n";
    s += "   <text name=\"n1\" x=\"0\" y=\"8.5\" w=\"100\" h=\"4\" style=\"note\" wordWrap=\"0\">Payment due within 30 days. Bank transfer to</text>\n";
    s += "   <text name=\"n2\" x=\"0\" y=\"12\"  w=\"100\" h=\"4\" style=\"note\" wordWrap=\"0\">ACME Corp " + d + " IBAN GB00 ACME 0000 1042 " + d + " Ref INV-1042.</text>\n";
    s += "   <text name=\"s1l\" x=\"100\" y=\"4\"  w=\"45\" h=\"4.5\" style=\"tlbl\" wordWrap=\"0\">Subtotal</text>\n";
    s += "   <text name=\"s1v\" x=\"149\" y=\"4\"  w=\"31\" h=\"4.5\" style=\"tval\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price))}}</text>\n";
    s += "   <text name=\"s2l\" x=\"100\" y=\"9.5\" w=\"45\" h=\"4.5\" style=\"tlbl\" wordWrap=\"0\">Tax (8.5%)</text>\n";
    s += "   <text name=\"s2v\" x=\"149\" y=\"9.5\" w=\"31\" h=\"4.5\" style=\"tval\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*0.085)}}</text>\n";
    s += "   <shape name=\"gbar\" x=\"100\" y=\"16\" w=\"82\" h=\"10\" shape=\"0\" backColor=\"" NAVY "\"/>\n";
    s += "   <text name=\"gl\" x=\"104\" y=\"18.5\" w=\"40\" h=\"6\" style=\"glbl\" wordWrap=\"0\">TOTAL</text>\n";
    s += "   <text name=\"gv\" x=\"149\" y=\"18.5\" w=\"29\" h=\"6\" style=\"gval\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*1.085)}}</text>\n";
    s += "   <text name=\"gc\" x=\"100\" y=\"28\" w=\"82\" h=\"4\" style=\"footr\" wordWrap=\"0\">USD " + d + " Total items {{expr: COUNT()}}</text>\n";
    s += "  </band>\n";
    s += "  <band kind=\"pagefooter\" name=\"pf\" height=\"12\">\n";
    s += "   <line name=\"pft\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.3\" color=\"" GRID "\"/>\n";
    s += "   <text name=\"ty\" x=\"0\"   y=\"3\" w=\"120\" h=\"4\" style=\"foot\"  wordWrap=\"0\">Thank you for your business.  Questions? billing@acme.example</text>\n";
    s += "   <text name=\"pg\" x=\"120\" y=\"3\" w=\"62\"  h=\"4\" style=\"footr\" wordWrap=\"0\">Page {{var:PageNo}} of {{var:TotalPages}}</text>\n";
    s += "  </band>\n";
    s += " </bands>\n";
    s += "</report>\n";
    return s;
}

static void ExportOne(TRPTJOB Job, SI32 Target, const char* Path) {
    if (rptExportA(Job, Target, Path) != 0) printf("  wrote %s\n", Path);
    else printf("  EXPORT FAILED: %s\n", Path);
}

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    const char* Csv = "18_items.csv";
    WriteText(Csv, CsvData());
    const char* Lrpt = "18_invoice.lrpt";
    WriteText(Lrpt, BuildXml(Csv));

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); goto CloseJob; }
    printf("rendered %d page(s); exporting:\n", (int)rptGetPageCount(Job));
    ExportOne(Job, RPT_EXP_PDF, "18_invoice.pdf");
    ExportOne(Job, RPT_EXP_HTML, "18_invoice.html");
    ExportOne(Job, RPT_EXP_SVG, "18_invoice.svg");
    ExportOne(Job, RPT_EXP_TEXT, "18_invoice.txt");
    ExportOne(Job, RPT_EXP_CSV, "18_invoice.csv");
    ExportOne(Job, RPT_EXP_XLSX, "18_invoice.xlsx");
    ExportOne(Job, RPT_EXP_XLS, "18_invoice.xls");
CloseJob:
    rptCloseReport(Job);
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

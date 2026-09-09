/* LumasReport example 18 -- Professional framed invoice (C port). */
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "lumaspdf.h"

#define PDF_DEMO_KEY "LUMAS-LumasReportExamples-DD5D40E0"
#define RPT_DEMO_KEY "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

/* COLORREF 00BBGGRR (low byte = red). */
#define NAVY  "005F3A1F"
#define INK   "00222222"
#define GREY  "00808080"
#define GRID  "00B9B9B9"
#define HAIR  "00D8D8D8"
#define SHADE "00F4F1EC"
#define WHITE "00FFFFFF"

/* middle dot U+00B7 in UTF-8 */
#define DOT "\xC2\xB7"

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

/* Append helper. */
static void app(char* buf, size_t cap, size_t* n, const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    *n += (size_t)vsnprintf(buf + *n, cap - *n, fmt, ap);
    va_end(ap);
}

/* Five section-scoped vertical column dividers. */
static void ColGrid(char* buf, size_t cap, size_t* n, const char* tag) {
    app(buf, cap, n, "   <line name=\"%sa\" orient=\"v\" scope=\"section\" x=\"0\"   width=\"0.35\" color=\"" GRID "\"/>\n", tag);
    app(buf, cap, n, "   <line name=\"%sb\" orient=\"v\" scope=\"section\" x=\"95\"  width=\"0.35\" color=\"" GRID "\"/>\n", tag);
    app(buf, cap, n, "   <line name=\"%sc\" orient=\"v\" scope=\"section\" x=\"117\" width=\"0.35\" color=\"" GRID "\"/>\n", tag);
    app(buf, cap, n, "   <line name=\"%sd\" orient=\"v\" scope=\"section\" x=\"149\" width=\"0.35\" color=\"" GRID "\"/>\n", tag);
    app(buf, cap, n, "   <line name=\"%se\" orient=\"v\" scope=\"section\" x=\"182\" width=\"0.35\" color=\"" GRID "\"/>\n", tag);
}

static void BuildXml(char* s, size_t cap, const char* csv) {
    size_t n = 0;
    app(s, cap, &n, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    app(s, cap, &n, "<report name=\"InvoicePro\" tagLangVersion=\"1\">\n");
    app(s, cap, &n, " <page width=\"210\" height=\"297\" marginLeft=\"14\" marginTop=\"14\" marginRight=\"14\" marginBottom=\"16\"/>\n");
    app(s, cap, &n, " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"%s\"/></datasources>\n", csv);
    app(s, cap, &n, " <variables><variable name=\"PageNo\" init=\"1\"/></variables>\n");
    app(s, cap, &n, " <styles>\n");
    app(s, cap, &n, "  <style name=\"brand\"  fontName=\"Helvetica\" fontSize=\"20\" bold=\"1\" textColor=\"" NAVY "\"/>\n");
    app(s, cap, &n, "  <style name=\"addr\"   fontName=\"Helvetica\" fontSize=\"8\"  textColor=\"" GREY "\"/>\n");
    app(s, cap, &n, "  <style name=\"title\"  fontName=\"Helvetica\" fontSize=\"30\" bold=\"1\" textColor=\"" NAVY "\" hAlign=\"right\"/>\n");
    app(s, cap, &n, "  <style name=\"mlbl\"   fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"" GREY "\" hAlign=\"right\"/>\n");
    app(s, cap, &n, "  <style name=\"mval\"   fontName=\"Helvetica\" fontSize=\"8.5\" textColor=\"" INK "\" hAlign=\"right\"/>\n");
    app(s, cap, &n, "  <style name=\"billto\" fontName=\"Helvetica\" fontSize=\"8\" bold=\"1\" textColor=\"" NAVY "\"/>\n");
    app(s, cap, &n, "  <style name=\"cust\"   fontName=\"Helvetica\" fontSize=\"9.5\" textColor=\"" INK "\"/>\n");
    app(s, cap, &n, "  <style name=\"colh\"   fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"" WHITE "\"/>\n");
    app(s, cap, &n, "  <style name=\"colhr\"  fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"" WHITE "\" hAlign=\"right\"/>\n");
    app(s, cap, &n, "  <style name=\"cell\"   fontName=\"Helvetica\" fontSize=\"9.5\" textColor=\"" INK "\"/>\n");
    app(s, cap, &n, "  <style name=\"cellr\"  fontName=\"Helvetica\" fontSize=\"9.5\" textColor=\"" INK "\" hAlign=\"right\"/>\n");
    app(s, cap, &n, "  <style name=\"tlbl\"   fontName=\"Helvetica\" fontSize=\"9.5\" bold=\"1\" textColor=\"" INK "\" hAlign=\"right\"/>\n");
    app(s, cap, &n, "  <style name=\"tval\"   fontName=\"Helvetica\" fontSize=\"9.5\" textColor=\"" INK "\" hAlign=\"right\"/>\n");
    app(s, cap, &n, "  <style name=\"glbl\"   fontName=\"Helvetica\" fontSize=\"13\" bold=\"1\" textColor=\"" WHITE "\"/>\n");
    app(s, cap, &n, "  <style name=\"gval\"   fontName=\"Helvetica\" fontSize=\"13\" bold=\"1\" textColor=\"" WHITE "\" hAlign=\"right\"/>\n");
    app(s, cap, &n, "  <style name=\"note\"   fontName=\"Helvetica\" fontSize=\"8.5\" textColor=\"" GREY "\"/>\n");
    app(s, cap, &n, "  <style name=\"foot\"   fontName=\"Helvetica\" fontSize=\"8\" textColor=\"" GREY "\"/>\n");
    app(s, cap, &n, "  <style name=\"footr\"  fontName=\"Helvetica\" fontSize=\"8\" textColor=\"" GREY "\" hAlign=\"right\"/>\n");
    app(s, cap, &n, " </styles>\n");
    app(s, cap, &n, " <bands>\n");
    /* REPORT HEADER */
    app(s, cap, &n, "  <band kind=\"reportheader\" name=\"rh\" height=\"42\">\n");
    app(s, cap, &n, "   <text name=\"co\"   x=\"0\"  y=\"0\"  w=\"110\" h=\"9\" style=\"brand\" wordWrap=\"0\">ACME Corporation</text>\n");
    app(s, cap, &n, "   <text name=\"a1\"   x=\"0\"  y=\"10\" w=\"120\" h=\"4\" style=\"addr\" wordWrap=\"0\">123 Industrial Way  " DOT "  Springfield, IL 62704</text>\n");
    app(s, cap, &n, "   <text name=\"a2\"   x=\"0\"  y=\"14\" w=\"120\" h=\"4\" style=\"addr\" wordWrap=\"0\">+1 (555) 018-2245  " DOT "  billing@acme.example</text>\n");
    app(s, cap, &n, "   <text name=\"ti\"   x=\"92\" y=\"0\"  w=\"90\"  h=\"13\" style=\"title\" wordWrap=\"0\">INVOICE</text>\n");
    app(s, cap, &n, "   <text name=\"ml1\"  x=\"108\" y=\"15\" w=\"40\" h=\"4\" style=\"mlbl\" wordWrap=\"0\">INVOICE #</text>\n");
    app(s, cap, &n, "   <text name=\"mv1\"  x=\"150\" y=\"15\" w=\"32\" h=\"4\" style=\"mval\" wordWrap=\"0\">INV-1042</text>\n");
    app(s, cap, &n, "   <text name=\"ml2\"  x=\"108\" y=\"20\" w=\"40\" h=\"4\" style=\"mlbl\" wordWrap=\"0\">ISSUE DATE</text>\n");
    app(s, cap, &n, "   <text name=\"mv2\"  x=\"150\" y=\"20\" w=\"32\" h=\"4\" style=\"mval\" wordWrap=\"0\">2026-07-19</text>\n");
    app(s, cap, &n, "   <text name=\"ml3\"  x=\"108\" y=\"25\" w=\"40\" h=\"4\" style=\"mlbl\" wordWrap=\"0\">DUE DATE</text>\n");
    app(s, cap, &n, "   <text name=\"mv3\"  x=\"150\" y=\"25\" w=\"32\" h=\"4\" style=\"mval\" wordWrap=\"0\">2026-08-18</text>\n");
    app(s, cap, &n, "   <text name=\"bt\"   x=\"0\"  y=\"25\" w=\"60\" h=\"4\" style=\"billto\" wordWrap=\"0\">BILL TO</text>\n");
    app(s, cap, &n, "   <text name=\"c1\"   x=\"0\"  y=\"29.5\" w=\"95\" h=\"4.5\" style=\"cust\" wordWrap=\"0\">Globex Manufacturing Co.</text>\n");
    app(s, cap, &n, "   <text name=\"c2\"   x=\"0\"  y=\"33.5\" w=\"95\" h=\"4\" style=\"addr\" wordWrap=\"0\">500 Commerce Blvd, Metropolis, NY 10001</text>\n");
    app(s, cap, &n, "   <line name=\"rht\" orient=\"h\" scope=\"section\" vAlign=\"top\"    width=\"0.3\" color=\"" HAIR "\"/>\n");
    app(s, cap, &n, "   <line name=\"rhb\" orient=\"h\" scope=\"section\" vAlign=\"bottom\" width=\"1.1\" color=\"" NAVY "\"/>\n");
    app(s, cap, &n, "  </band>\n");
    /* COLUMN CAPTIONS */
    app(s, cap, &n, "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n");
    app(s, cap, &n, "   <shape name=\"bar\" x=\"0\" y=\"0\" w=\"182\" h=\"8\" shape=\"0\" backColor=\"" NAVY "\"/>\n");
    app(s, cap, &n, "   <text name=\"hI\" x=\"3\"   y=\"2\" w=\"88\" h=\"5\" style=\"colh\"  wordWrap=\"0\">DESCRIPTION</text>\n");
    app(s, cap, &n, "   <text name=\"hQ\" x=\"97\"  y=\"2\" w=\"16\" h=\"5\" style=\"colhr\" wordWrap=\"0\">QTY</text>\n");
    app(s, cap, &n, "   <text name=\"hP\" x=\"119\" y=\"2\" w=\"26\" h=\"5\" style=\"colhr\" wordWrap=\"0\">UNIT PRICE</text>\n");
    app(s, cap, &n, "   <text name=\"hA\" x=\"151\" y=\"2\" w=\"29\" h=\"5\" style=\"colhr\" wordWrap=\"0\">AMOUNT</text>\n");
    ColGrid(s, cap, &n, "phg");
    app(s, cap, &n, " </band>\n");
    /* DETAIL ROWS */
    app(s, cap, &n, "  <band kind=\"detail\" name=\"det\" height=\"7\" data=\"d\">\n");
    app(s, cap, &n, "   <shape name=\"zebra\" x=\"0\" y=\"0\" w=\"182\" h=\"7\" shape=\"0\" backColor=\"" SHADE "\" visible=\"RowNum % 2 = 0\"/>\n");
    app(s, cap, &n, "   <text name=\"dI\" x=\"3\"   y=\"1.6\" w=\"90\" h=\"4\" style=\"cell\"  wordWrap=\"0\">{{Item}}</text>\n");
    app(s, cap, &n, "   <text name=\"dQ\" x=\"97\"  y=\"1.6\" w=\"16\" h=\"4\" style=\"cellr\" wordWrap=\"0\">{{Qty}}</text>\n");
    app(s, cap, &n, "   <text name=\"dP\" x=\"119\" y=\"1.6\" w=\"26\" h=\"4\" style=\"cellr\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', Price)}}</text>\n");
    app(s, cap, &n, "   <text name=\"dA\" x=\"151\" y=\"1.6\" w=\"29\" h=\"4\" style=\"cellr\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', Qty*Price)}}</text>\n");
    ColGrid(s, cap, &n, "dg");
    app(s, cap, &n, "   <line name=\"drb\" orient=\"h\" scope=\"section\" vAlign=\"bottom\" width=\"0.2\" color=\"" HAIR "\"/>\n");
    app(s, cap, &n, "  </band>\n");
    /* SUMMARY */
    app(s, cap, &n, "  <band kind=\"summary\" name=\"sm\" height=\"46\">\n");
    app(s, cap, &n, "   <line name=\"stop\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.6\" color=\"" NAVY "\"/>\n");
    app(s, cap, &n, "   <text name=\"nh\" x=\"0\" y=\"4\"  w=\"95\" h=\"4\" style=\"billto\" wordWrap=\"0\">NOTES</text>\n");
    app(s, cap, &n, "   <text name=\"n1\" x=\"0\" y=\"8.5\" w=\"100\" h=\"4\" style=\"note\" wordWrap=\"0\">Payment due within 30 days. Bank transfer to</text>\n");
    app(s, cap, &n, "   <text name=\"n2\" x=\"0\" y=\"12\"  w=\"100\" h=\"4\" style=\"note\" wordWrap=\"0\">ACME Corp " DOT " IBAN GB00 ACME 0000 1042 " DOT " Ref INV-1042.</text>\n");
    app(s, cap, &n, "   <text name=\"s1l\" x=\"100\" y=\"4\"  w=\"45\" h=\"4.5\" style=\"tlbl\" wordWrap=\"0\">Subtotal</text>\n");
    app(s, cap, &n, "   <text name=\"s1v\" x=\"149\" y=\"4\"  w=\"31\" h=\"4.5\" style=\"tval\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price))}}</text>\n");
    app(s, cap, &n, "   <text name=\"s2l\" x=\"100\" y=\"9.5\" w=\"45\" h=\"4.5\" style=\"tlbl\" wordWrap=\"0\">Tax (8.5%)</text>\n");
    app(s, cap, &n, "   <text name=\"s2v\" x=\"149\" y=\"9.5\" w=\"31\" h=\"4.5\" style=\"tval\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*0.085)}}</text>\n");
    app(s, cap, &n, "   <shape name=\"gbar\" x=\"100\" y=\"16\" w=\"82\" h=\"10\" shape=\"0\" backColor=\"" NAVY "\"/>\n");
    app(s, cap, &n, "   <text name=\"gl\" x=\"104\" y=\"18.5\" w=\"40\" h=\"6\" style=\"glbl\" wordWrap=\"0\">TOTAL</text>\n");
    app(s, cap, &n, "   <text name=\"gv\" x=\"149\" y=\"18.5\" w=\"29\" h=\"6\" style=\"gval\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*1.085)}}</text>\n");
    app(s, cap, &n, "   <text name=\"gc\" x=\"100\" y=\"28\" w=\"82\" h=\"4\" style=\"footr\" wordWrap=\"0\">USD " DOT " Total items {{expr: COUNT()}}</text>\n");
    app(s, cap, &n, "  </band>\n");
    /* PAGE FOOTER */
    app(s, cap, &n, "  <band kind=\"pagefooter\" name=\"pf\" height=\"12\">\n");
    app(s, cap, &n, "   <line name=\"pft\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.3\" color=\"" GRID "\"/>\n");
    app(s, cap, &n, "   <text name=\"ty\" x=\"0\"   y=\"3\" w=\"120\" h=\"4\" style=\"foot\"  wordWrap=\"0\">Thank you for your business.  Questions? billing@acme.example</text>\n");
    app(s, cap, &n, "   <text name=\"pg\" x=\"120\" y=\"3\" w=\"62\"  h=\"4\" style=\"footr\" wordWrap=\"0\">Page {{var:PageNo}} of {{var:TotalPages}}</text>\n");
    app(s, cap, &n, "  </band>\n");
    app(s, cap, &n, " </bands>\n");
    app(s, cap, &n, "</report>\n");
}

static void ExportOne(TRPTJOB job, int target, const char* path) {
    if (rptExportA(job, target, path) != 0) printf("  wrote %s\n", path);
    else printf("  EXPORT FAILED: %s\n", path);
}

int main(void) {
    PPDF pdf; TRPT eng; TRPTJOB job;
    const char* csv = "18_items.csv";
    const char* lrpt = "18_invoice.lrpt";
    char xml[12288];
    const char* csvData =
        "Item,Qty,Price\n"
        "Precision Widget Assembly,4,42.50\n"
        "Gadget Control Module,2,149.50\n"
        "Shielded Signal Cable (3m),10,4.75\n"
        "Universal Power Adapter,3,28.00\n"
        "Steel Mounting Bracket,12,3.25\n"
        "Thermal Interface Kit,5,11.20\n";
    if (!BootEngine(&pdf, &eng)) return 1;

    WriteText(csv, csvData);
    BuildXml(xml, sizeof(xml), csv);
    WriteText(lrpt, xml);

    job = rptOpenReportA(eng, lrpt);
    if (!job) { printf("open failed\n"); DumpRptError(eng); goto cleanup; }
    if (rptRender(job) == 0) { printf("render failed\n"); DumpRptError(eng); goto closejob; }
    printf("rendered %d page(s); exporting:\n", rptGetPageCount(job));
    ExportOne(job, RPT_EXP_PDF, "18_invoice.pdf");
    ExportOne(job, RPT_EXP_HTML, "18_invoice.html");
    ExportOne(job, RPT_EXP_SVG, "18_invoice.svg");
    ExportOne(job, RPT_EXP_TEXT, "18_invoice.txt");
    ExportOne(job, RPT_EXP_CSV, "18_invoice.csv");
    ExportOne(job, RPT_EXP_XLSX, "18_invoice.xlsx");
    ExportOne(job, RPT_EXP_XLS, "18_invoice.xls");
closejob:
    rptCloseReport(job);
cleanup:
    rptDeleteEngine(eng);
    pdfDeletePDF(pdf);
    return 0;
}

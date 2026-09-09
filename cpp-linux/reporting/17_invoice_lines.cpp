// 17_invoice_lines -- C++ port of examples\Vb6\reporting\17_invoice_lines.bas
#include "rptcommon.h"

static std::string ReplaceAll(std::string s, const std::string& from, const std::string& to) {
    size_t p = 0;
    while ((p = s.find(from, p)) != std::string::npos) { s.replace(p, from.size(), to); p += to.size(); }
    return s;
}

static std::string CsvData() {
    return
        "Item,Qty,Price\n"
        "Widget Assembly A,2,25.00\n"
        "Gadget Module B,1,149.50\n"
        "Shielded Cable C,5,4.75\n"
        "Power Adapter D,3,12.00\n"
        "Mounting Bracket E,8,3.25\n";
}

static std::string BuildXml() {
    return
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<report name=\"Invoice\" tagLangVersion=\"1\">\n"
        " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n"
        " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"{{CSV}}\"/></datasources>\n"
        " <styles>\n"
        "  <style name=\"h1\" fontName=\"Helvetica\" fontSize=\"22\" bold=\"1\"/>\n"
        "  <style name=\"lbl\" fontName=\"Helvetica\" fontSize=\"9\" bold=\"1\"/>\n"
        "  <style name=\"tot\" fontName=\"Helvetica\" fontSize=\"12\" bold=\"1\"/>\n"
        " </styles>\n"
        " <bands>\n"
        "  <band kind=\"reportheader\" name=\"rh\" height=\"30\">\n"
        "   <text name=\"co\"  x=\"0\"   y=\"0\"  w=\"110\" h=\"10\" fontSize=\"20\" bold=\"1\" wordWrap=\"0\">ACME Corporation</text>\n"
        "   <text name=\"ti\"  x=\"110\" y=\"0\"  w=\"70\"  h=\"10\" style=\"h1\" hAlign=\"right\" wordWrap=\"0\">INVOICE</text>\n"
        "   <text name=\"m1\"  x=\"0\"   y=\"13\" w=\"120\" h=\"5\"  fontSize=\"9\" wordWrap=\"0\">Invoice #: INV-1042    Date: 2026-07-19</text>\n"
        "   <text name=\"m2\"  x=\"110\" y=\"13\" w=\"70\"  h=\"5\"  fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">Terms: Net 30</text>\n"
        "   <line name=\"hr1\" orient=\"h\" scope=\"page\" x=\"0\" y=\"24\" w=\"0\" h=\"2\" vAlign=\"middle\" width=\"1.2\" color=\"00CC0000\"/>\n"
        "  </band>\n"
        "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n"
        "   <text name=\"ci\" x=\"0\"   y=\"0\" w=\"78\"  h=\"5\" style=\"lbl\" wordWrap=\"0\">Description</text>\n"
        "   <text name=\"cq\" x=\"80\"  y=\"0\" w=\"23\"  h=\"5\" style=\"lbl\" hAlign=\"right\" wordWrap=\"0\">Qty</text>\n"
        "   <text name=\"cp\" x=\"105\" y=\"0\" w=\"33\"  h=\"5\" style=\"lbl\" hAlign=\"right\" wordWrap=\"0\">Unit Price</text>\n"
        "   <text name=\"ca\" x=\"140\" y=\"0\" w=\"40\"  h=\"5\" style=\"lbl\" hAlign=\"right\" wordWrap=\"0\">Amount</text>\n"
        "   <line name=\"phv1\" orient=\"v\" scope=\"section\" x=\"79\"  width=\"0.2\" color=\"00909090\"/>\n"
        "   <line name=\"phv2\" orient=\"v\" scope=\"section\" x=\"104\" width=\"0.2\" color=\"00909090\"/>\n"
        "   <line name=\"phv3\" orient=\"v\" scope=\"section\" x=\"139\" width=\"0.2\" color=\"00909090\"/>\n"
        "   <line name=\"hr2\" orient=\"h\" x=\"0\" y=\"6\" w=\"180\" h=\"1\" vAlign=\"middle\" width=\"0.5\" color=\"00404040\"/>\n"
        "  </band>\n"
        "  <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n"
        "   <text name=\"Description\" x=\"0\"   y=\"0\" w=\"78\"  h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{Item}}</text>\n"
        "   <text name=\"Qty\"         x=\"80\"  y=\"0\" w=\"23\"  h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{Qty}}</text>\n"
        "   <text name=\"UnitPrice\"   x=\"105\" y=\"0\" w=\"33\"  h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', Price)}}</text>\n"
        "   <text name=\"Amount\"      x=\"140\" y=\"0\" w=\"40\"  h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', Qty*Price)}}</text>\n"
        "   <line name=\"dv1\" orient=\"v\" scope=\"section\" x=\"79\"  width=\"0.2\" color=\"00CCCCCC\"/>\n"
        "   <line name=\"dv2\" orient=\"v\" scope=\"section\" x=\"104\" width=\"0.2\" color=\"00CCCCCC\"/>\n"
        "   <line name=\"dv3\" orient=\"v\" scope=\"section\" x=\"139\" width=\"0.2\" color=\"00CCCCCC\"/>\n"
        "   <line name=\"rr\" orient=\"h\" x=\"0\" y=\"0\" w=\"180\" h=\"5.5\" vAlign=\"bottom\" dash=\"dot\" width=\"0.2\" color=\"00AAAAAA\"/>\n"
        "  </band>\n"
        "  <band kind=\"summary\" name=\"sm\" height=\"52\">\n"
        "   <text name=\"sl1\" x=\"115\" y=\"1\" w=\"30\" h=\"5\" style=\"lbl\" wordWrap=\"0\">Subtotal</text>\n"
        "   <text name=\"sv1\" x=\"145\" y=\"1\" w=\"35\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price))}}</text>\n"
        "   <text name=\"sl2\" x=\"115\" y=\"7\" w=\"30\" h=\"5\" style=\"lbl\" wordWrap=\"0\">Tax (10%)</text>\n"
        "   <text name=\"sv2\" x=\"145\" y=\"7\" w=\"35\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*0.1)}}</text>\n"
        "   <line name=\"dl\" orient=\"h\" x=\"115\" y=\"14\" w=\"65\" h=\"1\" double=\"1\" width=\"0.4\" color=\"00404040\"/>\n"
        "   <text name=\"tl\" x=\"115\" y=\"16\" w=\"30\" h=\"6\" style=\"tot\" wordWrap=\"0\">TOTAL</text>\n"
        "   <text name=\"tv\" x=\"140\" y=\"16\" w=\"40\" h=\"6\" style=\"tot\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*1.1)}}</text>\n"
        "   <line name=\"ac\" orient=\"h\" x=\"115\" y=\"24\" w=\"65\" h=\"1\" double=\"1\" dash=\"dot\" width=\"0.35\" color=\"000000CC\"/>\n"
        "   <line name=\"sg\" orient=\"h\" x=\"0\" y=\"40\" w=\"70\" h=\"1\" dash=\"dash\" width=\"0.4\" cap=\"round\" color=\"00404040\"/>\n"
        "   <text name=\"sgl\" x=\"0\" y=\"41\" w=\"70\" h=\"5\" fontSize=\"8\" wordWrap=\"0\">Authorized Signature</text>\n"
        "   <text name=\"pd\" x=\"127\" y=\"34\" w=\"40\" h=\"7\" style=\"tot\" wordWrap=\"0\">PAID</text>\n"
        "   <line name=\"fr\" orient=\"h\" x=\"127\" y=\"43\" length=\"24\" width=\"1.0\" cap=\"round\" color=\"000000CC\"/>\n"
        "  </band>\n"
        " </bands>\n"
        "</report>\n";
}

static void ExportOne(TRPTJOB Job, SI32 Target, const char* Path) {
    if (rptExportA(Job, Target, Path) != 0) printf("  wrote %s\n", Path);
    else printf("  EXPORT FAILED for %s\n", Path);
}

int main() {
    ChdirToExe();
    if (!BootEngine()) return 0;

    const char* Csv = "17_items.csv";
    WriteText(Csv, CsvData());

    std::string Xml = ReplaceAll(BuildXml(), "{{CSV}}", Csv);
    const char* Lrpt = "17_invoice.lrpt";
    WriteText(Lrpt, Xml);

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }
    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); goto CloseJob; }
    printf("rendered %d page(s); exporting to 7 formats:\n", (int)rptGetPageCount(Job));
    ExportOne(Job, RPT_EXP_PDF, "17_invoice.pdf");
    ExportOne(Job, RPT_EXP_HTML, "17_invoice.html");
    ExportOne(Job, RPT_EXP_SVG, "17_invoice.svg");
    ExportOne(Job, RPT_EXP_TEXT, "17_invoice.txt");
    ExportOne(Job, RPT_EXP_CSV, "17_invoice.csv");
    ExportOne(Job, RPT_EXP_XLSX, "17_invoice.xlsx");
    ExportOne(Job, RPT_EXP_XLS, "17_invoice.xls");
CloseJob:
    rptCloseReport(Job);
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}

//  LumasReport example 18 -- Professional FRAMED invoice (C# port)
//  A polished, print-ready invoice built from the banded model + the SECTION-
//  BOUNDED line feature (scope="section"). Money columns right-aligned; totals use
//  inline SUM(Qty*Price). Exports to PDF/HTML/SVG/TEXT + CSV/XLSX/XLS.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Ex18
{
    const string PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0";
    const string RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA";

    // Colours are COLORREF 00BBGGRR (low byte = red).
    const string NAVY = "005F3A1F";
    const string INK = "00222222";
    const string GREY = "00808080";
    const string GRID = "00B9B9B9";
    const string HAIR = "00D8D8D8";
    const string SHADE = "00F4F1EC";
    const string WHITE = "00FFFFFF";

    static string CsvData()
    {
        string s = "";
        s += "Item,Qty,Price\n";
        s += "Precision Widget Assembly,4,42.50\n";
        s += "Gadget Control Module,2,149.50\n";
        s += "Shielded Signal Cable (3m),10,4.75\n";
        s += "Universal Power Adapter,3,28.00\n";
        s += "Steel Mounting Bracket,12,3.25\n";
        s += "Thermal Interface Kit,5,11.20\n";
        return s;
    }

    // The five vertical column dividers, section-scoped so each spans its band.
    static string ColGrid(string tag)
    {
        string s = "";
        s += "   <line name=\"" + tag + "a\" orient=\"v\" scope=\"section\" x=\"0\"   width=\"0.35\" color=\"" + GRID + "\"/>\n";
        s += "   <line name=\"" + tag + "b\" orient=\"v\" scope=\"section\" x=\"95\"  width=\"0.35\" color=\"" + GRID + "\"/>\n";
        s += "   <line name=\"" + tag + "c\" orient=\"v\" scope=\"section\" x=\"117\" width=\"0.35\" color=\"" + GRID + "\"/>\n";
        s += "   <line name=\"" + tag + "d\" orient=\"v\" scope=\"section\" x=\"149\" width=\"0.35\" color=\"" + GRID + "\"/>\n";
        s += "   <line name=\"" + tag + "e\" orient=\"v\" scope=\"section\" x=\"182\" width=\"0.35\" color=\"" + GRID + "\"/>\n";
        return s;
    }

    static string BuildXml(string csv)
    {
        string dot = "·";   // middle dot U+00B7
        string s = "";
        s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        s += "<report name=\"InvoicePro\" tagLangVersion=\"1\">\n";
        s += " <page width=\"210\" height=\"297\" marginLeft=\"14\" marginTop=\"14\" marginRight=\"14\" marginBottom=\"16\"/>\n";
        s += " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"" + csv + "\"/></datasources>\n";
        s += " <variables><variable name=\"PageNo\" init=\"1\"/></variables>\n";
        s += " <styles>\n";
        s += "  <style name=\"brand\"  fontName=\"Helvetica\" fontSize=\"20\" bold=\"1\" textColor=\"" + NAVY + "\"/>\n";
        s += "  <style name=\"addr\"   fontName=\"Helvetica\" fontSize=\"8\"  textColor=\"" + GREY + "\"/>\n";
        s += "  <style name=\"title\"  fontName=\"Helvetica\" fontSize=\"30\" bold=\"1\" textColor=\"" + NAVY + "\" hAlign=\"right\"/>\n";
        s += "  <style name=\"mlbl\"   fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"" + GREY + "\" hAlign=\"right\"/>\n";
        s += "  <style name=\"mval\"   fontName=\"Helvetica\" fontSize=\"8.5\" textColor=\"" + INK + "\" hAlign=\"right\"/>\n";
        s += "  <style name=\"billto\" fontName=\"Helvetica\" fontSize=\"8\" bold=\"1\" textColor=\"" + NAVY + "\"/>\n";
        s += "  <style name=\"cust\"   fontName=\"Helvetica\" fontSize=\"9.5\" textColor=\"" + INK + "\"/>\n";
        s += "  <style name=\"colh\"   fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"" + WHITE + "\"/>\n";
        s += "  <style name=\"colhr\"  fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"" + WHITE + "\" hAlign=\"right\"/>\n";
        s += "  <style name=\"cell\"   fontName=\"Helvetica\" fontSize=\"9.5\" textColor=\"" + INK + "\"/>\n";
        s += "  <style name=\"cellr\"  fontName=\"Helvetica\" fontSize=\"9.5\" textColor=\"" + INK + "\" hAlign=\"right\"/>\n";
        s += "  <style name=\"tlbl\"   fontName=\"Helvetica\" fontSize=\"9.5\" bold=\"1\" textColor=\"" + INK + "\" hAlign=\"right\"/>\n";
        s += "  <style name=\"tval\"   fontName=\"Helvetica\" fontSize=\"9.5\" textColor=\"" + INK + "\" hAlign=\"right\"/>\n";
        s += "  <style name=\"glbl\"   fontName=\"Helvetica\" fontSize=\"13\" bold=\"1\" textColor=\"" + WHITE + "\"/>\n";
        s += "  <style name=\"gval\"   fontName=\"Helvetica\" fontSize=\"13\" bold=\"1\" textColor=\"" + WHITE + "\" hAlign=\"right\"/>\n";
        s += "  <style name=\"note\"   fontName=\"Helvetica\" fontSize=\"8.5\" textColor=\"" + GREY + "\"/>\n";
        s += "  <style name=\"foot\"   fontName=\"Helvetica\" fontSize=\"8\" textColor=\"" + GREY + "\"/>\n";
        s += "  <style name=\"footr\"  fontName=\"Helvetica\" fontSize=\"8\" textColor=\"" + GREY + "\" hAlign=\"right\"/>\n";
        s += " </styles>\n";
        s += " <bands>\n";
        // ============ REPORT HEADER ============
        s += "  <band kind=\"reportheader\" name=\"rh\" height=\"42\">\n";
        s += "   <text name=\"co\"   x=\"0\"  y=\"0\"  w=\"110\" h=\"9\" style=\"brand\" wordWrap=\"0\">ACME Corporation</text>\n";
        s += "   <text name=\"a1\"   x=\"0\"  y=\"10\" w=\"120\" h=\"4\" style=\"addr\" wordWrap=\"0\">123 Industrial Way  " + dot + "  Springfield, IL 62704</text>\n";
        s += "   <text name=\"a2\"   x=\"0\"  y=\"14\" w=\"120\" h=\"4\" style=\"addr\" wordWrap=\"0\">+1 (555) 018-2245  " + dot + "  billing@acme.example</text>\n";
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
        s += "   <line name=\"rht\" orient=\"h\" scope=\"section\" vAlign=\"top\"    width=\"0.3\" color=\"" + HAIR + "\"/>\n";
        s += "   <line name=\"rhb\" orient=\"h\" scope=\"section\" vAlign=\"bottom\" width=\"1.1\" color=\"" + NAVY + "\"/>\n";
        s += "  </band>\n";
        // ============ COLUMN CAPTIONS (navy bar) ============
        s += "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n";
        s += "   <shape name=\"bar\" x=\"0\" y=\"0\" w=\"182\" h=\"8\" shape=\"0\" backColor=\"" + NAVY + "\"/>\n";
        s += "   <text name=\"hI\" x=\"3\"   y=\"2\" w=\"88\" h=\"5\" style=\"colh\"  wordWrap=\"0\">DESCRIPTION</text>\n";
        s += "   <text name=\"hQ\" x=\"97\"  y=\"2\" w=\"16\" h=\"5\" style=\"colhr\" wordWrap=\"0\">QTY</text>\n";
        s += "   <text name=\"hP\" x=\"119\" y=\"2\" w=\"26\" h=\"5\" style=\"colhr\" wordWrap=\"0\">UNIT PRICE</text>\n";
        s += "   <text name=\"hA\" x=\"151\" y=\"2\" w=\"29\" h=\"5\" style=\"colhr\" wordWrap=\"0\">AMOUNT</text>\n";
        s += ColGrid("phg");
        s += " </band>\n";
        // ============ DETAIL ROWS ============
        s += "  <band kind=\"detail\" name=\"det\" height=\"7\" data=\"d\">\n";
        s += "   <shape name=\"zebra\" x=\"0\" y=\"0\" w=\"182\" h=\"7\" shape=\"0\" backColor=\"" + SHADE + "\" visible=\"RowNum % 2 = 0\"/>\n";
        s += "   <text name=\"dI\" x=\"3\"   y=\"1.6\" w=\"90\" h=\"4\" style=\"cell\"  wordWrap=\"0\">{{Item}}</text>\n";
        s += "   <text name=\"dQ\" x=\"97\"  y=\"1.6\" w=\"16\" h=\"4\" style=\"cellr\" wordWrap=\"0\">{{Qty}}</text>\n";
        s += "   <text name=\"dP\" x=\"119\" y=\"1.6\" w=\"26\" h=\"4\" style=\"cellr\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', Price)}}</text>\n";
        s += "   <text name=\"dA\" x=\"151\" y=\"1.6\" w=\"29\" h=\"4\" style=\"cellr\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', Qty*Price)}}</text>\n";
        s += ColGrid("dg");
        s += "   <line name=\"drb\" orient=\"h\" scope=\"section\" vAlign=\"bottom\" width=\"0.2\" color=\"" + HAIR + "\"/>\n";
        s += "  </band>\n";
        // ============ SUMMARY ============
        s += "  <band kind=\"summary\" name=\"sm\" height=\"46\">\n";
        s += "   <line name=\"stop\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.6\" color=\"" + NAVY + "\"/>\n";
        s += "   <text name=\"nh\" x=\"0\" y=\"4\"  w=\"95\" h=\"4\" style=\"billto\" wordWrap=\"0\">NOTES</text>\n";
        s += "   <text name=\"n1\" x=\"0\" y=\"8.5\" w=\"100\" h=\"4\" style=\"note\" wordWrap=\"0\">Payment due within 30 days. Bank transfer to</text>\n";
        s += "   <text name=\"n2\" x=\"0\" y=\"12\"  w=\"100\" h=\"4\" style=\"note\" wordWrap=\"0\">ACME Corp " + dot + " IBAN GB00 ACME 0000 1042 " + dot + " Ref INV-1042.</text>\n";
        s += "   <text name=\"s1l\" x=\"100\" y=\"4\"  w=\"45\" h=\"4.5\" style=\"tlbl\" wordWrap=\"0\">Subtotal</text>\n";
        s += "   <text name=\"s1v\" x=\"149\" y=\"4\"  w=\"31\" h=\"4.5\" style=\"tval\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price))}}</text>\n";
        s += "   <text name=\"s2l\" x=\"100\" y=\"9.5\" w=\"45\" h=\"4.5\" style=\"tlbl\" wordWrap=\"0\">Tax (8.5%)</text>\n";
        s += "   <text name=\"s2v\" x=\"149\" y=\"9.5\" w=\"31\" h=\"4.5\" style=\"tval\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*0.085)}}</text>\n";
        s += "   <shape name=\"gbar\" x=\"100\" y=\"16\" w=\"82\" h=\"10\" shape=\"0\" backColor=\"" + NAVY + "\"/>\n";
        s += "   <text name=\"gl\" x=\"104\" y=\"18.5\" w=\"40\" h=\"6\" style=\"glbl\" wordWrap=\"0\">TOTAL</text>\n";
        s += "   <text name=\"gv\" x=\"149\" y=\"18.5\" w=\"29\" h=\"6\" style=\"gval\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*1.085)}}</text>\n";
        s += "   <text name=\"gc\" x=\"100\" y=\"28\" w=\"82\" h=\"4\" style=\"footr\" wordWrap=\"0\">USD " + dot + " Total items {{expr: COUNT()}}</text>\n";
        s += "  </band>\n";
        // ============ PAGE FOOTER ============
        s += "  <band kind=\"pagefooter\" name=\"pf\" height=\"12\">\n";
        s += "   <line name=\"pft\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.3\" color=\"" + GRID + "\"/>\n";
        s += "   <text name=\"ty\" x=\"0\"   y=\"3\" w=\"120\" h=\"4\" style=\"foot\"  wordWrap=\"0\">Thank you for your business.  Questions? billing@acme.example</text>\n";
        s += "   <text name=\"pg\" x=\"120\" y=\"3\" w=\"62\"  h=\"4\" style=\"footr\" wordWrap=\"0\">Page {{var:PageNo}} of {{var:TotalPages}}</text>\n";
        s += "  </band>\n";
        s += " </bands>\n";
        s += "</report>\n";
        return s;
    }

    static void ExportOne(IntPtr job, int target, string path)
    {
        if (LumasPdf.rptExportA(job, target, path)) Console.WriteLine("  wrote " + path);
        else Console.WriteLine("  EXPORT FAILED: " + path);
    }

    static void Main()
    {
        IntPtr pdf, eng;
        if (!BootEngine(out pdf, out eng)) return;

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string csv = Path.Combine(dir, "18_items.csv");
        File.WriteAllText(csv, CsvData());
        string lrpt = Path.Combine(dir, "18_invoice.lrpt");
        File.WriteAllText(lrpt, BuildXml(csv));

        IntPtr job = LumasPdf.rptOpenReportA(eng, lrpt);
        if (job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(eng); goto Cleanup; }
        if (!LumasPdf.rptRender(job)) { Console.WriteLine("render failed"); DumpRptError(eng); goto CloseJob; }
        Console.WriteLine("rendered " + LumasPdf.rptGetPageCount(job) + " page(s); exporting:");
        ExportOne(job, LumasPdfConsts.RPT_EXP_PDF, Path.Combine(dir, "18_invoice.pdf"));
        ExportOne(job, LumasPdfConsts.RPT_EXP_HTML, Path.Combine(dir, "18_invoice.html"));
        ExportOne(job, LumasPdfConsts.RPT_EXP_SVG, Path.Combine(dir, "18_invoice.svg"));
        ExportOne(job, LumasPdfConsts.RPT_EXP_TEXT, Path.Combine(dir, "18_invoice.txt"));
        ExportOne(job, LumasPdfConsts.RPT_EXP_CSV, Path.Combine(dir, "18_invoice.csv"));
        ExportOne(job, LumasPdfConsts.RPT_EXP_XLSX, Path.Combine(dir, "18_invoice.xlsx"));
        ExportOne(job, LumasPdfConsts.RPT_EXP_XLS, Path.Combine(dir, "18_invoice.xls"));
    CloseJob:
        LumasPdf.rptCloseReport(job);
    Cleanup:
        LumasPdf.rptDeleteEngine(eng);
        LumasPdf.pdfDeletePDF(pdf);
    }

    static bool BootEngine(out IntPtr pdf, out IntPtr eng)
    {
        eng = IntPtr.Zero;
        pdf = LumasPdf.pdfNewPDF();
        if (pdf == IntPtr.Zero) { Console.WriteLine("pdfNewPDF failed"); return false; }
        LumasPdf.pdfSetLicenseKey(pdf, PDF_DEMO_KEY);
        LumasPdf.rptSetRptLicenseKeyA(pdf, RPT_DEMO_KEY);
        eng = LumasPdf.rptCreateEngineA(pdf, null);
        if (eng == IntPtr.Zero) { Console.WriteLine("rptCreateEngine failed"); return false; }
        return true;
    }

    static void DumpRptError(IntPtr eng)
    {
        IntPtr p = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(TRptErrorInfoC)));
        try
        {
            if (LumasPdf.rptGetLastError(eng, p))
            {
                var info = (TRptErrorInfoC)Marshal.PtrToStructure(p, typeof(TRptErrorInfoC));
                if (info.Code != 0)
                    Console.WriteLine("  ! rpt error " + info.Code + " [" + info.Module_ + "] at " + info.Location + ": " + info.Msg);
            }
        }
        finally { Marshal.FreeHGlobal(p); }
    }
}

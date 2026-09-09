//  LumasReport example 17 -- Invoice with comprehensive LINE usage, exported to
//  MULTIPLE formats (PDF, HTML, SVG, TEXT + native CSV, XLSX, XLS).  (C# port)
//  Demonstrates the full <line> surface and inline aggregates: SUM(Qty*Price).
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Ex17
{
    const string PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0";
    const string RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA";

    static string CsvData()
    {
        string s = "";
        s += "Item,Qty,Price\n";
        s += "Widget Assembly A,2,25.00\n";
        s += "Gadget Module B,1,149.50\n";
        s += "Shielded Cable C,5,4.75\n";
        s += "Power Adapter D,3,12.00\n";
        s += "Mounting Bracket E,8,3.25\n";
        return s;
    }

    static string BuildXml()
    {
        string s = "";
        s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        s += "<report name=\"Invoice\" tagLangVersion=\"1\">\n";
        s += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        s += " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"{{CSV}}\"/></datasources>\n";
        s += " <styles>\n";
        s += "  <style name=\"h1\" fontName=\"Helvetica\" fontSize=\"22\" bold=\"1\"/>\n";
        s += "  <style name=\"lbl\" fontName=\"Helvetica\" fontSize=\"9\" bold=\"1\"/>\n";
        s += "  <style name=\"tot\" fontName=\"Helvetica\" fontSize=\"12\" bold=\"1\"/>\n";
        s += " </styles>\n";
        s += " <bands>\n";
        s += "  <band kind=\"reportheader\" name=\"rh\" height=\"30\">\n";
        s += "   <text name=\"co\"  x=\"0\"   y=\"0\"  w=\"110\" h=\"10\" fontSize=\"20\" bold=\"1\" wordWrap=\"0\">ACME Corporation</text>\n";
        s += "   <text name=\"ti\"  x=\"110\" y=\"0\"  w=\"70\"  h=\"10\" style=\"h1\" hAlign=\"right\" wordWrap=\"0\">INVOICE</text>\n";
        s += "   <text name=\"m1\"  x=\"0\"   y=\"13\" w=\"120\" h=\"5\"  fontSize=\"9\" wordWrap=\"0\">Invoice #: INV-1042    Date: 2026-07-19</text>\n";
        s += "   <text name=\"m2\"  x=\"110\" y=\"13\" w=\"70\"  h=\"5\"  fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">Terms: Net 30</text>\n";
        s += "   <line name=\"hr1\" orient=\"h\" scope=\"page\" x=\"0\" y=\"24\" w=\"0\" h=\"2\" vAlign=\"middle\" width=\"1.2\" color=\"00CC0000\"/>\n";
        s += "  </band>\n";
        s += "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n";
        s += "   <text name=\"ci\" x=\"0\"   y=\"0\" w=\"78\"  h=\"5\" style=\"lbl\" wordWrap=\"0\">Description</text>\n";
        s += "   <text name=\"cq\" x=\"80\"  y=\"0\" w=\"23\"  h=\"5\" style=\"lbl\" hAlign=\"right\" wordWrap=\"0\">Qty</text>\n";
        s += "   <text name=\"cp\" x=\"105\" y=\"0\" w=\"33\"  h=\"5\" style=\"lbl\" hAlign=\"right\" wordWrap=\"0\">Unit Price</text>\n";
        s += "   <text name=\"ca\" x=\"140\" y=\"0\" w=\"40\"  h=\"5\" style=\"lbl\" hAlign=\"right\" wordWrap=\"0\">Amount</text>\n";
        s += "   <line name=\"phv1\" orient=\"v\" scope=\"section\" x=\"79\"  width=\"0.2\" color=\"00909090\"/>\n";
        s += "   <line name=\"phv2\" orient=\"v\" scope=\"section\" x=\"104\" width=\"0.2\" color=\"00909090\"/>\n";
        s += "   <line name=\"phv3\" orient=\"v\" scope=\"section\" x=\"139\" width=\"0.2\" color=\"00909090\"/>\n";
        s += "   <line name=\"hr2\" orient=\"h\" x=\"0\" y=\"6\" w=\"180\" h=\"1\" vAlign=\"middle\" width=\"0.5\" color=\"00404040\"/>\n";
        s += "  </band>\n";
        s += "  <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n";
        s += "   <text name=\"Description\" x=\"0\"   y=\"0\" w=\"78\"  h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{Item}}</text>\n";
        s += "   <text name=\"Qty\"         x=\"80\"  y=\"0\" w=\"23\"  h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{Qty}}</text>\n";
        s += "   <text name=\"UnitPrice\"   x=\"105\" y=\"0\" w=\"33\"  h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', Price)}}</text>\n";
        s += "   <text name=\"Amount\"      x=\"140\" y=\"0\" w=\"40\"  h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', Qty*Price)}}</text>\n";
        s += "   <line name=\"dv1\" orient=\"v\" scope=\"section\" x=\"79\"  width=\"0.2\" color=\"00CCCCCC\"/>\n";
        s += "   <line name=\"dv2\" orient=\"v\" scope=\"section\" x=\"104\" width=\"0.2\" color=\"00CCCCCC\"/>\n";
        s += "   <line name=\"dv3\" orient=\"v\" scope=\"section\" x=\"139\" width=\"0.2\" color=\"00CCCCCC\"/>\n";
        s += "   <line name=\"rr\" orient=\"h\" x=\"0\" y=\"0\" w=\"180\" h=\"5.5\" vAlign=\"bottom\" dash=\"dot\" width=\"0.2\" color=\"00AAAAAA\"/>\n";
        s += "  </band>\n";
        s += "  <band kind=\"summary\" name=\"sm\" height=\"52\">\n";
        s += "   <text name=\"sl1\" x=\"115\" y=\"1\" w=\"30\" h=\"5\" style=\"lbl\" wordWrap=\"0\">Subtotal</text>\n";
        s += "   <text name=\"sv1\" x=\"145\" y=\"1\" w=\"35\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price))}}</text>\n";
        s += "   <text name=\"sl2\" x=\"115\" y=\"7\" w=\"30\" h=\"5\" style=\"lbl\" wordWrap=\"0\">Tax (10%)</text>\n";
        s += "   <text name=\"sv2\" x=\"145\" y=\"7\" w=\"35\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*0.1)}}</text>\n";
        s += "   <line name=\"dl\" orient=\"h\" x=\"115\" y=\"14\" w=\"65\" h=\"1\" double=\"1\" width=\"0.4\" color=\"00404040\"/>\n";
        s += "   <text name=\"tl\" x=\"115\" y=\"16\" w=\"30\" h=\"6\" style=\"tot\" wordWrap=\"0\">TOTAL</text>\n";
        s += "   <text name=\"tv\" x=\"140\" y=\"16\" w=\"40\" h=\"6\" style=\"tot\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', SUM(Qty*Price)*1.1)}}</text>\n";
        s += "   <line name=\"ac\" orient=\"h\" x=\"115\" y=\"24\" w=\"65\" h=\"1\" double=\"1\" dash=\"dot\" width=\"0.35\" color=\"000000CC\"/>\n";
        s += "   <line name=\"sg\" orient=\"h\" x=\"0\" y=\"40\" w=\"70\" h=\"1\" dash=\"dash\" width=\"0.4\" cap=\"round\" color=\"00404040\"/>\n";
        s += "   <text name=\"sgl\" x=\"0\" y=\"41\" w=\"70\" h=\"5\" fontSize=\"8\" wordWrap=\"0\">Authorized Signature</text>\n";
        s += "   <text name=\"pd\" x=\"127\" y=\"34\" w=\"40\" h=\"7\" style=\"tot\" wordWrap=\"0\">PAID</text>\n";
        s += "   <line name=\"fr\" orient=\"h\" x=\"127\" y=\"43\" length=\"24\" width=\"1.0\" cap=\"round\" color=\"000000CC\"/>\n";
        s += "  </band>\n";
        s += " </bands>\n";
        s += "</report>\n";
        return s;
    }

    static void ExportOne(IntPtr job, int target, string path)
    {
        if (LumasPdf.rptExportA(job, target, path)) Console.WriteLine("  wrote " + path);
        else Console.WriteLine("  EXPORT FAILED for " + path);
    }

    static void Main()
    {
        IntPtr pdf, eng;
        if (!BootEngine(out pdf, out eng)) return;

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string csv = Path.Combine(dir, "17_items.csv");
        File.WriteAllText(csv, CsvData());

        string xml = BuildXml().Replace("{{CSV}}", csv);
        string lrpt = Path.Combine(dir, "17_invoice.lrpt");
        File.WriteAllText(lrpt, xml);

        IntPtr job = LumasPdf.rptOpenReportA(eng, lrpt);
        if (job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(eng); goto Cleanup; }
        if (!LumasPdf.rptRender(job)) { Console.WriteLine("render failed"); DumpRptError(eng); goto CloseJob; }
        Console.WriteLine("rendered " + LumasPdf.rptGetPageCount(job) + " page(s); exporting to 7 formats:");
        ExportOne(job, LumasPdfConsts.RPT_EXP_PDF, Path.Combine(dir, "17_invoice.pdf"));
        ExportOne(job, LumasPdfConsts.RPT_EXP_HTML, Path.Combine(dir, "17_invoice.html"));
        ExportOne(job, LumasPdfConsts.RPT_EXP_SVG, Path.Combine(dir, "17_invoice.svg"));
        ExportOne(job, LumasPdfConsts.RPT_EXP_TEXT, Path.Combine(dir, "17_invoice.txt"));
        ExportOne(job, LumasPdfConsts.RPT_EXP_CSV, Path.Combine(dir, "17_invoice.csv"));
        ExportOne(job, LumasPdfConsts.RPT_EXP_XLSX, Path.Combine(dir, "17_invoice.xlsx"));
        ExportOne(job, LumasPdfConsts.RPT_EXP_XLS, Path.Combine(dir, "17_invoice.xls"));
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

//  LumasReport example 15 -- {{ }} tag language + text formatting tour (C# port)
//  Exercises every form of the v1 interpolation namespace and the text-formatting
//  knobs, then proves (by exporting to plain TEXT and grepping it) that the
//  interpolations actually resolved.
using System;
using System.IO;
using System.Text;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Ex15
{
    const string PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0";
    const string RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA";

    static string CsvData()
    {
        string s = "";
        s += "Col,Note\n";
        s += "Alpha,first\n";
        s += "Beta,second\n";
        return s;
    }

    // The report template. %CSV% is replaced with the absolute csv path at runtime.
    static string ReportTmpl()
    {
        string s = "";
        s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        s += "<report name=\"TagTour\" tagLangVersion=\"1\">\n";
        s += " <page width=\"210\" height=\"297\" marginLeft=\"12\" marginTop=\"12\" marginRight=\"12\" marginBottom=\"12\"/>\n";
        s += " <datasources>\n";
        s += "  <datasource alias=\"d\" provider=\"csv\" conn=\"%CSV%\"/>\n";
        s += " </datasources>\n";
        s += " <params>\n";
        s += "  <param name=\"Name\" default=\"(unset)\"/>\n";
        s += " </params>\n";
        s += " <bands>\n";
        s += "  <band kind=\"reportheader\" name=\"rh\" height=\"120\">\n";
        s += "   <text name=\"h\"   x=\"0\" y=\"0\"  w=\"186\" h=\"8\" fontSize=\"16\" hAlign=\"center\">Tag &amp; formatting tour</text>\n";
        s += "   <text name=\"ex\"  x=\"0\" y=\"12\" w=\"186\" h=\"6\" fontSize=\"11\">expr 2+3*4 = {{expr: 2+3*4 }}</text>\n";
        s += "   <text name=\"vr\"  x=\"0\" y=\"20\" w=\"186\" h=\"6\" fontSize=\"11\">var:Name = {{var:Name}}</text>\n";
        s += "   <text name=\"fn\"  x=\"0\" y=\"28\" w=\"186\" h=\"6\" fontSize=\"11\">FORMATNUM = {{expr: FORMATNUM('#,##0.00', 1234.5) }}</text>\n";
        s += "   <text name=\"fd\"  x=\"0\" y=\"36\" w=\"186\" h=\"6\" fontSize=\"11\">FORMATDATE = {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }}</text>\n";
        s += "   <text name=\"esc\" x=\"0\" y=\"44\" w=\"186\" h=\"6\" fontSize=\"11\">escape literal = {{{{ }}</text>\n";
        s += "   <text name=\"a0\" x=\"0\" y=\"56\" w=\"186\" h=\"6\" fontSize=\"10\" hAlign=\"0\">hAlign 0 = left</text>\n";
        s += "   <text name=\"a1\" x=\"0\" y=\"63\" w=\"186\" h=\"6\" fontSize=\"10\" hAlign=\"1\">hAlign 1 = center</text>\n";
        s += "   <text name=\"a2\" x=\"0\" y=\"70\" w=\"186\" h=\"6\" fontSize=\"10\" hAlign=\"2\">hAlign 2 = right</text>\n";
        s += "   <text name=\"a3\" x=\"0\" y=\"77\" w=\"186\" h=\"6\" fontSize=\"10\" hAlign=\"3\">hAlign 3 = justify this line so it spreads across the whole width of the box evenly</text>\n";
        s += "   <text name=\"v0\" x=\"0\"   y=\"92\" w=\"60\" h=\"20\" fontSize=\"9\" vAlign=\"0\">vAlign 0 top</text>\n";
        s += "   <text name=\"v1\" x=\"63\"  y=\"92\" w=\"60\" h=\"20\" fontSize=\"9\" vAlign=\"1\">vAlign 1 middle</text>\n";
        s += "   <text name=\"v2\" x=\"126\" y=\"92\" w=\"60\" h=\"20\" fontSize=\"9\" vAlign=\"2\">vAlign 2 bottom</text>\n";
        s += "  </band>\n";
        s += "  <band kind=\"detail\" name=\"rows\" height=\"7\" data=\"d\">\n";
        s += "   <text name=\"r\" x=\"0\" y=\"0\" w=\"186\" h=\"6\" fontSize=\"11\">row: fields.d.Col={{fields.d.Col}}  bare d.Col={{d.Col}}  note={{d.Note}}</text>\n";
        s += "  </band>\n";
        s += " </bands>\n";
        s += "</report>\n";
        return s;
    }

    static void Prove(string what, string needle, string hay)
    {
        if (hay.IndexOf(needle) >= 0)
            Console.WriteLine("  OK   " + what + " found \"" + needle + "\"");
        else
            Console.WriteLine("  MISS " + what + " expected \"" + needle + "\"");
    }

    static void Main()
    {
        IntPtr pdf, eng;
        if (!BootEngine(out pdf, out eng)) return;

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string csv = Path.Combine(dir, "15_data.csv");
        string outPdf = Path.Combine(dir, "15_tags.pdf");
        string outTxt = Path.Combine(dir, "15_tags.txt");

        File.WriteAllText(csv, CsvData());

        // Inject the absolute CSV path into the report markup.
        string xml = ReportTmpl().Replace("%CSV%", csv);

        byte[] b = Encoding.UTF8.GetBytes(xml);
        IntPtr job = IntPtr.Zero;
        GCHandle h = GCHandle.Alloc(b, GCHandleType.Pinned);
        try { job = LumasPdf.rptOpenReportMem(eng, h.AddrOfPinnedObject(), b.Length); }
        finally { h.Free(); }
        if (job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(eng); goto Cleanup; }

        // Give the {{var:Name}} parameter a distinctive value to grep for.
        LumasPdf.rptSetParamStr(job, "Name", "Ada_Lovelace");

        if (!LumasPdf.rptRender(job)) { Console.WriteLine("render failed"); DumpRptError(eng); goto CloseJob; }
        Console.WriteLine("rendered " + LumasPdf.rptGetPageCount(job) + " page(s)");

        if (!LumasPdf.rptExportA(job, LumasPdfConsts.RPT_EXP_PDF, outPdf)) { Console.WriteLine("PDF export failed"); DumpRptError(eng); goto CloseJob; }
        Console.WriteLine("wrote " + outPdf);
        if (!LumasPdf.rptExportA(job, LumasPdfConsts.RPT_EXP_TEXT, outTxt)) { Console.WriteLine("TEXT export failed"); DumpRptError(eng); goto CloseJob; }
        Console.WriteLine("wrote " + outTxt);
    CloseJob:
        LumasPdf.rptCloseReport(job);

        // --- Proof: grep the TEXT export for each resolved interpolation ------
        Console.WriteLine("== Proof (grep the TEXT export) ==");
        string txt = File.Exists(outTxt) ? File.ReadAllText(outTxt) : "";
        string isoToday = DateTime.Now.ToString("yyyy-MM-dd");

        Prove("expr 2+3*4", "= 14", txt);
        Prove("var:Name", "Ada_Lovelace", txt);
        Prove("FORMATNUM", "1,234.50", txt);
        Prove("FORMATDATE", isoToday, txt);
        Prove("escape {{}}", "{{ }}", txt);
        Prove("fields.d.Col", "Alpha", txt);
        Prove("bare d.Col", "Beta", txt);
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

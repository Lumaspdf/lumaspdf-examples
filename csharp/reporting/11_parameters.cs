//  LumasReport example 11 -- Report parameters  (C# port of 11_parameters.bas)
//  Declares <params> in the .lrpt and drives them from code at JOB level via
//  rptSetParamStr / rptSetParamNum / rptSetParamInt (AFTER rptOpenReport, BEFORE
//  rptRender). The whole report is rendered TWICE with different parameter values.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Ex11
{
    const string PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0";
    const string RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA";

    static string BuildXml()
    {
        string s = "";
        s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        s += "<report name=\"Params\" tagLangVersion=\"1\">\n";
        s += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        s += " <params>\n";
        s += "  <param name=\"Customer\" default=\"ACME (default)\"/>\n";
        s += "  <param name=\"UnitPrice\" default=\"0\"/>\n";
        s += "  <param name=\"Qty\" default=\"0\"/>\n";
        s += " </params>\n";
        s += " <bands>\n";
        s += "  <band kind=\"reportheader\" name=\"rh\" height=\"30\">\n";
        s += "   <text name=\"title\" x=\"0\" y=\"0\" w=\"180\" h=\"10\" fontSize=\"18\" hAlign=\"center\">Invoice for {{var:Customer}}</text>\n";
        s += "   <text name=\"line1\" x=\"0\" y=\"14\" w=\"180\" h=\"6\" fontSize=\"11\">Unit price: {{var:UnitPrice}}   Quantity: {{var:Qty}}</text>\n";
        s += "   <text name=\"line2\" x=\"0\" y=\"22\" w=\"180\" h=\"6\" fontSize=\"11\">TOTAL = {{expr: UnitPrice * Qty}}</text>\n";
        s += "  </band>\n";
        s += " </bands>\n";
        s += "</report>\n";
        return s;
    }

    static bool RunOnce(IntPtr eng, string lrpt, string outPdf, string outTxt, string customer, double unitPrice, long qty)
    {
        IntPtr job = LumasPdf.rptOpenReportA(eng, lrpt);
        if (job == IntPtr.Zero) { Console.WriteLine("  open failed"); DumpRptError(eng); return false; }
        try
        {
            if (!LumasPdf.rptSetParamStr(job, "Customer", customer)) { Console.WriteLine("  SetParamStr failed"); DumpRptError(eng); return false; }
            if (!LumasPdf.rptSetParamNum(job, "UnitPrice", unitPrice)) { Console.WriteLine("  SetParamNum failed"); DumpRptError(eng); return false; }
            if (!LumasPdf.rptSetParamInt(job, "Qty", qty)) { Console.WriteLine("  SetParamInt failed"); DumpRptError(eng); return false; }
            if (!LumasPdf.rptRender(job)) { Console.WriteLine("  render failed"); DumpRptError(eng); return false; }
            if (!LumasPdf.rptExportA(job, LumasPdfConsts.RPT_EXP_PDF, outPdf)) { Console.WriteLine("  export PDF failed"); DumpRptError(eng); return false; }
            if (!LumasPdf.rptExportA(job, LumasPdfConsts.RPT_EXP_TEXT, outTxt)) { Console.WriteLine("  export TEXT failed"); DumpRptError(eng); return false; }
            Console.WriteLine("  wrote " + outPdf + "  (Customer=\"" + customer + "\" UnitPrice=" + unitPrice + " Qty=" + qty + " TOTAL=" + (unitPrice * qty) + ")");
            return true;
        }
        finally { LumasPdf.rptCloseReport(job); }
    }

    static void Main()
    {
        IntPtr pdf, eng;
        if (!BootEngine(out pdf, out eng)) return;
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string lrpt = Path.Combine(dir, "11_parameters.lrpt");
        File.WriteAllText(lrpt, BuildXml());

        Console.WriteLine("Run #1:");
        if (!RunOnce(eng, lrpt, Path.Combine(dir, "11_run1.pdf"), Path.Combine(dir, "11_run1.txt"), "Globex Corporation", 12.5, 4)) goto Cleanup;

        Console.WriteLine("Run #2:");
        if (!RunOnce(eng, lrpt, Path.Combine(dir, "11_run2.pdf"), Path.Combine(dir, "11_run2.txt"), "Initech LLC", 9.99, 10)) goto Cleanup;

        Console.WriteLine("OK");
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

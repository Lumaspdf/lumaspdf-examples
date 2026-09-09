//  02_license_and_errors -- C# port of examples\Vb6\reporting\02_license_and_errors.bas
//  License info readout + deliberate error paths + a valid render.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class License02
{
    const string PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0";
    const string RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA";

    static IntPtr mPdf;
    static IntPtr mEng;

    static void WriteText(string path, string content) { File.WriteAllText(path, content); }

    static void DumpRptError(IntPtr eng)
    {
        IntPtr p = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(TRptErrorInfoC)));
        try
        {
            if (LumasPdf.rptGetLastError(eng, p))
            {
                var info = (TRptErrorInfoC)Marshal.PtrToStructure(p, typeof(TRptErrorInfoC));
                if (info.Code != 0)
                    Console.WriteLine("  ! rpt error " + info.Code + " [" + info.Module_ +
                        "] at " + info.Location + ": " + info.Msg);
            }
        }
        finally { Marshal.FreeHGlobal(p); }
    }

    static bool BootEngine()
    {
        mPdf = LumasPdf.pdfNewPDF();
        if (mPdf == IntPtr.Zero) { Console.WriteLine("pdfNewPDF failed"); return false; }
        LumasPdf.pdfSetLicenseKey(mPdf, PDF_DEMO_KEY);
        LumasPdf.rptSetRptLicenseKeyA(mPdf, RPT_DEMO_KEY);
        mEng = LumasPdf.rptCreateEngineA(mPdf, null);
        if (mEng == IntPtr.Zero) { Console.WriteLine("rptCreateEngine failed:"); DumpRptError(IntPtr.Zero); return false; }
        return true;
    }

    static string FeaturesToStr(uint f)
    {
        string r = "";
        if ((f & LumasPdfConsts.RPT_FEAT_CORE) != 0) r += "CORE ";
        if ((f & LumasPdfConsts.RPT_FEAT_EXPORT_PDF) != 0) r += "PDF ";
        if ((f & LumasPdfConsts.RPT_FEAT_EXPORT_WEB) != 0) r += "WEB ";
        if ((f & LumasPdfConsts.RPT_FEAT_EXPORT_DATA) != 0) r += "DATA ";
        if ((f & LumasPdfConsts.RPT_FEAT_PREVIEW) != 0) r += "PREVIEW ";
        if ((f & LumasPdfConsts.RPT_FEAT_PRINT) != 0) r += "PRINT ";
        if ((f & LumasPdfConsts.RPT_FEAT_PLUGINS) != 0) r += "PLUGINS ";
        return r.Trim();
    }

    static int LastErrorCode(IntPtr eng)
    {
        IntPtr p = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(TRptErrorInfoC)));
        try
        {
            if (LumasPdf.rptGetLastError(eng, p))
            {
                var info = (TRptErrorInfoC)Marshal.PtrToStructure(p, typeof(TRptErrorInfoC));
                return info.Code;
            }
            return 0;
        }
        finally { Marshal.FreeHGlobal(p); }
    }

    static void ShowError(string tag, IntPtr eng)
    {
        IntPtr p = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(TRptErrorInfoC)));
        try
        {
            bool got = LumasPdf.rptGetLastError(eng, p);
            var info = got ? (TRptErrorInfoC)Marshal.PtrToStructure(p, typeof(TRptErrorInfoC)) : default(TRptErrorInfoC);
            if (got && info.Code != 0)
                Console.WriteLine("  " + tag + " -> code " + info.Code + "  module=" + info.Module_ +
                    "  location=" + info.Location + "  msg=" + info.Msg);
            else
                Console.WriteLine("  " + tag + " -> (no structured error reported)");
        }
        finally { Marshal.FreeHGlobal(p); }
    }

    static void Main()
    {
        if (!BootEngine()) return;

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string GoodLrpt = Path.Combine(dir, "02_good.lrpt");
        string BadLrpt = Path.Combine(dir, "02_bad.lrpt");
        string OutPdf = Path.Combine(dir, "02_out.pdf");

        Console.WriteLine("== License info ==");
        IntPtr lp = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(TRptLicenseInfoC)));
        try
        {
            var li = new TRptLicenseInfoC();
            li.StructSize = Marshal.SizeOf(typeof(TRptLicenseInfoC));
            Marshal.StructureToPtr(li, lp, false);
            if (LumasPdf.rptGetLicenseInfo(mEng, lp))
            {
                var info = (TRptLicenseInfoC)Marshal.PtrToStructure(lp, typeof(TRptLicenseInfoC));
                Console.WriteLine("  Edition  : " + info.Edition);
                Console.WriteLine("  Features : $" + info.Features.ToString("X8") + " (" + FeaturesToStr(info.Features) + ")");
                Console.WriteLine("  LicClass : " + info.LicClass);
                Console.WriteLine("  LockClass: " + info.LockClass);
                if (info.Expiry == 0)
                    Console.WriteLine("  Expiry   : 0 (perpetual / unbound)");
                else
                    Console.WriteLine("  Expiry   : " + info.Expiry);
                Console.WriteLine("  Customer : " + info.Customer);
            }
            else
            {
                Console.WriteLine("  rptGetLicenseInfo failed");
                DumpRptError(mEng);
            }
        }
        finally { Marshal.FreeHGlobal(lp); }

        Console.WriteLine("== Deliberate errors ==");

        WriteText(BadLrpt, "this is not a report at all\n");
        IntPtr Job = LumasPdf.rptOpenReportA(mEng, BadLrpt);
        if (Job == IntPtr.Zero) ShowError("open(not-XML .lrpt)", mEng);
        else { Console.WriteLine("  open(not-XML .lrpt) -> unexpectedly succeeded"); LumasPdf.rptCloseReport(Job); }

        WriteText(BadLrpt, "<notreport><oops/></notreport>\n");
        Job = LumasPdf.rptOpenReportA(mEng, BadLrpt);
        if (Job == IntPtr.Zero) ShowError("open(wrong-root .lrpt)", mEng);
        else { Console.WriteLine("  open(wrong-root .lrpt) -> unexpectedly succeeded"); LumasPdf.rptCloseReport(Job); }

        int PrevCode = LastErrorCode(mEng);
        if (LumasPdf.rptRender(IntPtr.Zero))
            Console.WriteLine("  rptRender(nil) -> unexpectedly succeeded");
        else if (LastErrorCode(mEng) == PrevCode)
            Console.WriteLine("  rptRender(nil) -> returned False; no new engine error (last code still " + PrevCode + ")");
        else
            ShowError("rptRender(nil)", mEng);

        PrevCode = LastErrorCode(mEng);
        if (LumasPdf.rptExportA(IntPtr.Zero, LumasPdfConsts.RPT_EXP_PDF, OutPdf))
            Console.WriteLine("  rptExportA(nil) -> unexpectedly succeeded");
        else if (LastErrorCode(mEng) == PrevCode)
            Console.WriteLine("  rptExportA(nil) -> returned False; no new engine error (last code still " + PrevCode + ")");
        else
            ShowError("rptExportA(nil)", mEng);

        Console.WriteLine("== Valid render ==");
        string Xml = "";
        Xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        Xml += "<report name=\"LicDemo\" tagLangVersion=\"1\">\n";
        Xml += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        Xml += " <bands>\n";
        Xml += "  <band kind=\"reportheader\" name=\"rh\" height=\"16\">\n";
        Xml += "   <text name=\"t\" x=\"0\" y=\"0\" w=\"180\" h=\"10\" fontSize=\"18\" hAlign=\"center\">License &amp; error demo</text>\n";
        Xml += "  </band>\n";
        Xml += " </bands>\n";
        Xml += "</report>\n";
        WriteText(GoodLrpt, Xml);
        Job = LumasPdf.rptOpenReportA(mEng, GoodLrpt);
        if (Job == IntPtr.Zero) { Console.WriteLine("  open failed"); DumpRptError(mEng); goto Cleanup; }
        if (!LumasPdf.rptRender(Job)) { Console.WriteLine("  render failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        Console.WriteLine("  rendered " + LumasPdf.rptGetPageCount(Job) + " page(s)");
        if (!LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf)) { Console.WriteLine("  export failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        Console.WriteLine("  wrote " + OutPdf);
        LumasPdf.rptCloseReport(Job);
    Cleanup:
        LumasPdf.rptDeleteEngine(mEng);
        LumasPdf.pdfDeletePDF(mPdf);
    }
}

//  LumasReport example 13 -- Custom function + custom exporter, NO plugin DLL (C# port)
//  Instead of loading rpt_testplugin.dll via rptLoadPlugin, this registers the
//  very same PlugDouble(x)=x*2 expression function AND a custom export target
//  directly on the engine through native-callback delegates:
//     rptRegisterFunction(eng, "PlugDouble", 1, 1, fnPtr, 0)   // {{expr: PlugDouble(21)}}
//     rptRegisterExporter (eng, 100, expPtr, 0)                // rptExport(job, 100, path)
//  Both callbacks use the engine's stdcall C ABI. The delegates are kept alive in
//  static fields so the GC cannot collect the thunks. No external plugin DLL is used.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Ex13
{
    const string PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0";
    const string RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA";

    // TRptCValue ordinals and field offsets: Kind@0, B@4, I@8, F@16, S@24.
    const int VK_INT = 2;
    const int VK_FLOAT = 3;
    const int OFF_I = 8;
    const int OFF_F = 16;
    // Custom export target id (must be >= 100).
    const int TARGET_CUSTOM = 100;
    const string EXPORT_MARKER =
        "PLUGIN:OK -- custom exporter via rptRegisterExporter (no external plugin DLL)";

    // stdcall callback ABIs. Args/ResultV are PRptCValue; Job/Path are opaque + PAnsiChar.
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int TRptUserFn(IntPtr User, IntPtr Args, int NArgs, IntPtr ResultV);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int TRptExporterFn(IntPtr User, IntPtr Job, IntPtr Path);

    // Keep the delegates alive so the GC does not collect the marshalled thunks.
    static TRptUserFn _plugDoubleCb = PlugDouble;
    static TRptExporterFn _plugExportCb = PlugExport;

    // PlugDouble(x) -> x*2, preserving the numeric kind (int stays int, float stays float).
    static int PlugDouble(IntPtr user, IntPtr args, int nArgs, IntPtr resultV)
    {
        if (nArgs != 1 || args == IntPtr.Zero || resultV == IntPtr.Zero) return -1;
        int kind = Marshal.ReadInt32(args, 0);
        if (kind == VK_INT)
        {
            long v = Marshal.ReadInt64(args, OFF_I);
            Marshal.WriteInt32(resultV, 0, VK_INT);
            Marshal.WriteInt64(resultV, OFF_I, v * 2);
        }
        else if (kind == VK_FLOAT)
        {
            double f = BitConverter.Int64BitsToDouble(Marshal.ReadInt64(args, OFF_F));
            Marshal.WriteInt32(resultV, 0, VK_FLOAT);
            Marshal.WriteInt64(resultV, OFF_F, BitConverter.DoubleToInt64Bits(f * 2.0));
        }
        else return -2;
        return 0;
    }

    // Custom exporter for target id 100: write a marker file to the requested path.
    static int PlugExport(IntPtr user, IntPtr job, IntPtr path)
    {
        string p = Marshal.PtrToStringAnsi(path);
        if (string.IsNullOrEmpty(p)) return -1;
        try { File.WriteAllText(p, EXPORT_MARKER); } catch { return -2; }
        return 0;
    }

    static string BuildXml()
    {
        string s = "";
        s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        s += "<report name=\"Plugin\" tagLangVersion=\"1\">\n";
        s += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        s += " <bands>\n";
        s += "  <band kind=\"reportheader\" name=\"rh\" height=\"24\">\n";
        s += "   <text name=\"p1\" x=\"0\" y=\"0\"  w=\"180\" h=\"8\" fontSize=\"16\">PlugDouble(21) = {{expr: PlugDouble(21) }}</text>\n";
        s += "   <text name=\"p2\" x=\"0\" y=\"10\" w=\"180\" h=\"8\" fontSize=\"12\">PlugDouble(2.5) = {{expr: PlugDouble(2.5) }}</text>\n";
        s += "  </band>\n";
        s += " </bands>\n";
        s += "</report>\n";
        return s;
    }

    static void Main()
    {
        IntPtr pdf, eng;
        if (!BootEngine(out pdf, out eng)) return;

        // Register BEFORE opening the report so the compiler resolves PlugDouble and
        // knows about the custom export target.
        IntPtr fnPtr = Marshal.GetFunctionPointerForDelegate(_plugDoubleCb);
        if (!LumasPdf.rptRegisterFunction(eng, "PlugDouble", 1, 1, fnPtr, IntPtr.Zero))
        {
            Console.WriteLine("rptRegisterFunction failed"); DumpRptError(eng); goto Cleanup;
        }
        IntPtr expPtr = Marshal.GetFunctionPointerForDelegate(_plugExportCb);
        if (!LumasPdf.rptRegisterExporter(eng, TARGET_CUSTOM, expPtr, IntPtr.Zero))
        {
            Console.WriteLine("rptRegisterExporter failed"); DumpRptError(eng); goto Cleanup;
        }
        Console.WriteLine("registered custom function PlugDouble/1 (x -> x*2)");
        Console.WriteLine("registered custom export target " + TARGET_CUSTOM + " (no external plugin DLL)");

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string lrpt = Path.Combine(dir, "13_plugin.lrpt");
        string outPdf = Path.Combine(dir, "13_plugin.pdf");
        string outTxt = Path.Combine(dir, "13_plugin.txt");
        string outCustom = Path.Combine(dir, "13_custom.out");
        File.WriteAllText(lrpt, BuildXml());

        IntPtr job = LumasPdf.rptOpenReportA(eng, lrpt);
        if (job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(eng); goto Cleanup; }
        if (!LumasPdf.rptRender(job)) { Console.WriteLine("render failed"); DumpRptError(eng); goto CloseJob; }
        if (!LumasPdf.rptExportA(job, LumasPdfConsts.RPT_EXP_PDF, outPdf)) { Console.WriteLine("export PDF failed"); DumpRptError(eng); goto CloseJob; }
        if (!LumasPdf.rptExportA(job, LumasPdfConsts.RPT_EXP_TEXT, outTxt)) { Console.WriteLine("export TEXT failed"); DumpRptError(eng); goto CloseJob; }
        if (!LumasPdf.rptExportA(job, TARGET_CUSTOM, outCustom)) { Console.WriteLine("export CUSTOM failed"); DumpRptError(eng); goto CloseJob; }
        Console.WriteLine("wrote " + outPdf);
        Console.WriteLine("wrote " + outCustom + " (via custom exporter)");
        Console.WriteLine("OK");
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

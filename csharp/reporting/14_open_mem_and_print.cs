//  LumasReport example 14 -- In-memory open + headless print (C# port)
//    1. The .lrpt need not live on disk: the markup is built in code and handed
//       straight to the engine with rptOpenReportMem(Eng, ptr, len).
//    2. A report can be sent to a physical printer headless via rptPrintA. We
//       drive "Microsoft Print to PDF" with an absolute OutputFile (no dialog).
//       If the printer is not installed the call fails softly.
//  Exports covered: rptOpenReportMem, rptRender, rptGetPageCount, rptExportA,
//                   rptPrintA (+ rptPreviewA documented, never called).
using System;
using System.IO;
using System.Text;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Ex14
{
    const string PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0";
    const string RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA";

    static string BuildXml()
    {
        string s = "";
        s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        s += "<report name=\"InMem\" tagLangVersion=\"1\">\n";
        s += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        s += " <bands>\n";
        s += "  <band kind=\"reportheader\" name=\"rh\" height=\"24\">\n";
        s += "   <text name=\"title\" x=\"0\" y=\"0\"  w=\"180\" h=\"12\" fontSize=\"20\" hAlign=\"center\">In-memory report</text>\n";
        s += "   <text name=\"sub\"   x=\"0\" y=\"14\" w=\"180\" h=\"6\"  fontSize=\"10\" hAlign=\"center\">Opened with rptOpenReportMem -- no file on disk.</text>\n";
        s += "  </band>\n";
        s += "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n";
        s += "   <text name=\"ph1\" x=\"0\" y=\"0\" w=\"180\" h=\"6\" fontSize=\"9\" hAlign=\"left\">LumasReport example 14</text>\n";
        s += "  </band>\n";
        s += "  <band kind=\"detail\" name=\"det\" height=\"8\">\n";
        s += "   <text name=\"d1\" x=\"0\" y=\"0\" w=\"180\" h=\"6\" fontSize=\"11\" hAlign=\"left\">This band was rendered from bytes handed to the engine directly.</text>\n";
        s += "  </band>\n";
        s += "  <band kind=\"pagefooter\" name=\"pf\" height=\"8\">\n";
        s += "   <text name=\"pf1\" x=\"0\" y=\"0\" w=\"180\" h=\"6\" fontSize=\"8\" hAlign=\"right\">page {{var:PageNo}} of {{var:TotalPages}}</text>\n";
        s += "  </band>\n";
        s += " </bands>\n";
        s += "</report>\n";
        return s;
    }

    static void Main()
    {
        IntPtr pdf, eng;
        if (!BootEngine(out pdf, out eng)) return;

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string outPdf = Path.Combine(dir, "14_open_mem.pdf");
        string outPrint = Path.Combine(dir, "14_printed.pdf");

        // --- 1. Open straight from memory (no temp file) ----------------------
        Console.WriteLine("== Open from memory ==");
        byte[] b = Encoding.UTF8.GetBytes(BuildXml());
        int nBytes = b.Length;
        Console.WriteLine("  blob is " + nBytes + " bytes");

        int pages = 0;
        IntPtr job = IntPtr.Zero;
        GCHandle h = GCHandle.Alloc(b, GCHandleType.Pinned);
        try
        {
            job = LumasPdf.rptOpenReportMem(eng, h.AddrOfPinnedObject(), nBytes);
        }
        finally { h.Free(); }
        if (job == IntPtr.Zero) { Console.WriteLine("  rptOpenReportMem failed"); DumpRptError(eng); goto Cleanup; }

        if (!LumasPdf.rptRender(job)) { Console.WriteLine("  render failed"); DumpRptError(eng); goto CloseJob; }
        pages = LumasPdf.rptGetPageCount(job);
        Console.WriteLine("  rendered " + pages + " page(s) from the in-memory report");

        // --- 2a. Export the in-memory report to a PDF -------------------------
        Console.WriteLine("== Export ==");
        if (!LumasPdf.rptExportA(job, LumasPdfConsts.RPT_EXP_PDF, outPdf)) { Console.WriteLine("  export failed"); DumpRptError(eng); goto CloseJob; }
        Console.WriteLine("  wrote " + outPdf);

        // --- 2b. Headless print via "Microsoft Print to PDF" ------------------
        Console.WriteLine("== Headless print ==");
        if (LumasPdf.rptPrintA(job, "Microsoft Print to PDF", outPrint))
            Console.WriteLine("  \"Microsoft Print to PDF\" -> " + outPrint);
        else
        {
            Console.WriteLine("  \"Microsoft Print to PDF\" not available / print failed (continuing -- not fatal):");
            DumpRptError(eng);
        }

        // --- 2c. Preview (documented, deliberately NOT called) ----------------
        //  rptPreviewA(job, "In-memory report") would pop the built-in modal viewer.
    CloseJob:
        LumasPdf.rptCloseReport(job);

        // --- 3. Verify the in-memory PDF is real ------------------------------
        Console.WriteLine("== Verify ==");
        if (File.Exists(outPdf) && pages >= 1)
            Console.WriteLine("  OK: " + outPdf + " exists, report has " + pages + " page(s)");
        else
            Console.WriteLine("  VERIFY FAILED: in-memory PDF missing or zero pages");
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

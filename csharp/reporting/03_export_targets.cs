//  03_export_targets -- C# port of examples\Vb6\reporting\03_export_targets.bas
//  Render one report, export to all 10 targets (pdf/html/csv/json/xml/txt/svg/xlsx/png/bmp).
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Export03
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
                    Console.WriteLine("  ! rpt error " + info.Code + " [" + info.Module_ + "] at " + info.Location + ": " + info.Msg);
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

    static long FileSizeOf(string path)
    {
        try { return new FileInfo(path).Length; } catch { return -1; }
    }

    static void Main()
    {
        int[] Targets = new int[] {
            LumasPdfConsts.RPT_EXP_PDF, LumasPdfConsts.RPT_EXP_HTML, LumasPdfConsts.RPT_EXP_CSV,
            LumasPdfConsts.RPT_EXP_JSON, LumasPdfConsts.RPT_EXP_XML, LumasPdfConsts.RPT_EXP_TEXT,
            LumasPdfConsts.RPT_EXP_SVG, LumasPdfConsts.RPT_EXP_XLSX, LumasPdfConsts.RPT_EXP_PNG,
            LumasPdfConsts.RPT_EXP_BMP };
        string[] Exts = new string[] { "pdf", "html", "csv", "json", "xml", "txt", "svg", "xlsx", "png", "bmp" };

        if (!BootEngine()) return;

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string Csv = Path.Combine(dir, "03_data.csv");
        string Lrpt = Path.Combine(dir, "03_report.lrpt");

        string CsvData = "";
        CsvData += "product,qty,price\n";
        CsvData += "Widget,4,9.95\n";
        CsvData += "Gadget,2,19.50\n";
        CsvData += "Sprocket,7,3.25\n";
        WriteText(Csv, CsvData);

        string Xml = "";
        Xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        Xml += "<report name=\"ExportDemo\" tagLangVersion=\"1\">\n";
        Xml += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        Xml += " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"" + Csv + "\"/></datasources>\n";
        Xml += " <bands>\n";
        Xml += "  <band kind=\"reportheader\" name=\"rh\" height=\"14\">\n";
        Xml += "   <text name=\"ttl\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\">Order Lines</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"detail\" name=\"det\" height=\"7\" data=\"d\">\n";
        Xml += "   <text name=\"p\" x=\"0\"   y=\"0\" w=\"90\" h=\"6\" fontSize=\"10\" wordWrap=\"0\">{{d.product}}</text>\n";
        Xml += "   <text name=\"q\" x=\"90\"  y=\"0\" w=\"30\" h=\"6\" fontSize=\"10\" hAlign=\"right\" wordWrap=\"0\">{{d.qty}}</text>\n";
        Xml += "   <text name=\"r\" x=\"120\" y=\"0\" w=\"60\" h=\"6\" fontSize=\"10\" hAlign=\"right\" wordWrap=\"0\">{{d.price}}</text>\n";
        Xml += "  </band>\n";
        Xml += " </bands>\n";
        Xml += "</report>\n";
        WriteText(Lrpt, Xml);

        IntPtr Job = LumasPdf.rptOpenReportA(mEng, Lrpt);
        if (Job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(mEng); goto Cleanup; }
        if (!LumasPdf.rptRender(Job)) { Console.WriteLine("render failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        Console.WriteLine("rendered " + LumasPdf.rptGetPageCount(Job) + " page(s)");
        Console.WriteLine("== Exporting to all targets ==");
        for (int i = 0; i <= 9; i++)
        {
            string OutFile = Path.Combine(dir, "03_out." + Exts[i]);
            if (LumasPdf.rptExportA(Job, Targets[i], OutFile) && File.Exists(OutFile))
                Console.WriteLine("  [" + Exts[i] + "] id=" + Targets[i] + "  OK  " + FileSizeOf(OutFile) + " bytes");
            else
            {
                Console.WriteLine("  [" + Exts[i] + "] id=" + Targets[i] + "  FAILED");
                DumpRptError(mEng);
            }
        }
        LumasPdf.rptCloseReport(Job);
    Cleanup:
        LumasPdf.rptDeleteEngine(mEng);
        LumasPdf.pdfDeletePDF(mPdf);
    }
}

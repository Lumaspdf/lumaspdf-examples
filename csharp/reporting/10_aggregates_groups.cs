//  10_aggregates_groups -- C# port of examples\Vb6\reporting\10_aggregates_groups.bas
//  Grouped catalog with per-group SUM/COUNT/AVG/MIN/MAX + grand totals.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Aggregates10
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

    static void Main()
    {
        if (!BootEngine()) return;

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string Csv = Path.Combine(dir, "10_data.csv");
        string Lrpt = Path.Combine(dir, "10_groups.lrpt");
        string OutPdf = Path.Combine(dir, "10_groups.pdf");
        string OutTxt = Path.Combine(dir, "10_groups.txt");

        string CsvData = "";
        CsvData += "Cat,Item,Amount\n";
        CsvData += "Fruit,Apple,10\n";
        CsvData += "Fruit,Pear,7\n";
        CsvData += "Fruit,Plum,5\n";
        CsvData += "Dairy,Milk,4\n";
        CsvData += "Dairy,Cheese,9\n";
        CsvData += "Dairy,Butter,6\n";
        CsvData += "Grain,Bread,3\n";
        CsvData += "Grain,Rice,8\n";
        CsvData += "Grain,Oats,2\n";
        WriteText(Csv, CsvData);

        string Xml = "";
        Xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        Xml += "<report name=\"Groups\" tagLangVersion=\"1\">\n";
        Xml += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        Xml += " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"" + Csv + "\"/></datasources>\n";
        Xml += " <bands>\n";
        Xml += "  <band kind=\"reportheader\" name=\"rh\" height=\"10\"><text name=\"t\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\" wordWrap=\"0\">Grouped Catalog</text></band>\n";
        Xml += "  <band kind=\"groupheader\" name=\"gh\" group=\"d.Cat\" height=\"7\"><text name=\"g\" x=\"0\" y=\"1\" w=\"180\" h=\"5\" fontSize=\"12\" bold=\"1\" wordWrap=\"0\">Category: {{expr: d.Cat}}</text></band>\n";
        Xml += "  <band kind=\"detail\" name=\"det\" height=\"5\" data=\"d\"><text name=\"i\" x=\"6\" y=\"0\" w=\"110\" h=\"4\" fontSize=\"9\" wordWrap=\"0\">{{Item}}</text><text name=\"a\" x=\"118\" y=\"0\" w=\"26\" h=\"4\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{Amount}}</text><text name=\"r\" x=\"148\" y=\"0\" w=\"30\" h=\"4\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">[{{expr: SUM(Amount)}}]</text></band>\n";
        Xml += "  <band kind=\"groupfooter\" name=\"gf\" group=\"d.Cat\" height=\"6\"><text name=\"gt\" x=\"4\" y=\"0\" w=\"176\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">{{expr: d.Cat}} total = {{expr: SUM(Amount)}}  (n={{expr: COUNT(Amount)}}, avg={{expr: ROUND(AVG(Amount),2)}}, min={{expr: MIN(Amount)}}, max={{expr: MAX(Amount)}})</text></band>\n";
        Xml += "  <band kind=\"summary\" name=\"sm\" height=\"8\"><text name=\"s\" x=\"4\" y=\"1\" w=\"176\" h=\"6\" fontSize=\"11\" bold=\"1\" wordWrap=\"0\">GRAND TOTAL = {{expr: SUM(Amount)}}   (items={{expr: COUNT()}}, categories={{expr: COUNTDISTINCT(Cat)}})</text></band>\n";
        Xml += " </bands>\n";
        Xml += "</report>\n";
        WriteText(Lrpt, Xml);

        IntPtr Job = LumasPdf.rptOpenReportA(mEng, Lrpt);
        if (Job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(mEng); goto Cleanup; }
        if (!LumasPdf.rptRender(Job)) { Console.WriteLine("render failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        Console.WriteLine("rendered " + LumasPdf.rptGetPageCount(Job) + " page(s), grouped by Cat with per-group + grand totals");
        LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf);
        LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt);
        Console.WriteLine("wrote " + OutPdf + "  +  " + OutTxt);
        LumasPdf.rptCloseReport(Job);
    Cleanup:
        LumasPdf.rptDeleteEngine(mEng);
        LumasPdf.pdfDeletePDF(mPdf);
    }
}

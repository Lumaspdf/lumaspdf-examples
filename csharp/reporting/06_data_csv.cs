//  06_data_csv -- C# port of examples\Vb6\reporting\06_data_csv.bas
//  CSV datasource -> PDF + CSV + text exports.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class DataCsv06
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
        string Lrpt = Path.Combine(dir, "06_data.lrpt");
        string Csv = Path.Combine(dir, "06_data.csv");
        string OutPdf = Path.Combine(dir, "06_data.pdf");
        string OutCsv = Path.Combine(dir, "06_data_out.csv");
        string OutTxt = Path.Combine(dir, "06_data.txt");

        string CsvData = "";
        CsvData += "Region,Product,Qty,Price\n";
        CsvData += "North,Widget,10,2.50\n";
        CsvData += "North,Gadget,4,9.99\n";
        CsvData += "South,Widget,7,2.50\n";
        CsvData += "South,Sprocket,20,1.25\n";
        CsvData += "East,Gadget,3,9.99\n";
        CsvData += "West,Sprocket,15,1.25\n";
        WriteText(Csv, CsvData);

        string Xml = "";
        Xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        Xml += "<report name=\"CsvSales\" tagLangVersion=\"1\">\n";
        Xml += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        Xml += " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"" + Csv + "\"/></datasources>\n";
        Xml += " <bands>\n";
        Xml += "  <band kind=\"reportheader\" name=\"rh\" height=\"12\">\n";
        Xml += "   <text name=\"ttl\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\">Sales by Region</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n";
        Xml += "   <text name=\"h1\" x=\"0\"   y=\"0\" w=\"50\" h=\"6\" fontSize=\"9\" style=\"\">REGION</text>\n";
        Xml += "   <text name=\"h2\" x=\"50\"  y=\"0\" w=\"60\" h=\"6\" fontSize=\"9\">PRODUCT</text>\n";
        Xml += "   <text name=\"h3\" x=\"110\" y=\"0\" w=\"30\" h=\"6\" fontSize=\"9\" hAlign=\"right\">QTY</text>\n";
        Xml += "   <text name=\"h4\" x=\"140\" y=\"0\" w=\"40\" h=\"6\" fontSize=\"9\" hAlign=\"right\">PRICE</text>\n";
        Xml += "   <line name=\"hl\" x=\"0\" y=\"7\" w=\"180\" h=\"0.3\" toX=\"180\" toY=\"0\"/>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n";
        Xml += "   <text name=\"c1\" x=\"0\"   y=\"0\" w=\"50\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{d.Region}}</text>\n";
        Xml += "   <text name=\"c2\" x=\"50\"  y=\"0\" w=\"60\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{d.Product}}</text>\n";
        Xml += "   <text name=\"c3\" x=\"110\" y=\"0\" w=\"30\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{d.Qty}}</text>\n";
        Xml += "   <text name=\"c4\" x=\"140\" y=\"0\" w=\"40\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{d.Price}}</text>\n";
        Xml += "  </band>\n";
        Xml += " </bands>\n";
        Xml += "</report>\n";
        WriteText(Lrpt, Xml);

        IntPtr Job = LumasPdf.rptOpenReportA(mEng, Lrpt);
        if (Job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(mEng); goto Cleanup; }
        if (!LumasPdf.rptRender(Job)) { Console.WriteLine("render failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        Console.WriteLine("rendered " + LumasPdf.rptGetPageCount(Job) + " page(s)");
        if (!LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf)) { Console.WriteLine("pdf export failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        if (!LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_CSV, OutCsv)) { Console.WriteLine("csv export failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        if (!LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt)) { Console.WriteLine("text export failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        Console.WriteLine("wrote " + OutPdf);
        Console.WriteLine("wrote " + OutCsv);
        Console.WriteLine("wrote " + OutTxt);
        LumasPdf.rptCloseReport(Job);
    Cleanup:
        LumasPdf.rptDeleteEngine(mEng);
        LumasPdf.pdfDeletePDF(mPdf);
    }
}

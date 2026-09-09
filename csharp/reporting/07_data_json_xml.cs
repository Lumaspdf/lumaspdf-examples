//  07_data_json_xml -- C# port of examples\Vb6\reporting\07_data_json_xml.bas
//  JSON and XML datasources, each rendered to PDF + text.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class DataJsonXml07
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

    static bool RunReport(string tag, string xml)
    {
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string Lrpt = Path.Combine(dir, "07_" + tag + ".lrpt");
        string OutPdf = Path.Combine(dir, "07_" + tag + ".pdf");
        string OutTxt = Path.Combine(dir, "07_" + tag + ".txt");
        WriteText(Lrpt, xml);
        IntPtr Job = LumasPdf.rptOpenReportA(mEng, Lrpt);
        if (Job == IntPtr.Zero) { Console.WriteLine(tag + ": open failed"); DumpRptError(mEng); return false; }
        if (!LumasPdf.rptRender(Job)) { Console.WriteLine(tag + ": render failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); return false; }
        Console.WriteLine(tag + ": rendered " + LumasPdf.rptGetPageCount(Job) + " page(s)");
        if (!LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf)) { Console.WriteLine(tag + ": pdf export failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); return false; }
        if (!LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt)) { Console.WriteLine(tag + ": text export failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); return false; }
        Console.WriteLine("wrote " + OutPdf + " + " + OutTxt);
        LumasPdf.rptCloseReport(Job);
        return true;
    }

    static void Main()
    {
        if (!BootEngine()) return;

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string Jsn = Path.Combine(dir, "07_data.json");
        string Xm = Path.Combine(dir, "07_data.xml");

        string JsonData = "[{\"City\":\"Paris\",\"Country\":\"FR\",\"Pop\":2100},{\"City\":\"Lyon\",\"Country\":\"FR\",\"Pop\":515},{\"City\":\"Nice\",\"Country\":\"FR\",\"Pop\":340}]";
        WriteText(Jsn, JsonData);

        string XmlData = "";
        XmlData += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        XmlData += "<rows>\n";
        XmlData += " <row City=\"Berlin\" Country=\"DE\" Pop=\"3600\"/>\n";
        XmlData += " <row City=\"Munich\" Country=\"DE\" Pop=\"1500\"/>\n";
        XmlData += " <row City=\"Hamburg\" Country=\"DE\" Pop=\"1900\"/>\n";
        XmlData += "</rows>\n";
        WriteText(Xm, XmlData);

        string Xml = "";
        Xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        Xml += "<report name=\"JsonCities\" tagLangVersion=\"1\">\n";
        Xml += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        Xml += " <datasources><datasource alias=\"j\" provider=\"json\" conn=\"" + Jsn + "\" query=\"\"/></datasources>\n";
        Xml += " <bands>\n";
        Xml += "  <band kind=\"reportheader\" name=\"rh\" height=\"10\">\n";
        Xml += "   <text name=\"ttl\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\">Cities (JSON source)</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"detail\" name=\"jd\" height=\"6\" data=\"j\">\n";
        Xml += "   <text name=\"c1\" x=\"0\"  y=\"0\" w=\"60\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{j.City}}</text>\n";
        Xml += "   <text name=\"c2\" x=\"60\" y=\"0\" w=\"30\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{j.Country}}</text>\n";
        Xml += "   <text name=\"c3\" x=\"90\" y=\"0\" w=\"40\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{j.Pop}}</text>\n";
        Xml += "  </band>\n";
        Xml += " </bands>\n";
        Xml += "</report>\n";
        if (!RunReport("json", Xml)) goto Cleanup;

        Xml = "";
        Xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        Xml += "<report name=\"XmlCities\" tagLangVersion=\"1\">\n";
        Xml += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        Xml += " <datasources><datasource alias=\"x\" provider=\"xml\" conn=\"" + Xm + "\" query=\"rows/row\"/></datasources>\n";
        Xml += " <bands>\n";
        Xml += "  <band kind=\"reportheader\" name=\"rh\" height=\"10\">\n";
        Xml += "   <text name=\"ttl\" x=\"0\" y=\"0\" w=\"180\" h=\"8\" fontSize=\"16\" hAlign=\"center\">Cities (XML source)</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"detail\" name=\"xd\" height=\"6\" data=\"x\">\n";
        Xml += "   <text name=\"c1\" x=\"0\"  y=\"0\" w=\"60\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{x.City}}</text>\n";
        Xml += "   <text name=\"c2\" x=\"60\" y=\"0\" w=\"30\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{x.Country}}</text>\n";
        Xml += "   <text name=\"c3\" x=\"90\" y=\"0\" w=\"40\" h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{x.Pop}}</text>\n";
        Xml += "  </band>\n";
        Xml += " </bands>\n";
        Xml += "</report>\n";
        if (!RunReport("xml", Xml)) goto Cleanup;
    Cleanup:
        LumasPdf.rptDeleteEngine(mEng);
        LumasPdf.pdfDeletePDF(mPdf);
    }
}

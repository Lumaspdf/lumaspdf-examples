//  04_bands -- C# port of examples\Vb6\reporting\04_bands.bas
//  All band kinds + styles + grouping over a 90-row CSV; expects >= 2 pages.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Bands04
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

    static string BuildCsv()
    {
        string sb = "grp,item,val\n";
        for (int g = 1; g <= 3; g++)
            for (int r = 1; r <= 30; r++)
                sb += "Group-" + g + ",Item " + g + "-" + r.ToString("00") + "," + (g * 100 + r) + "\n";
        return sb;
    }

    static void Main()
    {
        if (!BootEngine()) return;

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string Csv = Path.Combine(dir, "04_data.csv");
        string Lrpt = Path.Combine(dir, "04_report.lrpt");
        string OutPdf = Path.Combine(dir, "04_out.pdf");
        WriteText(Csv, BuildCsv());

        string Xml = "";
        Xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        Xml += "<report name=\"BandsDemo\" tagLangVersion=\"1\">\n";
        Xml += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        Xml += " <datasources><datasource alias=\"d\" provider=\"csv\" conn=\"" + Csv + "\"/></datasources>\n";
        Xml += " <styles>\n";
        Xml += "  <style name=\"Wm\"  fontSize=\"48\" bold=\"1\" textColor=\"00EEEEEE\" hAlign=\"1\" vAlign=\"1\"/>\n";
        Xml += "  <style name=\"Ov\"  fontSize=\"8\"  textColor=\"00B0B0B0\" hAlign=\"2\"/>\n";
        Xml += "  <style name=\"Grp\" fontSize=\"12\" bold=\"1\" textColor=\"00FFFFFF\" backColor=\"002A6099\" vAlign=\"1\"/>\n";
        Xml += " </styles>\n";
        Xml += " <bands>\n";
        Xml += "  <band kind=\"background\" name=\"bg\" height=\"297\">\n";
        Xml += "   <text name=\"wm\" x=\"20\" y=\"120\" w=\"150\" h=\"40\" style=\"Wm\" rotation=\"45\" wordWrap=\"0\">BACKGROUND</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"overlay\" name=\"ov\" height=\"297\">\n";
        Xml += "   <text name=\"ol\" x=\"0\" y=\"150\" w=\"180\" h=\"6\" style=\"Ov\" rotation=\"90\" wordWrap=\"0\">overlay band</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"reportheader\" name=\"rh\" height=\"16\">\n";
        Xml += "   <text name=\"rt\" x=\"0\" y=\"0\" w=\"180\" h=\"10\" fontSize=\"18\" hAlign=\"center\">reportheader band</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n";
        Xml += "   <text name=\"pt\" x=\"0\" y=\"0\" w=\"180\" h=\"6\" fontSize=\"9\" wordWrap=\"0\">pageheader band - grp / item / val</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"groupheader\" name=\"gh\" group=\"d.grp\" height=\"8\">\n";
        Xml += "   <text name=\"gt\" x=\"0\" y=\"0\" w=\"180\" h=\"7\" style=\"Grp\" wordWrap=\"0\">groupheader band: {{d.grp}}</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n";
        Xml += "   <text name=\"di\" x=\"4\"   y=\"0\" w=\"120\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">detail band: {{d.item}}</text>\n";
        Xml += "   <text name=\"dv\" x=\"130\" y=\"0\" w=\"46\"  h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{d.val}}</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"groupfooter\" name=\"gf\" group=\"d.grp\" height=\"7\">\n";
        Xml += "   <text name=\"ft\" x=\"0\" y=\"1\" w=\"180\" h=\"5\" fontSize=\"9\" italic=\"1\" wordWrap=\"0\">groupfooter band: end of {{d.grp}}</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"pagefooter\" name=\"pf\" height=\"7\">\n";
        Xml += "   <text name=\"pft\" x=\"0\" y=\"1\" w=\"180\" h=\"5\" fontSize=\"8\" hAlign=\"center\" wordWrap=\"0\">pagefooter band</text>\n";
        Xml += "  </band>\n";
        Xml += "  <band kind=\"summary\" name=\"sm\" height=\"16\">\n";
        Xml += "   <text name=\"st\" x=\"0\" y=\"2\" w=\"180\" h=\"10\" fontSize=\"14\" hAlign=\"center\">summary band - report complete</text>\n";
        Xml += "  </band>\n";
        Xml += " </bands>\n";
        Xml += "</report>\n";
        WriteText(Lrpt, Xml);

        IntPtr Job = LumasPdf.rptOpenReportA(mEng, Lrpt);
        if (Job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(mEng); goto Cleanup; }
        if (!LumasPdf.rptRender(Job)) { Console.WriteLine("render failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        int Pages = LumasPdf.rptGetPageCount(Job);
        Console.WriteLine("rendered " + Pages + " page(s)");
        if (!LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf)) { Console.WriteLine("export failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        Console.WriteLine("wrote " + OutPdf);
        if (Pages < 2)
            Console.WriteLine("FAIL: expected >= 2 pages, got " + Pages);
        else
            Console.WriteLine("OK: multi-page grouped report with all band kinds");
        LumasPdf.rptCloseReport(Job);
    Cleanup:
        LumasPdf.rptDeleteEngine(mEng);
        LumasPdf.pdfDeletePDF(mPdf);
    }
}

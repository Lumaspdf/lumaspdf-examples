//  05_elements -- C# port of examples\Vb6\reporting\05_elements.bas
//  Every element kind: text / line / shape / image / barcode / subreport.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Elements05
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

    static void WriteBmp8x8(string path)
    {
        using (var ms = new MemoryStream())
        using (var w = new BinaryWriter(ms))
        {
            // BITMAPFILEHEADER
            w.Write((byte)'B'); w.Write((byte)'M');
            w.Write((int)(54 + 192));
            w.Write((int)0);
            w.Write((int)54);
            // BITMAPINFOHEADER
            w.Write((int)40);
            w.Write((int)8); w.Write((int)8);
            w.Write((short)1);
            w.Write((short)24);
            w.Write((int)0);
            w.Write((int)192);
            w.Write((int)2835); w.Write((int)2835);
            w.Write((int)0); w.Write((int)0);
            // pixels bottom-up BGR
            for (int y = 0; y <= 7; y++)
                for (int x = 0; x <= 7; x++)
                    if (((x + y) & 1) == 0) { w.Write((byte)0); w.Write((byte)0); w.Write((byte)255); }
                    else { w.Write((byte)255); w.Write((byte)0); w.Write((byte)0); }
            w.Flush();
            File.WriteAllBytes(path, ms.ToArray());
        }
    }

    static void Main()
    {
        if (!BootEngine()) return;

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string Lrpt = Path.Combine(dir, "05_elements.lrpt");
        string Sub_ = Path.Combine(dir, "05_sub.lrpt");
        string Img = Path.Combine(dir, "05_img.bmp");
        string OutPdf = Path.Combine(dir, "05_elements.pdf");

        string Xml = "";
        Xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        Xml += "<report name=\"Sub\" tagLangVersion=\"1\">\n";
        Xml += " <page width=\"70\" height=\"30\" marginLeft=\"1\" marginTop=\"1\" marginRight=\"1\" marginBottom=\"1\"/>\n";
        Xml += " <bands>\n";
        Xml += "  <band kind=\"reportheader\" name=\"sh\" height=\"10\">\n";
        Xml += "   <text name=\"st\" x=\"0\" y=\"0\" w=\"66\" h=\"6\" fontSize=\"8\">Subreport content here.</text>\n";
        Xml += "  </band>\n";
        Xml += " </bands>\n";
        Xml += "</report>\n";
        WriteText(Sub_, Xml);
        WriteBmp8x8(Img);

        Xml = "";
        Xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        Xml += "<report name=\"Elements\" tagLangVersion=\"1\">\n";
        Xml += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        Xml += " <bands>\n";
        Xml += "  <band kind=\"reportheader\" name=\"rh\" height=\"150\">\n";
        Xml += "   <text name=\"title\" x=\"0\" y=\"0\" w=\"180\" h=\"10\" fontSize=\"18\" hAlign=\"center\">Every Element Kind</text>\n";
        Xml += "   <text name=\"note\"  x=\"0\" y=\"12\" w=\"180\" h=\"6\" fontSize=\"9\" hAlign=\"center\">text / line / shape / image / barcode / subreport</text>\n";
        Xml += "   <line  name=\"rule\" x=\"0\" y=\"20\" w=\"180\" h=\"0.3\" toX=\"180\" toY=\"0\"/>\n";
        Xml += "   <shape name=\"rect\" x=\"0\"  y=\"26\" w=\"55\" h=\"22\" shape=\"0\"/>\n";
        Xml += "   <shape name=\"rrct\" x=\"63\" y=\"26\" w=\"55\" h=\"22\" shape=\"1\"/>\n";
        Xml += "   <shape name=\"elps\" x=\"126\" y=\"26\" w=\"55\" h=\"22\" shape=\"2\"/>\n";
        Xml += "   <text name=\"l1\" x=\"0\"   y=\"49\" w=\"55\" h=\"5\" fontSize=\"7\" hAlign=\"center\">shape=0 rect</text>\n";
        Xml += "   <text name=\"l2\" x=\"63\"  y=\"49\" w=\"55\" h=\"5\" fontSize=\"7\" hAlign=\"center\">shape=1 roundrect</text>\n";
        Xml += "   <text name=\"l3\" x=\"126\" y=\"49\" w=\"55\" h=\"5\" fontSize=\"7\" hAlign=\"center\">shape=2 ellipse</text>\n";
        Xml += "   <image name=\"pic\" x=\"0\" y=\"58\" w=\"24\" h=\"24\" source=\"" + Img + "\" stretch=\"1\"/>\n";
        Xml += "   <text name=\"il\" x=\"0\" y=\"83\" w=\"40\" h=\"5\" fontSize=\"7\">8x8 BMP image</text>\n";
        Xml += "   <barcode name=\"qr\"  x=\"40\"  y=\"58\" w=\"24\" h=\"24\" type=\"0\" text=\"QR:LumasReport\"/>\n";
        Xml += "   <barcode name=\"pdf\" x=\"70\"  y=\"58\" w=\"40\" h=\"24\" type=\"1\" text=\"PDF417-DATA-001\"/>\n";
        Xml += "   <barcode name=\"dm\"  x=\"116\" y=\"58\" w=\"24\" h=\"24\" type=\"2\" text=\"DataMatrix99\"/>\n";
        Xml += "   <barcode name=\"az\"  x=\"146\" y=\"58\" w=\"24\" h=\"24\" type=\"3\" text=\"AZTEC-XYZ\"/>\n";
        Xml += "   <text name=\"bl\" x=\"40\" y=\"83\" w=\"140\" h=\"5\" fontSize=\"7\">barcodes: QR / PDF417 / DataMatrix / Aztec</text>\n";
        Xml += "   <subreport name=\"sub\" x=\"0\" y=\"92\" w=\"90\" h=\"30\" ref=\"05_sub.lrpt\"/>\n";
        Xml += "   <text name=\"sl\" x=\"0\" y=\"123\" w=\"120\" h=\"5\" fontSize=\"7\">^ subreport (05_sub.lrpt) merged above</text>\n";
        Xml += "  </band>\n";
        Xml += " </bands>\n";
        Xml += "</report>\n";
        WriteText(Lrpt, Xml);

        IntPtr Job = LumasPdf.rptOpenReportA(mEng, Lrpt);
        if (Job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(mEng); goto Cleanup; }
        if (!LumasPdf.rptRender(Job)) { Console.WriteLine("render failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        Console.WriteLine("rendered " + LumasPdf.rptGetPageCount(Job) + " page(s)");
        if (!LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf)) { Console.WriteLine("export failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        Console.WriteLine("wrote " + OutPdf);
        LumasPdf.rptCloseReport(Job);
    Cleanup:
        LumasPdf.rptDeleteEngine(mEng);
        LumasPdf.pdfDeletePDF(mPdf);
    }
}

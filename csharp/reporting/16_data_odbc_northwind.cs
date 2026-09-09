//  LumasReport example 16 -- ODBC data provider over the real Northwind.mdb (C# port)
//  Covers: the "odbc" data provider, a live DB connection + JOIN + ORDER BY,
//  grouping (groupheader/groupfooter over a DB column), field interpolation.
//  NOTE: this C# build is x64, so it uses the 64-bit ACE driver
//  "Microsoft Access Driver (*.mdb, *.accdb)" (the VB6 32-bit mirror used the
//  legacy "(*.mdb)" driver).
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Ex16
{
    const string PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0";
    const string RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA";

    const string MDB = "E:\\LUMASPDFSDK\\wrappers\\vcl\\Examples\\Northwind.mdb";

    static string BuildXml()
    {
        string s = "";
        s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        s += "<report name=\"Northwind\" tagLangVersion=\"1\">\n";
        s += " <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\" marginRight=\"15\" marginBottom=\"15\"/>\n";
        s += " <datasources>\n";
        s += "  <datasource alias=\"d\" provider=\"odbc\"\n";
        s += "    conn=\"Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=" + MDB + ";\"\n";
        s += "    query=\"SELECT c.CategoryName, p.ProductName, p.UnitPrice, p.UnitsInStock FROM Categories c INNER JOIN Products p ON c.CategoryID = p.CategoryID ORDER BY c.CategoryName, p.ProductName\"/>\n";
        s += " </datasources>\n";
        s += " <bands>\n";
        s += "  <band kind=\"reportheader\" name=\"rh\" height=\"14\">\n";
        s += "   <text name=\"t\" x=\"0\" y=\"0\" w=\"180\" h=\"10\" fontSize=\"18\" hAlign=\"center\" wordWrap=\"0\">Northwind Product Catalog</text>\n";
        s += "  </band>\n";
        s += "  <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n";
        s += "   <text name=\"c1\" x=\"0\"   y=\"0\" w=\"110\" h=\"5\" fontSize=\"9\" bold=\"1\" wordWrap=\"0\">Product</text>\n";
        s += "   <text name=\"c2\" x=\"120\" y=\"0\" w=\"30\"  h=\"5\" fontSize=\"9\" bold=\"1\" hAlign=\"right\" wordWrap=\"0\">Price</text>\n";
        s += "   <text name=\"c3\" x=\"152\" y=\"0\" w=\"28\"  h=\"5\" fontSize=\"9\" bold=\"1\" hAlign=\"right\" wordWrap=\"0\">Stock</text>\n";
        s += "  </band>\n";
        s += "  <band kind=\"groupheader\" name=\"gh\" group=\"d.CategoryName\" height=\"8\">\n";
        s += "   <text name=\"g\" x=\"0\" y=\"1\" w=\"180\" h=\"6\" fontSize=\"12\" bold=\"1\" wordWrap=\"0\">{{expr: d.CategoryName}}</text>\n";
        s += "  </band>\n";
        s += "  <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n";
        s += "   <text name=\"p\"  x=\"4\"   y=\"0\" w=\"110\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">{{ProductName}}</text>\n";
        s += "   <text name=\"pr\" x=\"120\" y=\"0\" w=\"30\"  h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', UnitPrice) }}</text>\n";
        s += "   <text name=\"sk\" x=\"152\" y=\"0\" w=\"28\"  h=\"5\" fontSize=\"9\" hAlign=\"right\" wordWrap=\"0\">{{UnitsInStock}}</text>\n";
        s += "  </band>\n";
        s += "  <band kind=\"groupfooter\" name=\"gf\" group=\"d.CategoryName\" height=\"4\">\n";
        s += "   <text name=\"ge\" x=\"4\" y=\"0\" w=\"176\" h=\"4\" fontSize=\"7\" wordWrap=\"0\">-- end of {{expr: d.CategoryName}} --</text>\n";
        s += "  </band>\n";
        s += "  <band kind=\"pagefooter\" name=\"pf\" height=\"6\">\n";
        s += "   <text name=\"f\" x=\"0\" y=\"0\" w=\"180\" h=\"5\" fontSize=\"7\" hAlign=\"right\" wordWrap=\"0\">printed {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }}</text>\n";
        s += "  </band>\n";
        s += " </bands>\n";
        s += "</report>\n";
        return s;
    }

    static void Main()
    {
        if (!File.Exists(MDB)) { Console.WriteLine("Northwind.mdb not found: " + MDB); return; }
        IntPtr pdf, eng;
        if (!BootEngine(out pdf, out eng)) return;

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string lrpt = Path.Combine(dir, "16_northwind.lrpt");
        string outPdf = Path.Combine(dir, "16_northwind.pdf");
        string outTxt = Path.Combine(dir, "16_northwind.txt");
        File.WriteAllText(lrpt, BuildXml());

        IntPtr job = LumasPdf.rptOpenReportA(eng, lrpt);
        if (job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(eng); goto Cleanup; }
        if (!LumasPdf.rptRender(job)) { Console.WriteLine("render failed"); DumpRptError(eng); goto CloseJob; }
        Console.WriteLine("rendered " + LumasPdf.rptGetPageCount(job) + " page(s) from Northwind.mdb (odbc)");
        if (!LumasPdf.rptExportA(job, LumasPdfConsts.RPT_EXP_PDF, outPdf)) { Console.WriteLine("pdf export failed"); DumpRptError(eng); goto CloseJob; }
        if (!LumasPdf.rptExportA(job, LumasPdfConsts.RPT_EXP_TEXT, outTxt)) { Console.WriteLine("text export failed"); DumpRptError(eng); goto CloseJob; }
        Console.WriteLine("wrote " + outPdf + "  +  " + outTxt);
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

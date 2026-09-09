//  LumasReport example 19 -- Build a .lrpt STEP-BY-STEP, bind it to the real
//  Northwind.mdb, render + export.  (C# port)
//  The original also pops the SDK's embedded viewer via rptPreviewA (which BLOCKS
//  until closed); pass --headless / --no-preview to skip it and run unattended.
//  NOTE: x64 build -> 64-bit ACE driver "Microsoft Access Driver (*.mdb, *.accdb)".
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Ex19
{
    const string PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0";
    const string RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA";

    const string MDB = "E:\\LUMASPDFSDK\\wrappers\\vcl\\Examples\\Northwind.mdb";

    static string BuildReportXml()
    {
        string s = "";
        // STEP 1 + 2  <report> + <page>
        s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        s += "<report name=\"Northwind Catalog\" tagLangVersion=\"1\">\n";
        s += "  <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\"\n";
        s += "        marginRight=\"15\" marginBottom=\"15\"/>\n";
        // STEP 3  <datasources> -> Northwind.mdb (odbc)
        s += "  <datasources>\n";
        s += "    <datasource alias=\"d\" provider=\"odbc\"\n";
        s += "      conn=\"Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=" + MDB + ";\"\n";
        s += "      query=\"SELECT c.CategoryName, p.ProductName, p.QuantityPerUnit,\n";
        s += "                    p.UnitPrice, p.UnitsInStock\n";
        s += "             FROM Categories c INNER JOIN Products p\n";
        s += "               ON c.CategoryID = p.CategoryID\n";
        s += "             ORDER BY c.CategoryName, p.ProductName\"/>\n";
        s += "  </datasources>\n";
        // STEP 4  <params>
        s += "  <params>\n";
        s += "    <param name=\"Title\"   default=\"'Northwind Product Catalog'\"/>\n";
        s += "    <param name=\"Company\" default=\"'LumasPDF Trading Co.'\"/>\n";
        s += "  </params>\n";
        // STEP 5 + 6  <styles> + open <bands>
        s += "  <styles>\n";
        s += "    <style name=\"Bar\"     backColor=\"005F3A1F\" borderWidth=\"0\"/>\n";
        s += "    <style name=\"GrpBar\"  backColor=\"002A170F\" borderWidth=\"0\"/>\n";
        s += "    <style name=\"Title\"   fontName=\"Helvetica\" fontSize=\"22\" bold=\"1\" textColor=\"00FFFFFF\" vAlign=\"1\"/>\n";
        s += "    <style name=\"Sub\"     fontName=\"Helvetica\" fontSize=\"9\"  textColor=\"00FFFFFF\" hAlign=\"2\" vAlign=\"1\"/>\n";
        s += "    <style name=\"ColH\"    fontName=\"Helvetica\" fontSize=\"8\"  bold=\"1\" textColor=\"00FFFFFF\" vAlign=\"1\"/>\n";
        s += "    <style name=\"ColHR\"   fontName=\"Helvetica\" fontSize=\"8\"  bold=\"1\" textColor=\"00FFFFFF\" hAlign=\"2\" vAlign=\"1\"/>\n";
        s += "    <style name=\"Grp\"     fontName=\"Helvetica\" fontSize=\"12\" bold=\"1\" textColor=\"00FFFFFF\" vAlign=\"1\"/>\n";
        s += "    <style name=\"Cell\"    fontName=\"Helvetica\" fontSize=\"9\"  textColor=\"002A170F\" vAlign=\"1\"/>\n";
        s += "    <style name=\"CellR\"   fontName=\"Helvetica\" fontSize=\"9\"  textColor=\"002A170F\" hAlign=\"2\" vAlign=\"1\"/>\n";
        s += "    <style name=\"Muted\"   fontName=\"Helvetica\" fontSize=\"8\"  textColor=\"008B7464\" vAlign=\"1\"/>\n";
        s += "    <style name=\"Sub L\"   fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"005F3A1F\"/>\n";
        s += "    <style name=\"SubR\"    fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"005F3A1F\" hAlign=\"2\"/>\n";
        s += "    <style name=\"GTotL\"   fontName=\"Helvetica\" fontSize=\"11\" bold=\"1\" textColor=\"00FFFFFF\"/>\n";
        s += "    <style name=\"GTotR\"   fontName=\"Helvetica\" fontSize=\"11\" bold=\"1\" textColor=\"00FFFFFF\" hAlign=\"2\"/>\n";
        s += "    <style name=\"Foot\"    fontName=\"Helvetica\" fontSize=\"7.5\" textColor=\"008B7464\"/>\n";
        s += "    <style name=\"FootR\"   fontName=\"Helvetica\" fontSize=\"7.5\" textColor=\"008B7464\" hAlign=\"2\"/>\n";
        s += "  </styles>\n";
        s += "  <bands>\n";
        // STEP 7  reportheader
        s += "    <band kind=\"reportheader\" name=\"rh\" height=\"26\">\n";
        s += "      <shape name=\"hbar\"  x=\"0\" y=\"0\" w=\"180\" h=\"18\" style=\"Bar\" shape=\"0\"/>\n";
        s += "      <text  name=\"ttl\"   x=\"5\"  y=\"1\"  w=\"120\" h=\"10\" style=\"Title\" wordWrap=\"0\">{{var:Title}}</text>\n";
        s += "      <text  name=\"sub\"   x=\"95\" y=\"6\"  w=\"80\"  h=\"6\"  style=\"Sub\"   wordWrap=\"0\">{{var:Company}}</text>\n";
        s += "      <text  name=\"asof\"  x=\"0\"  y=\"20\" w=\"180\" h=\"4\"  style=\"Muted\" wordWrap=\"0\">Generated {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }} from Northwind.mdb (live ODBC)</text>\n";
        s += "    </band>\n";
        // STEP 8  pageheader
        s += "    <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n";
        s += "      <shape name=\"cbar\" x=\"0\" y=\"0\" w=\"180\" h=\"7\" style=\"GrpBar\" shape=\"0\"/>\n";
        s += "      <text name=\"hP\"  x=\"3\"   y=\"1.5\" w=\"64\" h=\"4\" style=\"ColH\"  wordWrap=\"0\">PRODUCT</text>\n";
        s += "      <text name=\"hK\"  x=\"69\"  y=\"1.5\" w=\"44\" h=\"4\" style=\"ColH\"  wordWrap=\"0\">PACK</text>\n";
        s += "      <text name=\"hU\"  x=\"114\" y=\"1.5\" w=\"21\" h=\"4\" style=\"ColHR\" wordWrap=\"0\">PRICE</text>\n";
        s += "      <text name=\"hS\"  x=\"137\" y=\"1.5\" w=\"18\" h=\"4\" style=\"ColHR\" wordWrap=\"0\">STOCK</text>\n";
        s += "      <text name=\"hV\"  x=\"157\" y=\"1.5\" w=\"20\" h=\"4\" style=\"ColHR\" wordWrap=\"0\">VALUE</text>\n";
        s += "    </band>\n";
        // STEP 9  groupheader
        s += "    <band kind=\"groupheader\" name=\"gh\" group=\"d.CategoryName\" height=\"9\">\n";
        s += "      <shape name=\"gbar\" x=\"0\" y=\"1\" w=\"180\" h=\"7\" style=\"GrpBar\" shape=\"0\"/>\n";
        s += "      <text  name=\"gname\" x=\"4\" y=\"1.7\" w=\"140\" h=\"5\" style=\"Grp\" wordWrap=\"0\">{{expr: d.CategoryName}}</text>\n";
        s += "    </band>\n";
        // STEP 10  detail
        s += "    <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n";
        s += "      <shape name=\"zebra\" x=\"0\" y=\"0\" w=\"180\" h=\"6\" shape=\"0\" backColor=\"00F9F5F1\" visible=\"RowNum % 2 = 0\"/>\n";
        s += "      <text name=\"cP\" x=\"3\"   y=\"1\" w=\"64\" h=\"4\" style=\"Cell\"  wordWrap=\"0\">{{ProductName}}</text>\n";
        s += "      <text name=\"cK\" x=\"69\"  y=\"1\" w=\"44\" h=\"4\" style=\"Muted\" wordWrap=\"0\">{{QuantityPerUnit}}</text>\n";
        s += "      <text name=\"cU\" x=\"114\" y=\"1\" w=\"21\" h=\"4\" style=\"CellR\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', UnitPrice) }}</text>\n";
        s += "      <text name=\"cS\" x=\"137\" y=\"1\" w=\"18\" h=\"4\" style=\"CellR\" wordWrap=\"0\">{{UnitsInStock}}</text>\n";
        s += "      <text name=\"cV\" x=\"157\" y=\"1\" w=\"20\" h=\"4\" style=\"CellR\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0', UnitPrice*UnitsInStock) }}</text>\n";
        s += "      <line name=\"drow\" orient=\"h\" scope=\"section\" vAlign=\"bottom\" width=\"0.15\" color=\"00E2D8CE\"/>\n";
        s += "    </band>\n";
        // STEP 11  groupfooter
        s += "    <band kind=\"groupfooter\" name=\"gf\" group=\"d.CategoryName\" height=\"7\">\n";
        s += "      <line name=\"gtop\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.4\" color=\"005F3A1F\"/>\n";
        s += "      <text name=\"sl\" x=\"3\"   y=\"1.5\" w=\"110\" h=\"4\" style=\"Sub L\" wordWrap=\"0\">Subtotal -- {{expr: d.CategoryName}} ({{expr: COUNT()}} products)</text>\n";
        s += "      <text name=\"sv\" x=\"137\" y=\"1.5\" w=\"40\"  h=\"4\" style=\"SubR\"  wordWrap=\"0\">{{expr: FORMATNUM('#,##0', SUM(UnitPrice*UnitsInStock)) }}</text>\n";
        s += "    </band>\n";
        // STEP 12  summary
        s += "    <band kind=\"summary\" name=\"sm\" height=\"16\">\n";
        s += "      <shape name=\"tbar\" x=\"0\" y=\"2\" w=\"180\" h=\"10\" style=\"Bar\" shape=\"0\"/>\n";
        s += "      <text name=\"gl\" x=\"4\"   y=\"4.2\" w=\"120\" h=\"6\" style=\"GTotL\" wordWrap=\"0\">GRAND TOTAL -- {{expr: COUNT()}} products in {{expr: COUNTDISTINCT(d.CategoryName)}} categories</text>\n";
        s += "      <text name=\"gv\" x=\"120\" y=\"4.2\" w=\"56\"  h=\"6\" style=\"GTotR\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0', SUM(UnitPrice*UnitsInStock)) }}</text>\n";
        s += "    </band>\n";
        // STEP 13  pagefooter
        s += "    <band kind=\"pagefooter\" name=\"pf\" height=\"9\">\n";
        s += "      <line name=\"ft\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.3\" color=\"00B9B9B9\"/>\n";
        s += "      <text name=\"fl\" x=\"0\"   y=\"2.5\" w=\"120\" h=\"4\" style=\"Foot\"  wordWrap=\"0\">{{var:Company}} -- confidential</text>\n";
        s += "      <text name=\"fr\" x=\"120\" y=\"2.5\" w=\"57\"  h=\"4\" style=\"FootR\" wordWrap=\"0\">Page {{var:PageNo}} of {{var:TotalPages}}</text>\n";
        s += "    </band>\n";
        // STEP 14  close </bands></report>
        s += "  </bands>\n";
        s += "</report>\n";
        return s;
    }

    static bool IsHeadless()
    {
        string c = Environment.CommandLine.ToLower();
        return c.IndexOf("--headless") >= 0 || c.IndexOf("--no-preview") >= 0 || c.IndexOf("/headless") >= 0;
    }

    static void Main()
    {
        if (!File.Exists(MDB)) { Console.WriteLine("Northwind.mdb not found: " + MDB); return; }
        IntPtr pdf, eng;
        if (!BootEngine(out pdf, out eng)) return;

        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string lrpt = Path.Combine(dir, "19_northwind.lrpt");
        string outPdf = Path.Combine(dir, "19_northwind.pdf");
        string outTxt = Path.Combine(dir, "19_northwind.txt");

        string xml = BuildReportXml();
        File.WriteAllText(lrpt, xml);
        Console.WriteLine("STEP 1-14: wrote " + lrpt + " (" + xml.Length + " bytes)");

        int pages = 0;
        IntPtr job = LumasPdf.rptOpenReportA(eng, lrpt);
        if (job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(eng); goto Cleanup; }

        LumasPdf.rptSetParamStr(job, "Title", "Northwind Product Catalog");
        LumasPdf.rptSetParamStr(job, "Company", "LumasPDF Trading Co.");

        if (!LumasPdf.rptRender(job)) { Console.WriteLine("render failed"); DumpRptError(eng); goto CloseJob; }
        pages = LumasPdf.rptGetPageCount(job);
        Console.WriteLine("RENDER: " + pages + " page(s) bound from Northwind.mdb");

        if (!LumasPdf.rptExportA(job, LumasPdfConsts.RPT_EXP_PDF, outPdf)) { Console.WriteLine("pdf export failed"); DumpRptError(eng); goto CloseJob; }
        if (!LumasPdf.rptExportA(job, LumasPdfConsts.RPT_EXP_TEXT, outTxt)) { Console.WriteLine("text export failed"); DumpRptError(eng); goto CloseJob; }
        Console.WriteLine("EXPORT: " + outPdf + "  +  " + outTxt);

        // *** EMBEDDED PREVIEW *** -- rptPreviewA opens the SDK viewer and BLOCKS.
        if (IsHeadless())
            Console.WriteLine("PREVIEW: skipped (--headless). Open " + outPdf + " to view.");
        else
        {
            Console.WriteLine("PREVIEW: opening the embedded viewer -- close the window to continue...");
            if (!LumasPdf.rptPreviewA(job, "Northwind Product Catalog"))
            {
                Console.WriteLine("  preview failed (continuing -- not fatal):");
                DumpRptError(eng);
            }
        }
    CloseJob:
        LumasPdf.rptCloseReport(job);

        if (File.Exists(outPdf) && pages >= 1)
            Console.WriteLine("OK: " + outPdf + " exists, " + pages + " page(s).");
        else
            Console.WriteLine("VERIFY FAILED: PDF missing or zero pages");
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

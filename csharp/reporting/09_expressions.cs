//  09_expressions -- C# port of examples\Vb6\reporting\09_expressions.bas
//  41 expression-language lines rendered into one report band.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Expressions09
{
    const string PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0";
    const string RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA";

    static IntPtr mPdf;
    static IntPtr mEng;
    static int mY;

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

    static string LineEl(string label, string expr)
    {
        string r = "   <text name=\"l" + mY + "\" x=\"0\" y=\"" + mY + "\" w=\"185\" h=\"5\" fontSize=\"9\" wordWrap=\"0\">" +
                   label + " -&gt; {{expr: " + expr + "}}</text>\n";
        mY += 5;
        return r;
    }

    static string BuildReport()
    {
        mY = 0;
        string s = "";
        s += LineEl("UPPER", "UPPER('abc')");
        s += LineEl("LOWER", "LOWER('ABC')");
        s += LineEl("LEFT", "LEFT('LumasReport', 5)");
        s += LineEl("RIGHT", "RIGHT('LumasReport', 6)");
        s += LineEl("SUBSTR", "SUBSTR('LumasReport', 6, 6)");
        s += LineEl("LEN", "LEN('LumasReport')");
        s += LineEl("TRIM", "'[' + TRIM('  hi  ') + ']'");
        s += LineEl("REPLACE", "REPLACE('a-b-c', '-', '+')");
        s += LineEl("PADL", "PADL('7', 4, '0')");
        s += LineEl("POS", "POS('Report', 'LumasReport')");
        s += LineEl("REVERSE", "REVERSE('abc')");
        s += LineEl("REPLICATE", "REPLICATE('ab', 3)");
        s += LineEl("CONTAINS", "CONTAINS('LumasReport', 'Rep')");
        s += LineEl("STARTSWITH", "STARTSWITH('LumasReport', 'Lumas')");
        s += LineEl("ENDSWITH", "ENDSWITH('LumasReport', 'port')");
        s += LineEl("ABS", "ABS(-42)");
        s += LineEl("ROUND", "ROUND(3.14159, 2)");
        s += LineEl("FLOOR", "FLOOR(3.9)");
        s += LineEl("CEIL", "CEIL(3.1)");
        s += LineEl("SQRT", "SQRT(144)");
        s += LineEl("POWER", "POWER(2, 10)");
        s += LineEl("MIN", "MIN(5, 3)");
        s += LineEl("MAX", "MAX(5, 3)");
        s += LineEl("SIGN", "SIGN(-7)");
        s += LineEl("TRUNC", "TRUNC(9.87)");
        s += LineEl("MOD_op", "17 % 5");
        s += LineEl("YEAR", "YEAR(TODAY())");
        s += LineEl("FORMATDATE", "FORMATDATE('yyyy-mm-dd', TODAY())");
        s += LineEl("ADDDAYS", "FORMATDATE('yyyy-mm-dd', ADDDAYS(TODAY(), 7))");
        s += LineEl("DATEDIFF", "DATEDIFF('d', TODAY(), ADDDAYS(TODAY(), 30))");
        s += LineEl("CSTR", "CSTR(123)");
        s += LineEl("CINT", "CINT('45')");
        s += LineEl("CFLOAT", "CFLOAT('3.5') * 2");
        s += LineEl("VAL", "VAL('19') + 1");
        s += LineEl("FORMATNUM", "FORMATNUM('#,##0.00', 1234.5)");
        s += LineEl("ISNULL", "ISNULL(NULLIF(3, 3))");
        s += LineEl("IFNULL", "IFNULL(NULLIF(3, 3), 'was-null')");
        s += LineEl("COALESCE", "COALESCE(NULLIF(1,1), NULLIF(2,2), 'fallback')");
        s += LineEl("REGEXMATCH", "REGEXMATCH('abc123', '[a-z]+[0-9]+')");
        s += LineEl("REGEXREPLACE", "REGEXREPLACE('a1b2c3', '[0-9]', '#')");
        s += LineEl("REGEXEXTRACT", "REGEXEXTRACT('order 4567 ok', '[0-9]+')");

        string Xml = "";
        Xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        Xml += "<report name=\"Expressions\" tagLangVersion=\"1\">\n";
        Xml += " <page width=\"210\" height=\"297\" marginLeft=\"12\" marginTop=\"12\" marginRight=\"12\" marginBottom=\"12\"/>\n";
        Xml += " <bands>\n";
        Xml += "  <band kind=\"reportheader\" name=\"rh\" height=\"" + (mY + 4) + "\">\n";
        Xml += s;
        Xml += "  </band>\n";
        Xml += " </bands>\n";
        Xml += "</report>\n";
        return Xml;
    }

    static void Main()
    {
        if (!BootEngine()) return;

        string Xml = BuildReport();
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string Lrpt = Path.Combine(dir, "09_expr.lrpt");
        string OutPdf = Path.Combine(dir, "09_expr.pdf");
        string OutTxt = Path.Combine(dir, "09_expr.txt");
        WriteText(Lrpt, Xml);

        IntPtr Job = LumasPdf.rptOpenReportA(mEng, Lrpt);
        if (Job == IntPtr.Zero) { Console.WriteLine("open failed"); DumpRptError(mEng); goto Cleanup; }
        if (!LumasPdf.rptRender(Job)) { Console.WriteLine("render failed"); DumpRptError(mEng); LumasPdf.rptCloseReport(Job); goto Cleanup; }
        LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf);
        LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt);
        Console.WriteLine("rendered " + LumasPdf.rptGetPageCount(Job) + " page(s); 41 expression lines -> " + OutTxt);
        LumasPdf.rptCloseReport(Job);
    Cleanup:
        LumasPdf.rptDeleteEngine(mEng);
        LumasPdf.pdfDeletePDF(mPdf);
    }
}

// probe_test -- C# port of examples\Vb6\probe_test\probe_test.bas
// Step-by-step probe of the TPDF flow + TPDFTable (tbl* exports).
using System;
using System.IO;
using LumasPdfSdk;

class ProbeTest
{
    static TErrorProc _err = ErrProc;

    static int ErrProc(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine("ERR " + errCode + ": " + errMessage);
        return 0;
    }

    static void Main()
    {
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        IntPtr pdf = LumasPdf.pdfNewPDF();
        Console.WriteLine("Create ok");
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        Console.WriteLine("CreateNewPDF('') = " + LumasPdf.pdfCreateNewPDFW(pdf, ""));
        Console.WriteLine("SetPageCoords = " + LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown));
        Console.WriteLine("Append = " + LumasPdf.pdfAppend(pdf));
        Console.WriteLine("SetFont = " + LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsRegular, 12.0, true, TCodepage.cp1252));
        Console.WriteLine("WriteText = " + LumasPdf.pdfWriteTextW(pdf, 50, 50, "probe"));

        IntPtr tbl = LumasPdf.tblCreateTable(pdf, 3, 3, 500f, 100f);
        Console.WriteLine("Table created");
        int r = LumasPdf.tblAddRow(tbl, -1f);
        Console.WriteLine("AddRow = " + r);
        // NOTE: the VB6 template passes Len = -1 (the classic API's null-terminated sentinel), but the
        // LumasPdf engine treats Len as an unsigned byte count (Len>0 => copy Len bytes), so
        // 0xFFFFFFFF causes a 4GB copy / AccessViolation. Pass 0 = auto-length instead.
        Console.WriteLine("SetCellText = " + LumasPdf.tblSetCellTextA(tbl, (uint)r, 0, LumasPdfConsts.taLeft, TCellAlign.coTop, "cell", 0));
        Console.WriteLine("DrawTable = " + LumasPdf.tblDrawTable(tbl, 50f, 80f, 700f));
        Console.WriteLine("HaveMore = " + LumasPdf.tblHaveMore(tbl));
        LumasPdf.tblDeleteTable(ref tbl);

        Console.WriteLine("EndPage = " + LumasPdf.pdfEndPage(pdf));
        Console.WriteLine("GetPageCount = " + LumasPdf.pdfGetPageCount(pdf));
        Console.WriteLine("HaveOpenDoc = " + LumasPdf.pdfHaveOpenDoc(pdf));
        string outFile = Path.Combine(dir, "probe_out.pdf");
        Console.WriteLine("OpenOutputFile = " + LumasPdf.pdfOpenOutputFileW(pdf, outFile));
        Console.WriteLine("CloseFile = " + LumasPdf.pdfCloseFile(pdf));
        LumasPdf.pdfDeletePDF(pdf);
    }
}

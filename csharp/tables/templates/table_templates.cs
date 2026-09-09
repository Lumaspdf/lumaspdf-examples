//  table_templates -- C# port of examples\Vb6\tables\templates\table_templates.bas
//  Imports every page of dynapdf_help.pdf as a template and lays them out two
//  per row in a table (tfScaleToRect), then draws the table across as many
//  output pages as needed. Uses the flat tbl* exports (TPDFTable handle).
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class TableTemplates
{
    // Table flag missing from the shared wrapper (from dynapdf.pas):
    const uint tfScaleToRect = 0x8;

    static TErrorProc _errCb = ErrProc;

    public static int ErrProc(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;                       // try to continue
    }

    static void Main()
    {
        int timeStart = Environment.TickCount;

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _errCb);

        LumasPdf.pdfCreateNewPDFW(pdf, "");

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfSetImportFlags2(pdf, LumasPdfConsts.if2UseProxy);   // Reduce the memory usage

        // Original: App.Path & "\..\..\..\..\dynapdf_help.pdf"
        string inFile = System.IO.Path.Combine(System.AppContext.BaseDirectory, "..", "..", "..", "..", "test_files") + "\\dynapdf_help.pdf";
        LumasPdf.pdfOpenImportFileW(pdf, inFile, (int)LumasPdfConsts.ptOpen, "");

        int pageCount = LumasPdf.pdfGetInPageCount(pdf);
        if (pageCount < 1)
        {
            Console.WriteLine("Help file not found!");
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        IntPtr tbl = LumasPdf.tblCreateTable(pdf, (uint)(pageCount / 4 + 1), 2, 512.12f, 0f);
        LumasPdf.tblSetBoxProperty(tbl, -1, -1, TTableBoxProperty.tbpBorderWidth, 1f, 1f, 1f, 1f);
        LumasPdf.tblSetBoxProperty(tbl, -1, -1, TTableBoxProperty.tbpCellPadding, 5f, 5f, 5f, 5f);
        LumasPdf.tblSetGridWidth(tbl, 1f, 1f);
        LumasPdf.tblSetFlags(tbl, -1, -1, tfScaleToRect);

        LumasPdf.pdfSetPageFormat(pdf, (int)TPageFormat.pfUS_Letter);

        int rowNum = 0;
        for (int i = 1; i <= pageCount; i++)
        {
            int tmpl = LumasPdf.pdfImportPage(pdf, (uint)i);
            if ((i & 1) != 0) rowNum = LumasPdf.tblAddRow(tbl, 335f);
            LumasPdf.tblSetCellTemplate(tbl, rowNum, (i - 1) & 1, true, TCellAlign.coCenter, TCellAlign.coCenter, (uint)tmpl, 0f, 0f);
        }

        // Draw the table now
        LumasPdf.pdfAppend(pdf);
        LumasPdf.tblDrawTable(tbl, 50f, 50f, 742f);
        while (LumasPdf.tblHaveMore(tbl))
        {
            LumasPdf.pdfEndPage(pdf);
            LumasPdf.pdfAppend(pdf);
            LumasPdf.tblDrawTable(tbl, 50f, 50f, 742f);
        }
        LumasPdf.pdfEndPage(pdf);

        LumasPdf.tblDeleteTable(ref tbl);

        // A table stores errors and warnings in the error log
        TPDFError err = new TPDFError();
        err.StructSize = (uint)Marshal.SizeOf(typeof(TPDFError));
        for (int i = 0; i < LumasPdf.pdfGetErrLogMessageCount(pdf); i++)
        {
            LumasPdf.pdfGetErrLogMessage(pdf, (uint)i, ref err);
            Console.WriteLine(Marshal.PtrToStringAnsi(err.Msg));
        }

        // No fatal error occurred?
        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
            if (LumasPdf.pdfCloseFile(pdf))
            {
                timeStart = Environment.TickCount - timeStart;
                Console.WriteLine("Processing time: " + timeStart + " ms");
            }
        }

        LumasPdf.pdfDeletePDF(pdf);
    }
}

//  table_text -- C# port of examples\Vb6\tables\text\table_text.bas
//  Builds a 3x3 table demonstrating cell text alignment (left/center/right x
//  top/center/bottom), draws it, then redraws it with a 90-degree cell
//  orientation. Uses the flat tbl* exports (TPDFTable handle).
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class TableText
{
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

        IntPtr tbl = LumasPdf.tblCreateTable(pdf, 3, 3, 500f, 100f);
        LumasPdf.tblSetBoxProperty(tbl, -1, -1, TTableBoxProperty.tbpBorderWidth, 1f, 1f, 1f, 1f);
        LumasPdf.tblSetFontA(tbl, -1, -1, "Arial", LumasPdfConsts.fsRegular, true, TCodepage.cp1252);
        LumasPdf.tblSetFontA(tbl, -1, 1, "Arial", LumasPdfConsts.fsBold, true, TCodepage.cp1252);
        LumasPdf.tblSetGridWidth(tbl, 1f, 1f);

        string txt = "The cell alignment can be set for text, images, and templates...";
        // NOTE: the VB6/Delphi original passes Len = -1 (auto null-terminated length).
        // The LumasPdf engine's tblSetCellTextA crashes (AccessViolation) on Len = -1,
        // so we pass the explicit string length here. (Engine bug: -1 sentinel unhandled.)
        uint all = (uint)txt.Length;

        // -1.0 means use the default row height as specified in the CreateTable() call.
        int rowNum = LumasPdf.tblAddRow(tbl, -1f);
        LumasPdf.tblSetCellTextA(tbl, (uint)rowNum, 0, LumasPdfConsts.taLeft, TCellAlign.coTop, txt, all);
        LumasPdf.tblSetCellTextA(tbl, (uint)rowNum, 1, LumasPdfConsts.taCenter, TCellAlign.coTop, txt, all);
        LumasPdf.tblSetCellTextA(tbl, (uint)rowNum, 2, LumasPdfConsts.taRight, TCellAlign.coTop, txt, all);

        rowNum = LumasPdf.tblAddRow(tbl, -1f);
        LumasPdf.tblSetCellTextA(tbl, (uint)rowNum, 0, LumasPdfConsts.taLeft, TCellAlign.coCenter, txt, all);
        LumasPdf.tblSetCellTextA(tbl, (uint)rowNum, 1, LumasPdfConsts.taCenter, TCellAlign.coCenter, txt, all);
        LumasPdf.tblSetCellTextA(tbl, (uint)rowNum, 2, LumasPdfConsts.taRight, TCellAlign.coCenter, txt, all);

        rowNum = LumasPdf.tblAddRow(tbl, -1f);
        LumasPdf.tblSetCellTextA(tbl, (uint)rowNum, 0, LumasPdfConsts.taLeft, TCellAlign.coBottom, txt, all);
        LumasPdf.tblSetCellTextA(tbl, (uint)rowNum, 1, LumasPdfConsts.taCenter, TCellAlign.coBottom, txt, all);
        LumasPdf.tblSetCellTextA(tbl, (uint)rowNum, 2, LumasPdfConsts.taRight, TCellAlign.coBottom, txt, all);

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

        // Let's change the cell orientation to see what happens...
        LumasPdf.tblSetCellOrientation(tbl, -1, -1, 90);
        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsRegular, 12.0, true, TCodepage.cp1252);
        LumasPdf.pdfWriteTextW(pdf, 50.0, 50.0, "The same table but the cell orientation was changed to 90 degrees.");

        LumasPdf.tblDrawTable(tbl, 50f, 65f, 742f);
        while (LumasPdf.tblHaveMore(tbl))
        {
            LumasPdf.pdfEndPage(pdf);
            LumasPdf.pdfAppend(pdf);
            LumasPdf.tblDrawTable(tbl, 50f, 50f, 737f);
        }
        LumasPdf.pdfEndPage(pdf);

        LumasPdf.tblDeleteTable(ref tbl);   // frees the table and sets tbl to 0

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
            // We write the file into the application directory.
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

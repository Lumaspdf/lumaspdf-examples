//  table_images -- C# port of examples\Vb6\tables\images\table_images.bas
//  Lays out every JPEG in test_files\images into a 4-column table (one image
//  per cell, native image color space), draws it, then redraws with
//  tfScaleToRect. Uses the flat tbl* exports (TPDFTable handle).
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class TableImages
{
    // Table flags missing from the shared wrapper (from dynapdf.pas):
    const uint tfScaleToRect = 0x8;
    const uint tfUseImageCS = 0x10;

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
        LumasPdf.pdfSetResolution(pdf, 300);

        IntPtr tbl = LumasPdf.tblCreateTable(pdf, 100, 4, 500f, 125f);
        LumasPdf.tblSetBoxProperty(tbl, -1, -1, TTableBoxProperty.tbpBorderWidth, 1f, 1f, 1f, 1f);
        LumasPdf.tblSetBoxProperty(tbl, -1, -1, TTableBoxProperty.tbpCellPadding, 5f, 5f, 5f, 5f);
        LumasPdf.tblSetGridWidth(tbl, 1f, 1f);
        LumasPdf.tblSetFlags(tbl, -1, -1, tfUseImageCS);

        // Original: App.Path & "\..\..\..\..\test_files\images\"
        string imgDir = System.IO.Path.Combine(System.AppContext.BaseDirectory, "..", "..", "..", "..", "test_files") + System.IO.Path.DirectorySeparatorChar + "images";
        string[] files = Directory.Exists(imgDir) ? Directory.GetFiles(imgDir, "*.jpg") : new string[0];
        if (files.Length == 0)
        {
            Console.WriteLine("Test images not found!");
            LumasPdf.tblDeleteTable(ref tbl);
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }
        Array.Sort(files);

        long fullSize = new FileInfo(files[0]).Length;
        int rowNum = LumasPdf.tblAddRow(tbl, 125f);
        LumasPdf.tblSetCellImageA(tbl, rowNum, 0, true, TCellAlign.coCenter, TCellAlign.coCenter, 0f, 0f, files[0], 1);

        int i = 1;
        for (int f = 1; f < files.Length; f++)
        {
            if (i == 4)
            {
                rowNum = LumasPdf.tblAddRow(tbl, 100f);
                i = 0;
            }
            fullSize += new FileInfo(files[f]).Length;
            LumasPdf.tblSetCellImageA(tbl, rowNum, i, true, TCellAlign.coCenter, TCellAlign.coCenter, 0f, 0f, files[f], 1);
            i++;
        }

        LumasPdf.pdfAppend(pdf);

        LumasPdf.tblDrawTable(tbl, 50f, 50f, 742f);
        while (LumasPdf.tblHaveMore(tbl))
        {
            LumasPdf.pdfEndPage(pdf);
            if (fullSize > 104857600) LumasPdf.pdfFlushPages(pdf, LumasPdfConsts.fpfDefault);
            LumasPdf.pdfAppend(pdf);
            LumasPdf.tblDrawTable(tbl, 50f, 50f, 742f);
        }
        LumasPdf.pdfEndPage(pdf);

        // We draw the same table again but this time with the flag tfScaleToRect
        LumasPdf.tblSetFlags(tbl, -1, -1, tfScaleToRect | tfUseImageCS);
        LumasPdf.pdfAppend(pdf);

        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsRegular, 12.0, true, TCodepage.cp1252);
        LumasPdf.pdfWriteTextW(pdf, 50.0, 50.0, "The same table but the flag tfScaleToRect was set.");

        LumasPdf.tblDrawTable(tbl, 50f, 65f, 742f);
        while (LumasPdf.tblHaveMore(tbl))
        {
            LumasPdf.pdfEndPage(pdf);
            if (fullSize > 104857600) LumasPdf.pdfFlushPages(pdf, LumasPdfConsts.fpfDefault);
            LumasPdf.pdfAppend(pdf);
            LumasPdf.tblDrawTable(tbl, 50f, 50f, 742f);
        }
        LumasPdf.pdfEndPage(pdf);

        LumasPdf.tblDeleteTable(ref tbl);

        // A table stores errors and warnings in the error log
        TPDFError err = new TPDFError();
        err.StructSize = (uint)Marshal.SizeOf(typeof(TPDFError));
        for (i = 0; i < LumasPdf.pdfGetErrLogMessageCount(pdf); i++)
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

//  bookmarks -- C# port of examples\Vb6\bookmarks\bookmarks.bas
//  Demonstrates the various bookmark destination types plus a page link with a
//  GoTo action. Flat pdf* binding over LumasPdf.dll.
using System;
using System.IO;
using LumasPdfSdk;

class Bookmarks
{
    // Keep the error delegate alive for the lifetime of the program.
    static TErrorProc _err = PDFError;

    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;                       // We try to continue if an error occurs
    }

    // VCL TColor values (COLORREF, R in low byte) used by SetBookmarkStyle.
    const uint clRed    = 0xFF;
    const uint clGreen  = 0x8000;
    const uint clBlue   = 0xFF0000;
    const uint clMaroon = 0x80;

    static void Main()
    {
        int f, bmk, root, lnk, act;
        double x, y;

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");          // The output file is opened later

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfSetPageHeight(pdf, 500.0);
        LumasPdf.pdfSetPageWidth(pdf, 800.0);

        LumasPdf.pdfAppend(pdf);
        f = LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 20, false, TCodepage.cp1252);
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Bookmark destination type dtFit");
        root = LumasPdf.pdfAddBookmarkW(pdf, "DestType dtFit", -1, 1, 1);
        LumasPdf.pdfSetBookmarkDest(pdf, root, (int)TDestType.dtFit, 0, 0, 0, 0);
        LumasPdf.pdfSetBookmarkStyle(pdf, root, LumasPdfConsts.fsItalic, clRed);
        LumasPdf.pdfEndPage(pdf);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfChangeFont(pdf, f);
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Bookmark destination type dtXY_Zoom");
        LumasPdf.pdfWriteTextW(pdf, 50, 70, "Zoom factor 3, Top position 50 (TopDown coordinates)");
        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtXY_Zoom, zoom factor 3", root, 2, 0);
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, (int)TDestType.dtXY_Zoom, 50, 50, 3, 0);
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsBold, clMaroon);
        LumasPdf.pdfEndPage(pdf);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfChangeFont(pdf, f);
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Bookmark destination type dtXY_Zoom");
        LumasPdf.pdfWriteTextW(pdf, 50, 70, "Zoom factor 0.5, Top position 50 (TopDown coordinates)");
        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtXY_Zoom, zoom factor 0.5", root, 3, 0);
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, (int)TDestType.dtXY_Zoom, 50, 50, 0.5, 0);
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsBold | LumasPdfConsts.fsItalic, clGreen);
        LumasPdf.pdfEndPage(pdf);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfChangeFont(pdf, f);
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Bookmark destination type dtXY_Zoom");
        LumasPdf.pdfWriteTextW(pdf, 50, 70, "Zoom factor not defined (unchanged), Top position 50 (TopDown coordinates)");
        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtXY_Zoom, zoom factor unchanged", root, 4, 0);
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, (int)TDestType.dtXY_Zoom, 50, 50, 0, 0);
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsRegular, clBlue);
        LumasPdf.pdfEndPage(pdf);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfChangeFont(pdf, f);
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Bookmark destination type dtFitH_Top");
        LumasPdf.pdfWriteTextW(pdf, 50, 70, "Top position 50 (TopDown coordinates)");
        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtFitH_Top (50)", root, 5, 0);
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, (int)TDestType.dtFitH_Top, 50, 0, 0, 0);
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsRegular, 0xFF8080);
        LumasPdf.pdfWriteTextW(pdf, 50, 200, "Bookmark destination type dtFitH_Top");
        LumasPdf.pdfWriteTextW(pdf, 50, 220, "Top position 200 (TopDown coordinates)");
        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType dtFitH_Top (200)", root, 5, 0);
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, (int)TDestType.dtFitH_Top, 200, 0, 0, 0);
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsRegular, 0xC08080);
        LumasPdf.pdfEndPage(pdf);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfChangeFont(pdf, f);
        LumasPdf.pdfWriteTextW(pdf, 200, 50, "Bookmark destination type dtFitV_Left");
        LumasPdf.pdfWriteTextW(pdf, 200, 70, "Left position 200. FitV has no effect if the width of the page");
        LumasPdf.pdfWriteTextW(pdf, 200, 90, "is not greater as the height.");
        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtFitV_Left (200)", root, 6, 0);
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, (int)TDestType.dtFitV_Left, 200, 0, 0, 0);
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsRegular, 0x808FFF);
        LumasPdf.pdfEndPage(pdf);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfChangeFont(pdf, f);
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Bookmark destination type dtFit_Rect");
        x = (LumasPdf.pdfGetPageWidth(pdf) - 90.0) / 2.0;
        y = (LumasPdf.pdfGetPageHeight(pdf) - 65.0) / 2.0;

        LumasPdf.pdfWriteFTextExW(pdf, x, y, 90.0, -1, (int)LumasPdfConsts.taCenter, "We zoom into the rectangle");
        LumasPdf.pdfRectangle(pdf, x, y, 90.0, 65.0, (int)TPathFillMode.fmStroke);

        // A page link with a GoTo action that zooms into the rectangle.
        LumasPdf.pdfSetLinkHighlightMode(pdf, (int)THighlightMode.hmInvert);
        lnk = LumasPdf.pdfPageLink(pdf, x, y, 90, 65, 7);
        act = LumasPdf.pdfCreateGoToAction(pdf, TDestType.dtFit_Rect, 7, x - 5.0, y - 5.0, x + 100.0, y + 70.0);
        LumasPdf.pdfAddActionToObj(pdf, (int)TObjType.otPageLink, (int)TObjEvent.oeOnMouseUp, (uint)act, (uint)lnk);

        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtFit_Rect", -1, 7, 0);
        // The page link uses the same destination as the bookmark.
        LumasPdf.pdfAddActionToObj(pdf, (int)TObjType.otBookmark, (int)TObjEvent.oeOnMouseUp, (uint)act, (uint)bmk);
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsRegular, 0x80FF);
        LumasPdf.pdfEndPage(pdf);

        LumasPdf.pdfSetPageFormat(pdf, (int)TPageFormat.pfDIN_A4);
        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfChangeFont(pdf, f);
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 50.0, LumasPdf.pdfGetPageWidth(pdf) - 100.0, -1.0, (int)LumasPdfConsts.taLeft,
            "Destination type dtFit. This variant scales the page so that both sides fit into the viewer window.");
        LumasPdf.pdfEndPage(pdf);

        root = LumasPdf.pdfAddBookmarkW(pdf, "DestType dtFit", -1, 8, 0);
        LumasPdf.pdfSetBookmarkDest(pdf, root, (int)TDestType.dtFit, 0, 0, 0, 0);

        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtXY_Zoom, zoom factor 3", root, 2, 0);
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, (int)TDestType.dtXY_Zoom, 50, 50, 3, 0);
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsBold, clMaroon);

        LumasPdf.pdfSetPageLayout(pdf, LumasPdfConsts.plOneColumn);

        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
        // No fatal error occurred?
        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
            if (LumasPdf.pdfCloseFile(pdf))
                Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
        }
        LumasPdf.pdfDeletePDF(pdf);
    }
}

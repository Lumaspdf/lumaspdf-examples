' bookmarks -- VB.NET port of examples\Vb6\bookmarks\bookmarks.bas
Imports System
Imports System.IO
Imports LumasPdfSdk

Module Bookmarks
    Private errDel As TErrorProc

    Private Const clRed As UInteger = &HFFUI
    Private Const clGreen As UInteger = &H8000UI
    Private Const clBlue As UInteger = &HFF0000UI
    Private Const clMaroon As UInteger = &H80UI

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim act As Integer, lnk As Integer, f As Integer, bmk As Integer, root As Integer
        Dim x As Double, y As Double
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)
        LumasPdf.pdfSetPageHeight(pdf, 500.0)
        LumasPdf.pdfSetPageWidth(pdf, 800.0)

        LumasPdf.pdfAppend(pdf)
        f = LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 20, False, TCodepage.cp1252)
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Bookmark destination type dtFit")
        root = LumasPdf.pdfAddBookmarkW(pdf, "DestType dtFit", -1, 1, 1)
        LumasPdf.pdfSetBookmarkDest(pdf, root, TDestType.dtFit, 0, 0, 0, 0)
        LumasPdf.pdfSetBookmarkStyle(pdf, root, LumasPdfConsts.fsItalic, clRed)
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfChangeFont(pdf, f)
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Bookmark destination type dtXY_Zoom")
        LumasPdf.pdfWriteTextW(pdf, 50, 70, "Zoom factor 3, Top position 50 (TopDown coordinates)")
        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtXY_Zoom, zoom factor 3", root, 2, 0)
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, TDestType.dtXY_Zoom, 50, 50, 3, 0)
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsBold, clMaroon)
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfChangeFont(pdf, f)
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Bookmark destination type dtXY_Zoom")
        LumasPdf.pdfWriteTextW(pdf, 50, 70, "Zoom factor 0.5, Top position 50 (TopDown coordinates)")
        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtXY_Zoom, zoom factor 0.5", root, 3, 0)
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, TDestType.dtXY_Zoom, 50, 50, 0.5, 0)
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsBold Or LumasPdfConsts.fsItalic, clGreen)
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfChangeFont(pdf, f)
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Bookmark destination type dtXY_Zoom")
        LumasPdf.pdfWriteTextW(pdf, 50, 70, "Zoom factor not defined (unchanged), Top position 50 (TopDown coordinates)")
        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtXY_Zoom, zoom factor unchanged", root, 4, 0)
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, TDestType.dtXY_Zoom, 50, 50, 0, 0)
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsRegular, clBlue)
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfChangeFont(pdf, f)
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Bookmark destination type dtFitH_Top")
        LumasPdf.pdfWriteTextW(pdf, 50, 70, "Top position 50 (TopDown coordinates)")
        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtFitH_Top (50)", root, 5, 0)
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, TDestType.dtFitH_Top, 50, 0, 0, 0)
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsRegular, &HFF8080UI)
        LumasPdf.pdfWriteTextW(pdf, 50, 200, "Bookmark destination type dtFitH_Top")
        LumasPdf.pdfWriteTextW(pdf, 50, 220, "Top position 200 (TopDown coordinates)")
        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType dtFitH_Top (200)", root, 5, 0)
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, TDestType.dtFitH_Top, 200, 0, 0, 0)
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsRegular, &HC08080UI)
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfChangeFont(pdf, f)
        LumasPdf.pdfWriteTextW(pdf, 200, 50, "Bookmark destination type dtFitV_Left")
        LumasPdf.pdfWriteTextW(pdf, 200, 70, "Left position 200. FitV has no effect if the width of the page")
        LumasPdf.pdfWriteTextW(pdf, 200, 90, "is not greater as the height.")
        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtFitV_Left (200)", root, 6, 0)
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, TDestType.dtFitV_Left, 200, 0, 0, 0)
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsRegular, &H808FFFUI)
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfChangeFont(pdf, f)
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Bookmark destination type dtFit_Rect")
        x = (LumasPdf.pdfGetPageWidth(pdf) - 90.0) / 2.0
        y = (LumasPdf.pdfGetPageHeight(pdf) - 65.0) / 2.0
        LumasPdf.pdfWriteFTextExW(pdf, x, y, 90.0, -1, LumasPdfConsts.taCenter, "We zoom into the rectangle")
        LumasPdf.pdfRectangle(pdf, x, y, 90.0, 65.0, TPathFillMode.fmStroke)

        LumasPdf.pdfSetLinkHighlightMode(pdf, THighlightMode.hmInvert)
        lnk = LumasPdf.pdfPageLink(pdf, x, y, 90, 65, 7)
        act = LumasPdf.pdfCreateGoToAction(pdf, TDestType.dtFit_Rect, 7, x - 5.0, y - 5.0, x + 100.0, y + 70.0)
        LumasPdf.pdfAddActionToObj(pdf, TObjType.otPageLink, TObjEvent.oeOnMouseUp, CUInt(act), CUInt(lnk))

        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtFit_Rect", -1, 7, 0)
        LumasPdf.pdfAddActionToObj(pdf, TObjType.otBookmark, TObjEvent.oeOnMouseUp, CUInt(act), CUInt(bmk))
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsRegular, &H80FFUI)
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.pdfSetPageFormat(pdf, TPageFormat.pfDIN_A4)
        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfChangeFont(pdf, f)
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 50.0, LumasPdf.pdfGetPageWidth(pdf) - 100.0, -1.0, LumasPdfConsts.taLeft, "Destination type dtFit. This variant scales the page so that both sides fit into the viewer window.")
        LumasPdf.pdfEndPage(pdf)

        root = LumasPdf.pdfAddBookmarkW(pdf, "DestType dtFit", -1, 8, 0)
        LumasPdf.pdfSetBookmarkDest(pdf, root, TDestType.dtFit, 0, 0, 0, 0)

        bmk = LumasPdf.pdfAddBookmarkW(pdf, "DestType: dtXY_Zoom, zoom factor 3", root, 2, 0)
        LumasPdf.pdfSetBookmarkDest(pdf, bmk, TDestType.dtXY_Zoom, 50, 50, 3, 0)
        LumasPdf.pdfSetBookmarkStyle(pdf, bmk, LumasPdfConsts.fsBold, clMaroon)

        LumasPdf.pdfSetPageLayout(pdf, LumasPdfConsts.plOneColumn)

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            Dim outFile As String = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf")
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
            If LumasPdf.pdfCloseFile(pdf) <> 0 Then
                Console.WriteLine("PDF file """ & outFile & """ successfully created!")
            End If
        End If
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

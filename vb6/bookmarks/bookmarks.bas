Attribute VB_Name = "modBookmarks"
Option Explicit
' ============================================================================
'  bookmarks -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Demonstrates the various bookmark destination types (dtFit, dtXY_Zoom,
'  dtFitH_Top, dtFitV_Left, dtFit_Rect) plus a page link with a GoTo action.
'  Enums come from the typelib; only the VCL TColor literals (COLORREF) are
'  local -- they are not engine enums.
' ============================================================================

' VCL TColor values (COLORREF, R in low byte) used by SetBookmarkStyle.
Private Const clRed    As Long = &HFF&
Private Const clGreen  As Long = &H8000&
Private Const clBlue   As Long = &HFF0000
Private Const clMaroon As Long = &H80&

Public Sub Main()
    Dim pdf As New CPDF
    Dim act As Long, lnk As Long, f As Long, bmk As Long, root As Long
    Dim x As Double, y As Double, outFile As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown
    pdf.SetPageHeight 500
    pdf.SetPageWidth 800

    pdf.Append
        f = pdf.SetFont("Helvetica", fsRegular, 20, False, cp1252)
        pdf.WriteText 50, 50, "Bookmark destination type dtFit"
        root = pdf.AddBookmarkA("DestType dtFit", -1, 1, 1)
        pdf.SetBookmarkDest root, dtFit, 0, 0, 0, 0
        pdf.SetBookmarkStyle root, fsItalic, clRed
    pdf.EndPage

    pdf.Append
        pdf.ChangeFont f
        pdf.WriteText 50, 50, "Bookmark destination type dtXY_Zoom"
        pdf.WriteText 50, 70, "Zoom factor 3, Top position 50 (TopDown coordinates)"
        bmk = pdf.AddBookmarkA("DestType: dtXY_Zoom, zoom factor 3", root, 2, 0)
        pdf.SetBookmarkDest bmk, dtXY_Zoom, 50, 50, 3, 0
        pdf.SetBookmarkStyle bmk, fsBold, clMaroon
    pdf.EndPage

    pdf.Append
        pdf.ChangeFont f
        pdf.WriteText 50, 50, "Bookmark destination type dtXY_Zoom"
        pdf.WriteText 50, 70, "Zoom factor 0.5, Top position 50 (TopDown coordinates)"
        bmk = pdf.AddBookmarkA("DestType: dtXY_Zoom, zoom factor 0.5", root, 3, 0)
        pdf.SetBookmarkDest bmk, dtXY_Zoom, 50, 50, 0.5, 0
        pdf.SetBookmarkStyle bmk, fsBold Or fsItalic, clGreen
    pdf.EndPage

    pdf.Append
        pdf.ChangeFont f
        pdf.WriteText 50, 50, "Bookmark destination type dtXY_Zoom"
        pdf.WriteText 50, 70, "Zoom factor not defined (unchanged), Top position 50 (TopDown coordinates)"
        bmk = pdf.AddBookmarkA("DestType: dtXY_Zoom, zoom factor unchanged", root, 4, 0)
        pdf.SetBookmarkDest bmk, dtXY_Zoom, 50, 50, 0, 0
        pdf.SetBookmarkStyle bmk, fsRegular, clBlue
    pdf.EndPage

    pdf.Append
        pdf.ChangeFont f
        pdf.WriteText 50, 50, "Bookmark destination type dtFitH_Top"
        pdf.WriteText 50, 70, "Top position 50 (TopDown coordinates)"
        bmk = pdf.AddBookmarkA("DestType: dtFitH_Top (50)", root, 5, 0)
        pdf.SetBookmarkDest bmk, dtFitH_Top, 50, 0, 0, 0
        pdf.SetBookmarkStyle bmk, fsRegular, &HFF8080
        pdf.WriteText 50, 200, "Bookmark destination type dtFitH_Top"
        pdf.WriteText 50, 220, "Top position 200 (TopDown coordinates)"
        bmk = pdf.AddBookmarkA("DestType dtFitH_Top (200)", root, 5, 0)
        pdf.SetBookmarkDest bmk, dtFitH_Top, 200, 0, 0, 0
        pdf.SetBookmarkStyle bmk, fsRegular, &HC08080
    pdf.EndPage

    pdf.Append
        pdf.ChangeFont f
        pdf.WriteText 200, 50, "Bookmark destination type dtFitV_Left"
        pdf.WriteText 200, 70, "Left position 200. FitV has no effect if the width of the page"
        pdf.WriteText 200, 90, "is not greater as the height."
        bmk = pdf.AddBookmarkA("DestType: dtFitV_Left (200)", root, 6, 0)
        pdf.SetBookmarkDest bmk, dtFitV_Left, 200, 0, 0, 0
        pdf.SetBookmarkStyle bmk, fsRegular, &H808FFF
    pdf.EndPage

    pdf.Append
        pdf.ChangeFont f
        pdf.WriteText 50, 50, "Bookmark destination type dtFit_Rect"
        x = (pdf.GetPageWidth - 90) / 2
        y = (pdf.GetPageHeight - 65) / 2
        pdf.WriteFTextEx x, y, 90, -1, taCenter, "We zoom into the rectangle"
        pdf.Rectangle x, y, 90, 65, fmStroke

        ' A page link with a GoTo action that zooms into the rectangle in the same way as the bookmark.
        pdf.SetLinkHighlightMode hmInvert
        lnk = pdf.PageLink(x, y, 90, 65, 7)
        act = pdf.CreateGoToAction(dtFit_Rect, 7, x - 5, y - 5, x + 100, y + 70)
        pdf.AddActionToObj otPageLink, oeOnMouseUp, act, lnk

        bmk = pdf.AddBookmarkA("DestType: dtFit_Rect", -1, 7, 0)
        pdf.AddActionToObj otBookmark, oeOnMouseUp, act, bmk
        pdf.SetBookmarkStyle bmk, fsRegular, &H80FF
    pdf.EndPage

    pdf.SetPageFormat pfDIN_A4
    pdf.Append
        pdf.ChangeFont f
        pdf.WriteFTextEx 50, 50, pdf.GetPageWidth - 100, -1, taLeft, "Destination type dtFit. This variant scales the page so that both sides fit into the viewer window."
    pdf.EndPage

    root = pdf.AddBookmarkA("DestType dtFit", -1, 8, 0)
    pdf.SetBookmarkDest root, dtFit, 0, 0, 0, 0

    bmk = pdf.AddBookmarkA("DestType: dtXY_Zoom, zoom factor 3", root, 2, 0)
    pdf.SetBookmarkDest bmk, dtXY_Zoom, 50, 50, 3, 0
    pdf.SetBookmarkStyle bmk, fsBold, clMaroon

    pdf.SetPageLayout plOneColumn

    If pdf.HaveOpenDoc <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile <> 0 Then Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If
End Sub

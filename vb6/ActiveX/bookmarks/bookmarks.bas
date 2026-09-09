Attribute VB_Name = "modBookmarks"
Option Explicit
' ============================================================================
'  bookmarks -- LumasPdf ActiveX/COM component style (late-bound, no project
'  reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\bookmarks -- same feature: demonstrates the various bookmark
'  destination types (dtFit, dtXY_Zoom, dtFitH_Top, dtFitV_Left, dtFit_Rect)
'  plus a page link with a GoTo action.
'
'  Enum values below are hand-transcribed from wrappers\vb6\LumasPDFInt.bas
'  (the ActiveX server shares the same native enums, but late binding means
'  no typelib constants are available -- see the "cp1252 = 2" etc. note in
'  NorthwindMegaDemo.bas). VCL TColor literals (COLORREF) are not engine
'  enums either way.
' ============================================================================

' VCL TColor values (COLORREF, R in low byte) used by SetBookmarkStyle.
Private Const clRed    As Long = &HFF&
Private Const clGreen  As Long = &H8000&
Private Const clBlue   As Long = &HFF0000
Private Const clMaroon As Long = &H80&

'--- TPageCoord ---------------------------------------------------------------
Const pcTopDown As Long = 1

'--- TFStyle --------------------------------------------------------------------
Const fsRegular As Long = &H19000000
Const fsItalic As Long = 1
Const fsBold As Long = &H2BC00000

'--- TCodepage (index 2 = cp1252) -----------------------------------------------
Const cp1252 As Long = 2

'--- TTextAlign -----------------------------------------------------------------
Const taLeft As Long = 0
Const taCenter As Long = 1

'--- TPathFillMode (fmStroke = 4) ----------------------------------------------
Const fmStroke As Long = 4

'--- TDestType ------------------------------------------------------------------
Const dtXY_Zoom As Long = 0
Const dtFit As Long = 1
Const dtFitH_Top As Long = 2
Const dtFitV_Left As Long = 3
Const dtFit_Rect As Long = 4

'--- THighlightMode -------------------------------------------------------------
Const hmInvert As Long = 1

'--- TObjType / TObjEvent --------------------------------------------------------
Const otBookmark As Long = 2
Const otPageLink As Long = 6
Const oeOnMouseUp As Long = 3

'--- TPageFormat (pfDIN_A4 = 1) / TPageLayout (plOneColumn = 1) ------------------
Const pfDIN_A4 As Long = 1
Const plOneColumn As Long = 1

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim act As Long, lnk As Long, f As Long, bmk As Long, root As Long
    Dim x As Double, y As Double, outFile As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    pdf.CreateNewPDFW ""

    pdf.SetPageCoords pcTopDown
    pdf.SetPageHeight 500
    pdf.SetPageWidth 800

    pdf.Append
        f = pdf.SetFontW("Helvetica", fsRegular, 20, False, cp1252)
        pdf.WriteTextW 50, 50, "Bookmark destination type dtFit"
        root = pdf.AddBookmarkA("DestType dtFit", -1, 1, 1)
        pdf.SetBookmarkDest root, dtFit, 0, 0, 0, 0
        pdf.SetBookmarkStyle root, fsItalic, clRed
    pdf.EndPage

    pdf.Append
        pdf.ChangeFont f
        pdf.WriteTextW 50, 50, "Bookmark destination type dtXY_Zoom"
        pdf.WriteTextW 50, 70, "Zoom factor 3, Top position 50 (TopDown coordinates)"
        bmk = pdf.AddBookmarkA("DestType: dtXY_Zoom, zoom factor 3", root, 2, 0)
        pdf.SetBookmarkDest bmk, dtXY_Zoom, 50, 50, 3, 0
        pdf.SetBookmarkStyle bmk, fsBold, clMaroon
    pdf.EndPage

    pdf.Append
        pdf.ChangeFont f
        pdf.WriteTextW 50, 50, "Bookmark destination type dtXY_Zoom"
        pdf.WriteTextW 50, 70, "Zoom factor 0.5, Top position 50 (TopDown coordinates)"
        bmk = pdf.AddBookmarkA("DestType: dtXY_Zoom, zoom factor 0.5", root, 3, 0)
        pdf.SetBookmarkDest bmk, dtXY_Zoom, 50, 50, 0.5, 0
        pdf.SetBookmarkStyle bmk, fsBold Or fsItalic, clGreen
    pdf.EndPage

    pdf.Append
        pdf.ChangeFont f
        pdf.WriteTextW 50, 50, "Bookmark destination type dtXY_Zoom"
        pdf.WriteTextW 50, 70, "Zoom factor not defined (unchanged), Top position 50 (TopDown coordinates)"
        bmk = pdf.AddBookmarkA("DestType: dtXY_Zoom, zoom factor unchanged", root, 4, 0)
        pdf.SetBookmarkDest bmk, dtXY_Zoom, 50, 50, 0, 0
        pdf.SetBookmarkStyle bmk, fsRegular, clBlue
    pdf.EndPage

    pdf.Append
        pdf.ChangeFont f
        pdf.WriteTextW 50, 50, "Bookmark destination type dtFitH_Top"
        pdf.WriteTextW 50, 70, "Top position 50 (TopDown coordinates)"
        bmk = pdf.AddBookmarkA("DestType: dtFitH_Top (50)", root, 5, 0)
        pdf.SetBookmarkDest bmk, dtFitH_Top, 50, 0, 0, 0
        pdf.SetBookmarkStyle bmk, fsRegular, &HFF8080
        pdf.WriteTextW 50, 200, "Bookmark destination type dtFitH_Top"
        pdf.WriteTextW 50, 220, "Top position 200 (TopDown coordinates)"
        bmk = pdf.AddBookmarkA("DestType dtFitH_Top (200)", root, 5, 0)
        pdf.SetBookmarkDest bmk, dtFitH_Top, 200, 0, 0, 0
        pdf.SetBookmarkStyle bmk, fsRegular, &HC08080
    pdf.EndPage

    pdf.Append
        pdf.ChangeFont f
        pdf.WriteTextW 200, 50, "Bookmark destination type dtFitV_Left"
        pdf.WriteTextW 200, 70, "Left position 200. FitV has no effect if the width of the page"
        pdf.WriteTextW 200, 90, "is not greater as the height."
        bmk = pdf.AddBookmarkA("DestType: dtFitV_Left (200)", root, 6, 0)
        pdf.SetBookmarkDest bmk, dtFitV_Left, 200, 0, 0, 0
        pdf.SetBookmarkStyle bmk, fsRegular, &H808FFF
    pdf.EndPage

    pdf.Append
        pdf.ChangeFont f
        pdf.WriteTextW 50, 50, "Bookmark destination type dtFit_Rect"
        x = (pdf.GetPageWidth - 90) / 2
        y = (pdf.GetPageHeight - 65) / 2
        pdf.WriteFTextExW x, y, 90, -1, taCenter, "We zoom into the rectangle"
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
        pdf.WriteFTextExW 50, 50, pdf.GetPageWidth - 100, -1, taLeft, "Destination type dtFit. This variant scales the page so that both sides fit into the viewer window."
    pdf.EndPage

    root = pdf.AddBookmarkA("DestType dtFit", -1, 8, 0)
    pdf.SetBookmarkDest root, dtFit, 0, 0, 0, 0

    bmk = pdf.AddBookmarkA("DestType: dtXY_Zoom, zoom factor 3", root, 2, 0)
    pdf.SetBookmarkDest bmk, dtXY_Zoom, 50, 50, 3, 0
    pdf.SetBookmarkStyle bmk, fsBold, clMaroon

    pdf.SetPageLayout plOneColumn

    If pdf.HaveOpenDoc Then
        outFile = App.Path & "\out.pdf"
        If Not pdf.OpenOutputFileW(outFile) Then Exit Sub
        If pdf.CloseFile Then Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "bookmarks (ActiveX)"
End Sub

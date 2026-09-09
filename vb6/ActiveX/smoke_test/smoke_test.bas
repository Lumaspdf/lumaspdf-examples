Attribute VB_Name = "modSmoke"
Option Explicit
' ============================================================================
'  smoke_test -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\smoke_test -- same feature: the server creates a PDF with
'  text, a red rectangle and a bookmark.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF(outFile) -> pdf.CreateNewPDFW(outFile)
'    pdf.SetDocInfoA(...)      -> pdf.SetDocInfoW(...)
'    pdf.SetFont(...)          -> pdf.SetFontW(...)   (Embed as VARIANT_BOOL)
'    pdf.WriteText(...)        -> pdf.WriteTextW(...)
'    pdf.AddBookmarkA(...)     -> pdf.AddBookmarkW(...)
' ============================================================================

'--- TFStyle --------------------------------------------------------------------------
Const fsRegular As Long = &H19000000

'--- TCodepage (index 2 = cp1252) ------------------------------------------------------
Const cp1252 As Long = 2

'--- TDocumentInfo ----------------------------------------------------------------------
Const diTitle As Long = 5

'--- TPathFillMode (fmFill = 3, not 0) ---------------------------------------------------
Const fmFill As Long = 3

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim outFile As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True            ' turn engine errors into VB6 errors

    outFile = App.Path & "\smoke_out.pdf"

    If Not CBool(pdf.CreateNewPDFW(outFile)) Then
        Debug.Print "CreateNewPDFW failed"
        Exit Sub
    End If

    pdf.SetDocInfoW diTitle, "LumasPdf ActiveX example-mirror smoke test"
    pdf.Append
    pdf.SetFontW "Arial", fsRegular, 24#, True, cp1252
    pdf.WriteTextW 50, 700, "Examples run on the LumasPdf ActiveX server"
    pdf.SetFillColor 255                      ' red (COLORREF, R in low byte)
    pdf.Rectangle 50, 500, 200, 100, fmFill
    pdf.AddBookmarkW "First page", -1, 1, 0
    pdf.EndPage

    If Not CBool(pdf.CloseFile()) Then
        Debug.Print "CloseFile failed"
        Exit Sub
    End If

    Debug.Print "OK: " & outFile
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "smoke_test (ActiveX)"
End Sub

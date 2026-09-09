Attribute VB_Name = "modSmoke"
Option Explicit
' ============================================================================
'  smoke_test -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp): the
'  OO object and ALL enums (fsRegular, cp1252, diTitle, fmFill) come from the
'  typelib -- no LumasPdf.bas, no flat Declares. Errors surface as VB6
' pdf.RaiseExceptions = True
'  server drives the engine: creates a PDF with text, a red rectangle and a
'  bookmark.
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim outFile As String
' pdf.RaiseExceptions = True

    outFile = App.Path & "\smoke_out.pdf"

    If pdf.CreateNewPDF(outFile) = 0 Then
        Debug.Print "CreateNewPDF failed"
        Exit Sub
    End If

    pdf.SetDocInfoA diTitle, "LumasPdf example-mirror smoke test"
    pdf.Append
    pdf.SetFont "Arial", fsRegular, 24#, True, cp1252
    pdf.WriteText 50, 700, "Examples run on the LumasPdf ActiveX server"
    pdf.SetFillColor 255                      ' red (COLORREF, R in low byte)
    pdf.Rectangle 50, 500, 200, 100, fmFill
    pdf.AddBookmarkA "First page", -1, 1, 0
    pdf.EndPage

    If pdf.CloseFile() = 0 Then
        Debug.Print "CloseFile failed"
        Exit Sub
    End If

    Debug.Print "OK: " & outFile
End Sub

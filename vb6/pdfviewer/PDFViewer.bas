Attribute VB_Name = "modPDFViewer"
Option Explicit
' ============================================================================
'  PDFViewer -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Opens 18_invoice.pdf in the SDK's EMBEDDED viewer window. The COM object
'  exposes the flat viewer export as a method: VwrShowFileW(FileName, Title).
'  Automation marshals the two VB Unicode strings directly -- no StrPtr needed.
'  The call BLOCKS until the user closes the window (8s-timeout run = PASS).
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim pdfPath As String, title As String, ok As Long

    ' 18_invoice.pdf sits next to the exe (copied from ..\reporting\18_invoice.pdf).
    pdfPath = App.Path & "\18_invoice.pdf"
    title = "18_invoice.pdf - LumasPDF embedded preview"

    If Dir(pdfPath) = "" Then
        MsgBox "Not found: " & pdfPath, vbExclamation, "PDFViewer"
        Exit Sub
    End If

    ' Open the embedded viewer. Blocks until the window is closed.
    ok = vwrShowFileW(pdfPath), StrPtr(title))

    If ok = 0 Then
        MsgBox "The embedded viewer could not be shown for:" & vbCrLf & pdfPath, _
               vbExclamation, "PDFViewer"
    End If
End Sub

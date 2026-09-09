Attribute VB_Name = "modPDFViewer"
Option Explicit
' ============================================================================
'  PDFViewer -- LumasPdf ActiveX/COM component style (late-bound, no project
'  reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\pdfviewer -- same feature: open 18_invoice.pdf in the SDK's
'  EMBEDDED viewer window.
'
'  Method mapping vs. the CPDF.cls reference: the flat export
'  vwrShowFileW(FileName, Title) is exposed on the ActiveX component as the
'  instance method VwrShowFileW(FileName, Title) -- BSTR/BSTR in, VARIANT_BOOL
'  out; Automation marshals the two VB strings directly, no StrPtr needed.
'  The call BLOCKS until the user closes the window.
' ============================================================================

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim pdfPath As String, title As String
    Dim ok As Boolean

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True            ' turn engine errors into VB6 errors

    ' 18_invoice.pdf sits next to the exe (copied from ..\reporting\18_invoice.pdf).
    pdfPath = App.Path & "\18_invoice.pdf"
    title = "18_invoice.pdf - LumasPDF ActiveX embedded preview"

    If Dir(pdfPath) = "" Then
        MsgBox "Not found: " & pdfPath, vbExclamation, "PDFViewer (ActiveX)"
        Exit Sub
    End If

    ' Open the embedded viewer. Blocks until the window is closed.
    ok = CBool(pdf.VwrShowFileW(pdfPath, title))

    If Not ok Then
        MsgBox "The embedded viewer could not be shown for:" & vbCrLf & pdfPath, _
               vbExclamation, "PDFViewer (ActiveX)"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "PDFViewer (ActiveX)"
End Sub

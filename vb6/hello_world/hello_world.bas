Attribute VB_Name = "modHelloWorld"
Option Explicit
' ============================================================================
'  hello_world -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp):
'  the OO object, ALL enums (fsItalic, cp1252, taCenter) AND ALL constants
'  (colors, RPT_EXP_*, NO_COLOR, ...) come straight from the typelib -- no
'  LumasPdf.bas, no flat Declares. Errors surface as VB6 exceptions via
' pdf.RaiseExceptions = True
'  but the OO surface is the registered COM server, not a hand-written class).
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim outFile As String, cr As String
    cr = Chr(13)
' pdf.RaiseExceptions = True

    pdf.CreateNewPDF ""
    pdf.SetDocInfoA diCreator, "Delphi Example project"
    pdf.SetDocInfoA diTitle, "My first PDF output"

    pdf.Append
    pdf.SetFont "Arial", fsItalic, 30#, True, cp1252
    pdf.WriteFText taCenter, "My first PDF output..." & cr & cr & CStr(Now)
    pdf.EndPage

    outFile = App.Path & "\out.pdf"
    pdf.OpenOutputFile outFile
    pdf.CloseFile
    Debug.Print "OK: " & outFile
End Sub

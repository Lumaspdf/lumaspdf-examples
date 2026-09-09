Attribute VB_Name = "modHelloWorld"
Option Explicit
' ============================================================================
'  hello_world -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example
'  at examples\Vb6\hello_world -- same feature: create a one-page PDF with
'  document info + a centered italic headline and a timestamp.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same
'  names, just late-bound to the registered "LumasPdf.PDF" COM server
'  instead of the native wrapper class):
'    pdf.CreateNewPDF ""        -> pdf.CreateNewPDFW ""
'    pdf.SetDocInfoA d, v       -> pdf.SetDocInfoW d, v
'    pdf.SetFont ...            -> pdf.SetFontW ...
'    pdf.WriteFText ...         -> pdf.WriteFTextW ...
' ============================================================================

'--- TFStyle bits (see src\Lumas.Pdf.Types.pas) --------------------------------
Const FS_ITALIC As Long = 1

'--- TTextAlign -----------------------------------------------------------------
Const taCenter As Long = 1

'--- TCodepage (index 2 = cp1252) -----------------------------------------------
Const CP_1252 As Long = 2

'--- TDocumentInfo ---------------------------------------------------------------
Const diCreator As Long = 1
Const diTitle As Long = 5

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim outFile As String, cr As String
    cr = Chr(13)

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True            ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""
    pdf.SetDocInfoW diCreator, "Delphi Example project"
    pdf.SetDocInfoW diTitle, "My first PDF output"

    pdf.Append
    pdf.SetFontW "Arial", FS_ITALIC, 30#, True, CP_1252
    pdf.WriteFTextW taCenter, "My first PDF output..." & cr & cr & CStr(Now)
    pdf.EndPage

    outFile = App.Path & "\out.pdf"
    pdf.OpenOutputFileW outFile
    pdf.CloseFile
    Debug.Print "OK: " & outFile
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "hello_world (ActiveX)"
End Sub

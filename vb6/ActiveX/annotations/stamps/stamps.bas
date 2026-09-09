Attribute VB_Name = "modStamps"
Option Explicit
' ============================================================================
'  stamps -- LumasPdf ActiveX/COM component style (late-bound, no project
'  reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\annotations\stamps -- same feature: a pre-defined "Approved"
'  rubber stamp annotation rendered in English, German and French (the
'  stamp's language is switched with SetLanguage right before each
'  StampAnnotA call).
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF ""    -> pdf.CreateNewPDFW ""
'    pdf.StampAnnotA ...    -> pdf.StampAnnotA ...   (kept -- explicit A in reference)
'    pdf.OpenOutputFile ... -> pdf.OpenOutputFileW ...
'  All other calls (SetAnnotColor, SetLanguage, SetPageCoords, Append,
'  EndPage, HaveOpenDoc, CloseFile) map 1:1, just with the instance handle
'  dropped.
' ============================================================================

'--- TPageCoord --------------------------------------------------------------------
Const pcTopDown As Long = 1

'--- TPDFColorSpace ------------------------------------------------------------------
Const csDeviceRGB As Long = 0

'--- TFieldColor (reused for annotation color type: border color) ---------------------
Const fcBorderColor As Long = 1

'--- TRubberStamp ---------------------------------------------------------------------
Const rsApproved As Long = 0

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim a As Long
    Dim outFile As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""

    pdf.SetPageCoords pcTopDown

    pdf.Append

    ' A pre-defined stamp is scaled to the given width. The language can be set right before creating the stamp.
    a = pdf.StampAnnotA(rsApproved, 135#, 50#, 300#, 10#, "Test app", "Stamp Annotations", "The default language is English!")
    pdf.SetAnnotColor a, fcBorderColor, csDeviceRGB, RGB(120, 190, 92)

    pdf.SetLanguage "DE"
    a = pdf.StampAnnotA(rsApproved, 135#, 150#, 300#, 10#, "Test app", "Stamp Annotations", "The same stamp in German!")
    pdf.SetAnnotColor a, fcBorderColor, csDeviceRGB, RGB(230, 65, 132)

    pdf.SetLanguage "FR"
    a = pdf.StampAnnotA(rsApproved, 135#, 250#, 300#, 10#, "Test app", "Stamp Annotations", "The same stamp in French!")
    pdf.SetAnnotColor a, fcBorderColor, csDeviceRGB, RGB(78, 157, 232)
    pdf.EndPage

    If CBool(pdf.HaveOpenDoc()) Then
        outFile = App.Path & "\out.pdf"
        pdf.OpenOutputFileW outFile
        pdf.CloseFile
        Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "stamps (ActiveX)"
End Sub

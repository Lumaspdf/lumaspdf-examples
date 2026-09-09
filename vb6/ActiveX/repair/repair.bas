Attribute VB_Name = "modRepair"
Option Explicit
' ============================================================================
'  repair -- LumasPdf ActiveX/COM component style (late-bound, no project
'  reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\repair (itself a VB6 mirror of examples\c\repair\repair.c).
'  Fixes a damaged PDF with a SINGLE method: ConvertFile(..., ctNormalize).
'
'  Method mapping vs. the CPDF.cls/global-proc reference: VB6/COM cannot pass
'  native callback pointers, so ConvertFile is exposed on the ActiveX
'  component as the 7-arg instance method ending at OwnerPwd (the instance
'  handle and the 3 trailing callback-pointer args of the flat
'  pdfConvertFileA export are dropped):
'    pdfConvertFileA(pdf.GetInstancePtr(), InFile, OutFile, ctNormalize, 0, "", "", "", 0, 0, 0)
'      -> pdf.ConvertFile(InFile, OutFile, ctNormalize, 0, "", "", "")
'
'  A compiled GUI exe has no stdout, so the rc/repair-mode line is written to
'  result.txt (and Debug.Print'd in the IDE). Run the exe FROM this folder so
'  the ../../../test_files/... relative path resolves (this project lives one
'  level deeper than the flat-DLL original, under Vb6\ActiveX\repair\).
' ============================================================================

'--- TConformanceType (subset used) ---------------------------------------------------
Const ctNormalize As Long = 1

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim rc As Long, repairMode As Boolean, msg As String, f As Integer

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True            ' turn engine errors into VB6 errors

    ' ctNormalize ; "" for RGBProfile / CMYKProfile / OwnerPwd (not needed to repair)
    rc = pdf.ConvertFile("../../../test_files/corrupt.pdf", "repaired.pdf", ctNormalize, 0, "", "", "")
    repairMode = CBool(pdf.GetInRepairMode)

    msg = "ConvertFile(ctNormalize) rc=" & rc & "  (repair-mode used: " & repairMode & ")"
    Debug.Print msg
    f = FreeFile
    Open App.Path & "\result.txt" For Output As #f
    Print #f, msg
    Close #f
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "repair (ActiveX)"
End Sub

Attribute VB_Name = "modRepair"
Option Explicit
' ============================================================================
'  repair -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules (VB6 mirror of
'  examples\c\repair\repair.c). Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt)
'  (one Reference in the .vbp): the OO object AND all enums (ctNormalize)
'  come straight from the typelib. Fixes a damaged PDF with a SINGLE method:
'  ConvertFile(..., ctNormalize). VB6/COM cannot pass native callback pointers,
'  so ConvertFile is the 7-arg form ending at OwnerPwd. Errors surface as VB6
' pdf.RaiseExceptions = True
'  A compiled GUI exe has no stdout, so the rc/repair-mode line is written to
'  result.txt (and Debug.Print'd in the IDE). Run the exe FROM this folder so
'  the ../../test_files/... relative paths resolve.
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim rc As Long, repairMode As Long, msg As String, f As Integer
' pdf.RaiseExceptions = True

    ' ctNormalize ; "" for RGBProfile / CMYKProfile / OwnerPwd (not needed to repair)
    rc = pdfConvertFileA(pdf.GetInstancePtr(), "../../test_files/corrupt.pdf", "repaired.pdf", ctNormalize, 0, "", "", "", 0, 0, 0)
    repairMode = pdf.GetInRepairMode

    msg = "ConvertFile(ctNormalize) rc=" & rc & "  (repair-mode used: " & repairMode & ")"
    Debug.Print msg
    f = FreeFile
    Open App.Path & "\result.txt" For Output As #f
    Print #f, msg
    Close #f
End Sub

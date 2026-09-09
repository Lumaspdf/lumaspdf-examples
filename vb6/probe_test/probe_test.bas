Attribute VB_Name = "modProbeTest"
Option Explicit
' ============================================================================
'  probe_test -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Step-by-step probe of the TPDF flow (in-memory CreateNewPDF + OpenOutputFile
'  at the end + a table via the Tbl* methods). Error callback replaced by
' pdf.RaiseExceptions = True
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim tbl As Variant, r As Long
    Dim outFile As String
' pdf.RaiseExceptions = True

    Debug.Print "Create ok"
    Debug.Print "CreateNewPDF('') = " & pdf.CreateNewPDF("")
    Debug.Print "SetPageCoords = " & pdf.SetPageCoords(pcTopDown)
    Debug.Print "Append = " & pdf.Append
    Debug.Print "SetFont = " & pdf.SetFont("Arial", fsRegular, 12#, 1, cp1252)
    Debug.Print "WriteText = " & pdf.WriteText(50, 50, "probe")

    tbl = tblCreateTable(pdf.GetInstancePtr(), 3, 3, 500!, 100!)
    Debug.Print "Table created"
    r = tblAddRow(tbl, -1!)
    Debug.Print "AddRow = " & r
    ' Pass the real string length (not -1): the AX marshaller passes a WideString,
    ' so Len=-1 makes the engine over-read (access violation).
    Debug.Print "SetCellText = " & tblSetCellTextA(tbl, r, 0, taLeft, coTop, "cell", Len("cell"))
    Debug.Print "DrawTable = " & tblDrawTable(tbl, 50!, 80!, 700!)
    Debug.Print "HaveMore = " & tblHaveMore(tbl)
    tblDeleteTable tbl

    Debug.Print "EndPage = " & pdf.EndPage
    Debug.Print "GetPageCount = " & pdf.GetPageCount()
    Debug.Print "HaveOpenDoc = " & pdf.HaveOpenDoc
    outFile = App.Path & "\probe_out.pdf"
    Debug.Print "OpenOutputFile = " & pdf.OpenOutputFile(outFile)
    Debug.Print "CloseFile = " & pdf.CloseFile
End Sub

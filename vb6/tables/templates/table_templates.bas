Attribute VB_Name = "modTableTemplates"
Option Explicit
' ============================================================================
'  table_templates -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp); enums
'  (pcTopDown, if2UseProxy, ptOpen, coCenter, tbpBorderWidth, tbpCellPadding,
'  pfUS_Letter) come from the typelib. The flat tbl*/pdf* exports map to
'  tbl*/pdf.* methods (drop the handle first-arg; the table handle stays an
'  explicit arg). Imports every page of sample_multipage.pdf as a template and lays
'  them two per row in a table (tfScaleToRect), then draws the table across as
'  many output pages as needed. The error callback and the record-based
' pdf.RaiseExceptions = True
' ============================================================================

' Table flag not exposed by the type library (from LumasPdf.pas):
Private Const tfScaleToRect As Long = &H8&

Public Sub Main()
    Dim pdf As New CPDF
    Dim tbl As Long, delH As Variant
    Dim outFile As String
    Dim timeStart As Single
    Dim i As Long, pageCount As Long, tmpl As Long, rowNum As Long
' pdf.RaiseExceptions = True

    timeStart = Timer

    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown

    pdf.SetImportFlags2 if2UseProxy    ' Reduce the memory usage

    pdf.OpenImportFile App.Path & "\..\..\..\..\sample_multipage.pdf", ptOpen, ""

    pageCount = pdf.GetInPageCount()
    If pageCount < 1 Then
        Debug.Print "Help file not found!"
        Exit Sub
    End If

    tbl = tblCreateTable(pdf.GetInstancePtr(), pageCount \ 4 + 1, 2, 512.12, 0#)
    tblSetBoxProperty tbl, -1, -1, tbpBorderWidth, 1#, 1#, 1#, 1#
    tblSetBoxProperty tbl, -1, -1, tbpCellPadding, 5#, 5#, 5#, 5#
    tblSetGridWidth tbl, 1#, 1#
    tblSetFlags tbl, -1, -1, tfScaleToRect

    pdf.SetPageFormat pfUS_Letter

    rowNum = 0
    For i = 1 To pageCount
        tmpl = pdf.ImportPage(i)
        If (i And 1) <> 0 Then rowNum = tblAddRow(tbl, 335#)
        tblSetCellTemplate tbl, rowNum, (i - 1) And 1, True, coCenter, coCenter, tmpl, 0#, 0#
    Next i

    ' Draw the table now
    pdf.Append
    tblDrawTable tbl, 50#, 50#, 742#
    Do While tblHaveMore(tbl)
        pdf.EndPage
        pdf.Append
        tblDrawTable tbl, 50#, 50#, 742#
    Loop
    pdf.EndPage

    delH = tbl
    tblDeleteTable delH

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "Processing time: " & Format$((Timer - timeStart) * 1000, "0") & " ms"
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

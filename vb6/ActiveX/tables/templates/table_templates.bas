Attribute VB_Name = "modTableTemplates"
Option Explicit
' ============================================================================
'  table_templates -- ActiveX/COM version (LumasPdf.PDF, late-bound), mirrors
'  the plain-DLL example at examples\Vb6\tables\templates (read-only
'  reference, not modified). Imports every page of dynapdf_help.pdf as a
'  template and lays them two per row in a table (tfScaleToRect), then draws
'  the table across as many output pages as needed.
' ============================================================================

' Table flag not exposed by a type library reference (from dynapdf.pas):
Private Const tfScaleToRect As Long = &H8&

Private Const coCenter As Long = 2
Private Const tbpBorderWidth As Long = 0
Private Const tbpCellPadding As Long = 2
Private Const pcTopDown As Long = 1
Private Const if2UseProxy As Long = &H4
Private Const ptOpen As Long = 0
Private Const pfUS_Letter As Long = 19

Public Sub Main()
    Dim pdf As Object
    Dim tbl As Long, delH As Variant
    Dim outFile As String
    Dim timeStart As Single
    Dim i As Long, pageCount As Long, tmpl As Long, rowNum As Long

    On Error GoTo ErrHandler
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    timeStart = Timer

    pdf.CreateNewPDFA ""

    pdf.SetPageCoords pcTopDown

    pdf.SetImportFlags2 if2UseProxy    ' Reduce the memory usage

    pdf.OpenImportFileA App.path & "\..\..\..\..\..\dynapdf_help.pdf", ptOpen, ""

    pageCount = pdf.GetInPageCount()
    If pageCount < 1 Then
        Debug.Print "Help file not found!"
        Exit Sub
    End If

    tbl = pdf.TblCreateTable(pageCount \ 4 + 1, 2, 512.12, 0#)
    pdf.TblSetBoxProperty tbl, -1, -1, tbpBorderWidth, 1#, 1#, 1#, 1#
    pdf.TblSetBoxProperty tbl, -1, -1, tbpCellPadding, 5#, 5#, 5#, 5#
    pdf.TblSetGridWidth tbl, 1#, 1#
    pdf.TblSetFlags tbl, -1, -1, tfScaleToRect

    pdf.SetPageFormat pfUS_Letter

    rowNum = 0
    For i = 1 To pageCount
        tmpl = pdf.ImportPage(i)
        If (i And 1) <> 0 Then rowNum = pdf.TblAddRow(tbl, 335#)
        pdf.TblSetCellTemplate tbl, rowNum, (i - 1) And 1, True, coCenter, coCenter, tmpl, 0#, 0#
    Next i

    ' Draw the table now
    pdf.Append
    pdf.TblDrawTable tbl, 50#, 50#, 742#
    Do While pdf.TblHaveMore(tbl)
        pdf.EndPage
        pdf.Append
        pdf.TblDrawTable tbl, 50#, 50#, 742#
    Loop
    pdf.EndPage

    delH = tbl
    pdf.TblDeleteTable delH

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() Then
        outFile = App.path & "\out.pdf"
        If Not pdf.OpenOutputFileA(outFile) Then Exit Sub
        If pdf.CloseFile() Then
            Debug.Print "Processing time: " & Format$((Timer - timeStart) * 1000, "0") & " ms"
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "table_templates"
End Sub

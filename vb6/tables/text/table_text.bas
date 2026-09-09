Attribute VB_Name = "modTableText"
Option Explicit
' ============================================================================
'  table_text -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp): the OO
'  object, ALL enums (fsRegular, cp1252, taLeft, tbpBorderWidth, ...) come from the
'  typelib. The flat tbl*/pdf* exports map to tbl*/pdf.* methods (drop the
'  handle first-arg; the table handle stays an explicit arg). The error callback
'  and the record-based error-log dump are dropped; errors surface via exceptions.
'  Builds a 3x3 cell-alignment table, draws it, then redraws it at 90-degree cell
'  orientation.
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim tbl As Long, rowNum As Long
    Dim outFile As String, txt As String
    Dim delH As Variant

' pdf.RaiseExceptions = True

    pdf.CreateNewPDF ""
    pdf.SetPageCoords pcTopDown

    tbl = tblCreateTable(pdf.GetInstancePtr(), 3, 3, 500#, 100#)
    tblSetBoxProperty tbl, -1, -1, tbpBorderWidth, 1#, 1#, 1#, 1#
    tblSetFontA tbl, -1, -1, "Arial", fsRegular, True, cp1252
    tblSetFontA tbl, -1, 1, "Arial", fsBold, True, cp1252
    tblSetGridWidth tbl, 1#, 1#

    txt = "The cell alignment can be set for text, images, and templates..."

    ' -1.0 means use the default row height as specified in the CreateTable() call.
    rowNum = tblAddRow(tbl, -1#)
    tblSetCellTextA tbl, rowNum, 0, taLeft, coTop, txt, -1
    tblSetCellTextA tbl, rowNum, 1, taCenter, coTop, txt, -1
    tblSetCellTextA tbl, rowNum, 2, taRight, coTop, txt, -1

    rowNum = tblAddRow(tbl, -1#)
    tblSetCellTextA tbl, rowNum, 0, taLeft, coCenter, txt, -1
    tblSetCellTextA tbl, rowNum, 1, taCenter, coCenter, txt, -1
    tblSetCellTextA tbl, rowNum, 2, taRight, coCenter, txt, -1

    rowNum = tblAddRow(tbl, -1#)
    tblSetCellTextA tbl, rowNum, 0, taLeft, coBottom, txt, -1
    tblSetCellTextA tbl, rowNum, 1, taCenter, coBottom, txt, -1
    tblSetCellTextA tbl, rowNum, 2, taRight, coBottom, txt, -1

    ' Draw the table now
    pdf.Append
    tblDrawTable tbl, 50#, 50#, 742#
    Do While tblHaveMore(tbl)
        pdf.EndPage
        pdf.Append
        tblDrawTable tbl, 50#, 50#, 742#
    Loop
    pdf.EndPage

    ' Let's change the cell orientation to see what happens...
    tblSetCellOrientation tbl, -1, -1, 90
    pdf.Append
    pdf.SetFont "Arial", fsRegular, 12#, True, cp1252
    pdf.WriteText 50#, 50#, "The same table but the cell orientation was changed to 90 degrees."

    tblDrawTable tbl, 50#, 65#, 742#
    Do While tblHaveMore(tbl)
        pdf.EndPage
        pdf.Append
        tblDrawTable tbl, 50#, 50#, 737#
    Loop
    pdf.EndPage

    delH = tbl
    tblDeleteTable delH               ' frees the table and sets the handle to 0

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

Attribute VB_Name = "modTableText"
Option Explicit
' ============================================================================
'  table_text -- ActiveX/COM version (LumasPdf.PDF, late-bound), mirrors the
'  plain-DLL example at examples\Vb6\tables\text (read-only reference, not
'  modified). Builds a 3x3 cell-alignment table, draws it, then redraws it at
'  90-degree cell orientation.
' ============================================================================

Private Const taLeft As Long = 0
Private Const taCenter As Long = 1
Private Const taRight As Long = 2
Private Const coTop As Long = 0
Private Const coCenter As Long = 2
Private Const coBottom As Long = 1
Private Const tbpBorderWidth As Long = 0
Private Const fsRegular As Long = &H19000000
Private Const fsBold As Long = &H2BC00000
Private Const cp1252 As Long = 2
Private Const pcTopDown As Long = 1

Public Sub Main()
    Dim pdf As Object
    Dim tbl As Long, rowNum As Long
    Dim outFile As String, txt As String
    Dim delH As Variant

    On Error GoTo ErrHandler
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    pdf.CreateNewPDFA ""
    pdf.SetPageCoords pcTopDown

    tbl = pdf.TblCreateTable(3, 3, 500#, 100#)
    pdf.TblSetBoxProperty tbl, -1, -1, tbpBorderWidth, 1#, 1#, 1#, 1#
    pdf.TblSetFontA tbl, -1, -1, "Arial", fsRegular, True, cp1252
    pdf.TblSetFontA tbl, -1, 1, "Arial", fsBold, True, cp1252
    pdf.TblSetGridWidth tbl, 1#, 1#

    txt = "The cell alignment can be set for text, images, and templates..."

    ' -1.0 means use the default row height as specified in the CreateTable() call.
    rowNum = pdf.TblAddRow(tbl, -1#)
    pdf.TblSetCellTextA tbl, rowNum, 0, taLeft, coTop, txt, -1
    pdf.TblSetCellTextA tbl, rowNum, 1, taCenter, coTop, txt, -1
    pdf.TblSetCellTextA tbl, rowNum, 2, taRight, coTop, txt, -1

    rowNum = pdf.TblAddRow(tbl, -1#)
    pdf.TblSetCellTextA tbl, rowNum, 0, taLeft, coCenter, txt, -1
    pdf.TblSetCellTextA tbl, rowNum, 1, taCenter, coCenter, txt, -1
    pdf.TblSetCellTextA tbl, rowNum, 2, taRight, coCenter, txt, -1

    rowNum = pdf.TblAddRow(tbl, -1#)
    pdf.TblSetCellTextA tbl, rowNum, 0, taLeft, coBottom, txt, -1
    pdf.TblSetCellTextA tbl, rowNum, 1, taCenter, coBottom, txt, -1
    pdf.TblSetCellTextA tbl, rowNum, 2, taRight, coBottom, txt, -1

    ' Draw the table now
    pdf.Append
    pdf.TblDrawTable tbl, 50#, 50#, 742#
    Do While pdf.TblHaveMore(tbl)
        pdf.EndPage
        pdf.Append
        pdf.TblDrawTable tbl, 50#, 50#, 742#
    Loop
    pdf.EndPage

    ' Let's change the cell orientation to see what happens...
    pdf.TblSetCellOrientation tbl, -1, -1, 90
    pdf.Append
    pdf.SetFontA "Arial", fsRegular, 12#, True, cp1252
    pdf.WriteTextA 50#, 50#, "The same table but the cell orientation was changed to 90 degrees."

    pdf.TblDrawTable tbl, 50#, 65#, 742#
    Do While pdf.TblHaveMore(tbl)
        pdf.EndPage
        pdf.Append
        pdf.TblDrawTable tbl, 50#, 50#, 737#
    Loop
    pdf.EndPage

    delH = tbl
    pdf.TblDeleteTable delH           ' frees the table and sets the handle to 0

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() Then
        outFile = App.path & "\out.pdf"
        If Not pdf.OpenOutputFileA(outFile) Then Exit Sub
        If pdf.CloseFile() Then Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "table_text"
End Sub

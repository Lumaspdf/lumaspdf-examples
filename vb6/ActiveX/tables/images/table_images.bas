Attribute VB_Name = "modTableImages"
Option Explicit
' ============================================================================
'  table_images -- ActiveX/COM version (LumasPdf.PDF, late-bound), mirrors
'  the plain-DLL example at examples\Vb6\tables\images (read-only reference,
'  not modified). Lays out every JPEG in test_files\images into a 4-column
'  table (native image color space), draws it, then redraws with
'  tfScaleToRect.
'
'  Mapping: tblXxx(Table, args) -> pdf.TblXxx(Table, args) -- the table
'  handle stays an explicit argument, only the IPDF handle is dropped.
' ============================================================================

' Table flags not exposed by a type library reference (from LumasPdf.pas):
Private Const tfScaleToRect As Long = &H8&
Private Const tfUseImageCS As Long = &H10&

' TCellAlign / TTableBoxProperty
Private Const coCenter As Long = 2
Private Const tbpBorderWidth As Long = 0
Private Const tbpCellPadding As Long = 2
' TFStyle / TCodepage
Private Const fsRegular As Long = &H19000000
Private Const cp1252 As Long = 2
' TPageCoord
Private Const pcTopDown As Long = 1
' TFlushPagesFlags
Private Const fpfDefault As Long = 0

Public Sub Main()
    Dim pdf As Object
    Dim tbl As Long, delH As Variant
    Dim outFile As String, imgDir As String, fn As String
    Dim timeStart As Single, fullSize As Currency
    Dim i As Long, rowNum As Long

    On Error GoTo ErrHandler
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    timeStart = Timer

    pdf.CreateNewPDFA ""

    pdf.SetPageCoords pcTopDown
    pdf.SetResolution 300

    tbl = pdf.TblCreateTable(100, 4, 500#, 125#)
    pdf.TblSetBoxProperty tbl, -1, -1, tbpBorderWidth, 1#, 1#, 1#, 1#
    pdf.TblSetBoxProperty tbl, -1, -1, tbpCellPadding, 5#, 5#, 5#, 5#
    pdf.TblSetGridWidth tbl, 1#, 1#
    pdf.TblSetFlags tbl, -1, -1, tfUseImageCS

    imgDir = App.path & "\..\..\..\..\..\test_files\images\"
    fn = Dir$(imgDir & "*.jpg")
    If fn = "" Then
        Debug.Print "Test images not found!"
        delH = tbl
        pdf.TblDeleteTable delH
        Exit Sub
    End If

    i = 1
    fullSize = FileLen(imgDir & fn)
    rowNum = pdf.TblAddRow(tbl, 125#)
    pdf.TblSetCellImageA tbl, rowNum, 0, True, coCenter, coCenter, 0#, 0#, imgDir & fn, 1

    Do
        fn = Dir$()
        If fn = "" Then Exit Do
        If i = 4 Then
            rowNum = pdf.TblAddRow(tbl, 100#)
            i = 0
        End If
        fullSize = fullSize + FileLen(imgDir & fn)
        pdf.TblSetCellImageA tbl, rowNum, i, True, coCenter, coCenter, 0#, 0#, imgDir & fn, 1
        i = i + 1
    Loop

    pdf.Append

    pdf.TblDrawTable tbl, 50#, 50#, 742#
    Do While pdf.TblHaveMore(tbl)
        pdf.EndPage
        If fullSize > 104857600 Then pdf.FlushPages fpfDefault
        pdf.Append
        pdf.TblDrawTable tbl, 50#, 50#, 742#
    Loop
    pdf.EndPage

    ' We draw the same table again but this time with the flag tfScaleToRect
    pdf.TblSetFlags tbl, -1, -1, tfScaleToRect Or tfUseImageCS
    pdf.Append

    pdf.SetFontA "Arial", fsRegular, 12#, True, cp1252
    pdf.WriteTextA 50#, 50#, "The same table but the flag tfScaleToRect was set."

    pdf.TblDrawTable tbl, 50#, 65#, 742#
    Do While pdf.TblHaveMore(tbl)
        pdf.EndPage
        If fullSize > 104857600 Then pdf.FlushPages fpfDefault
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
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "table_images"
End Sub

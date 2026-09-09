Attribute VB_Name = "modTableImages"
Option Explicit
' ============================================================================
'  table_images -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp); enums
'  (fsRegular, cp1252, pcTopDown, coCenter, tbpBorderWidth, tbpCellPadding,
'  fpfDefault) come from the typelib. The flat tbl*/pdf* exports map to
'  tbl*/pdf.* methods (drop the handle first-arg; the table handle stays an
'  explicit arg). Lays out every JPEG in test_files\images into a 4-column table
'  (native image color space), draws it, then redraws with tfScaleToRect. The
'  error callback and the record-based error-log dump are dropped; errors
' pdf.RaiseExceptions = True
' ============================================================================

' Table flags not exposed by the type library (from dynapdf.pas):
Private Const tfScaleToRect As Long = &H8&
Private Const tfUseImageCS As Long = &H10&

Public Sub Main()
    Dim pdf As New CPDF
    Dim tbl As Long, delH As Variant
    Dim outFile As String, imgDir As String, fn As String
    Dim timeStart As Single, fullSize As Currency
    Dim i As Long, rowNum As Long
' pdf.RaiseExceptions = True

    timeStart = Timer

    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown
    pdf.SetResolution 300

    tbl = tblCreateTable(pdf.GetInstancePtr(), 100, 4, 500#, 125#)
    tblSetBoxProperty tbl, -1, -1, tbpBorderWidth, 1#, 1#, 1#, 1#
    tblSetBoxProperty tbl, -1, -1, tbpCellPadding, 5#, 5#, 5#, 5#
    tblSetGridWidth tbl, 1#, 1#
    tblSetFlags tbl, -1, -1, tfUseImageCS

    imgDir = App.Path & "\..\..\..\..\test_files\images\"
    fn = Dir$(imgDir & "*.jpg")
    If fn = "" Then
        Debug.Print "Test images not found!"
        delH = tbl
        tblDeleteTable delH
        Exit Sub
    End If

    i = 1
    fullSize = FileLen(imgDir & fn)
    rowNum = tblAddRow(tbl, 125#)
    tblSetCellImageA tbl, rowNum, 0, True, coCenter, coCenter, 0#, 0#, imgDir & fn, 1

    Do
        fn = Dir$()
        If fn = "" Then Exit Do
        If i = 4 Then
            rowNum = tblAddRow(tbl, 100#)
            i = 0
        End If
        fullSize = fullSize + FileLen(imgDir & fn)
        tblSetCellImageA tbl, rowNum, i, True, coCenter, coCenter, 0#, 0#, imgDir & fn, 1
        i = i + 1
    Loop

    pdf.Append

    tblDrawTable tbl, 50#, 50#, 742#
    Do While tblHaveMore(tbl)
        pdf.EndPage
        If fullSize > 104857600 Then pdf.FlushPages fpfDefault
        pdf.Append
        tblDrawTable tbl, 50#, 50#, 742#
    Loop
    pdf.EndPage

    ' We draw the same table again but this time with the flag tfScaleToRect
    tblSetFlags tbl, -1, -1, tfScaleToRect Or tfUseImageCS
    pdf.Append

    pdf.SetFont "Arial", fsRegular, 12#, True, cp1252
    pdf.WriteText 50#, 50#, "The same table but the flag tfScaleToRect was set."

    tblDrawTable tbl, 50#, 65#, 742#
    Do While tblHaveMore(tbl)
        pdf.EndPage
        If fullSize > 104857600 Then pdf.FlushPages fpfDefault
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

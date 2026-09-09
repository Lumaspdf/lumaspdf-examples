Attribute VB_Name = "modMeasureLines"
Option Explicit
' ============================================================================
'  measure_lines -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules (early-bound to
'  CPDF). Two dimension/measure line annotations on a rotated rectangle,
'  configured through a TLineAnnotParms record.
'
'  The native TLineAnnotParms record is supplied to the AX layer as a positional
'  Variant Array() (index = struct field order; Empty = keep default). The COM
'  marshaller overlays it onto the native record (StructSize filled auto):
'    idx1 Caption=1, idx5 LeaderLineLen=10, idx6 LeaderLineExtend=4,
'    idx7 LeaderLineOffset=2.
' ============================================================================

Private Const clCream As Long = 15793151
Private Const clBlack As Long = 0

Public Sub Main()
    Dim pdf As New CPDF
    Dim a As Long
    Dim x As Double, y As Double, w As Double, h As Double
    Dim outFile As String, txt As String
    Dim parms As Variant

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown

    pdf.Append

    w = 300#
    h = 100#
    x = pdf.GetPageWidth() / 2
    y = pdf.GetPageHeight() / 2

    ' Save the graphics state because the coordinate system will be rotated.
    pdf.SaveGraphicState

    pdf.SetGStateFlags gfRealTopDownCoords, 0    ' This simplifies the handling a little bit.
    pdf.RotateCoords -30#, x, y

    x = -w / 2
    y = -h / 2

    pdf.SetFillColor clCream
    pdf.Rectangle x, y, w, h, fmFillStroke

    parms = Array(Empty, 1, Empty, Empty, Empty, 10, 4, 2)

    txt = Format$(w, "0.0")
    a = pdf.LineAnnotA(x, y, x + w, y, 1#, leClosedArrow, leClosedArrow, clBlack, clBlack, csDeviceRGB, "This is a measure line", "Measure Line", txt)
    pdf.SetLineAnnotParms a, -1, 0#, parms

    txt = Format$(h, "0.0")
    a = pdf.LineAnnotA(x, y + h, x, y, 1#, leClosedArrow, leClosedArrow, clBlack, clBlack, csDeviceRGB, "This is a measure line", "Measure Line", txt)
    ' The parameters are exactly the same as above
    pdf.SetLineAnnotParms a, -1, 0#, parms

    pdf.RestoreGraphicState

    pdf.EndPage

    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

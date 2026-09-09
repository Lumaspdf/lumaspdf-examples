Attribute VB_Name = "modMeasureLines"
Option Explicit
' ============================================================================
'  measure_lines -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\annotations\measure_lines -- same feature: two dimension /
'  measure line annotations drawn along the sides of a rotated rectangle,
'  configured through a TLineAnnotParms record.
'
'  The native TLineAnnotParms record is supplied to the ActiveX server as a
'  positional Variant Array() (index = struct field order; Empty = keep
'  default). The COM marshaller overlays it onto the native record
'  (StructSize filled automatically):
'    idx1 Caption=1, idx5 LeaderLineLen=10, idx6 LeaderLineExtend=4,
'    idx7 LeaderLineOffset=2.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF ""    -> pdf.CreateNewPDFW ""
'    pdf.LineAnnotA ...     -> pdf.LineAnnotA ...   (kept -- explicit A in reference)
'    pdf.OpenOutputFile ... -> pdf.OpenOutputFileW ...
'  All other calls (SaveGraphicState, SetGStateFlags, RotateCoords,
'  SetFillColor, Rectangle, SetLineAnnotParms, RestoreGraphicState,
'  GetPageWidth, GetPageHeight, SetPageCoords, Append, EndPage, HaveOpenDoc,
'  CloseFile) map 1:1, just with the instance handle dropped.
' ============================================================================

Private Const clCream As Long = 15793151
Private Const clBlack As Long = 0

'--- TPageCoord --------------------------------------------------------------------
Const pcTopDown As Long = 1

'--- TPDFColorSpace ------------------------------------------------------------------
Const csDeviceRGB As Long = 0

'--- TPathFillMode (memory note: fmFillStroke = 5, not 2) ---------------------------
Const fmFillStroke As Long = 5

'--- TGStateFlags --------------------------------------------------------------------
Const gfRealTopDownCoords As Long = 2

'--- TLineEndStyle ---------------------------------------------------------------------
Const leClosedArrow As Long = 3

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim a As Long
    Dim x As Double, y As Double, w As Double, h As Double
    Dim outFile As String, txt As String
    Dim parms As Variant

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""

    pdf.SetPageCoords pcTopDown

    pdf.Append

    w = 300#
    h = 100#
    x = pdf.GetPageWidth() / 2
    y = pdf.GetPageHeight() / 2

    ' Save the graphics state because the coordinate system will be rotated.
    pdf.SaveGraphicState

    pdf.SetGStateFlags gfRealTopDownCoords, False    ' This simplifies the handling a little bit.
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

    If CBool(pdf.HaveOpenDoc()) Then
        outFile = App.Path & "\out.pdf"
        pdf.OpenOutputFileW outFile
        pdf.CloseFile
        Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "measure_lines (ActiveX)"
End Sub

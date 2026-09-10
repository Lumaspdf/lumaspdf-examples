Attribute VB_Name = "modQuadPoints"
Option Explicit
' ============================================================================
'  quad_points -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\annotations\quad_points -- same feature: highlight and link
'  annotations rotated together with the page coordinate system by setting
'  their quad points explicitly (highlight/link annotations do not follow a
'  page's coordinate transform on their own -- see the comment at
'  RotateCoords below).
'
'  ActiveX SetAnnotQuadPoints signature: SetAnnotQuadPoints(Handle, AValue,
'  Count). AValue must be a genuinely typed Single array (Dim v(n) As
'  Single) of packed (X,Y) pairs -- never a Variant Array() literal -- the
'  same rule documented for PolygonAnnotW in NorthwindMegaDemo.bas. Count is
'  the number of POINTS (4 for one quad), not the raw number count.
'  Quad point order follows the PDF spec: upper-left, upper-right,
'  lower-left, lower-right.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF ""     -> pdf.CreateNewPDFW ""
'    pdf.SetFont ...         -> pdf.SetFontW ...
'    pdf.WriteText ...       -> pdf.WriteTextW ...
'    pdf.GetTextWidthA ...   -> pdf.GetTextWidthA ...  (kept -- explicit A in reference)
'    pdf.HighlightAnnotA ... -> pdf.HighlightAnnotA ... (kept -- explicit A in reference)
'    pdf.WebLinkA ...        -> pdf.WebLinkA ...        (kept -- explicit A in reference)
'    pdf.OpenOutputFile ...  -> pdf.OpenOutputFileW ...
'  All other calls (SaveGraphicState, SetGStateFlags, RotateCoords,
'  GetDescent, SetAnnotQuadPoints, SetAnnotBorderWidth, SetAnnotColor,
'  RestoreGraphicState, SetPageCoords, Append, EndPage, HaveOpenDoc,
'  CloseFile) map 1:1, just with the instance handle dropped.
' ============================================================================

Private Const clYellow As Long = 65535
Private Const clRed As Long = 255
Private Const clBlue As Long = 16711680

'--- TFStyle (see src\Lumas.Pdf.Types.pas) --------------------------------------
Const FS_REGULAR As Long = &H19000000   ' weight 400 -> same as "no bold/italic"

'--- TCodepage (index 2 = cp1252) -------------------------------------------------
Const CP_1252 As Long = 2

'--- TPageCoord --------------------------------------------------------------------
Const pcTopDown As Long = 1

'--- TPDFColorSpace ------------------------------------------------------------------
Const csDeviceRGB As Long = 0

'--- TGStateFlags --------------------------------------------------------------------
Const gfRealTopDownCoords As Long = 2

'--- TAnnotType (highlight family subtypes) ------------------------------------------
Const atHighlight As Long = 4
Const atSquiggly As Long = 12
Const atStrikeOut As Long = 14
Const atUnderline As Long = 16

'--- TFieldColor (reused for annotation color type: border color) ---------------------
Const fcBorderColor As Long = 1

Private Const ROTATE_ANGLE As Double = -30#
Private Const PIVOT_X As Double = 50#
Private Const PIVOT_Y As Double = 200#

' Rotates point (px,py) about (ox,oy) by angleDeg -- same transform the page
' applies via RotateCoords -- so the quad points we hand to
' SetAnnotQuadPoints track the rotated text exactly.
Private Sub RotatePt(ByVal px As Double, ByVal py As Double, ByVal angleDeg As Double, ByRef rx As Single, ByRef ry As Single)
    Dim rad As Double, c As Double, s As Double, dx As Double, dy As Double
    rad = angleDeg * (3.14159265358979 / 180#)
    c = Cos(rad): s = Sin(rad)
    dx = px - PIVOT_X: dy = py - PIVOT_Y
    rx = CSng(PIVOT_X + dx * c - dy * s)
    ry = CSng(PIVOT_Y + dx * s + dy * c)
End Sub

' Builds the 4-point quad (UL, UR, LL, LR) for the box (x0,y0)-(x0+w,y0+h),
' rotated the same way as the page, and applies it to annotation handle a.
Private Sub SetRotatedQuad(ByVal pdf As Object, ByVal a As Long, ByVal x0 As Double, ByVal y0 As Double, ByVal w As Double, ByVal h As Double)
    Dim q(0 To 7) As Single
    RotatePt x0, y0, ROTATE_ANGLE, q(0), q(1)          ' upper-left
    RotatePt x0 + w, y0, ROTATE_ANGLE, q(2), q(3)      ' upper-right
    RotatePt x0, y0 + h, ROTATE_ANGLE, q(4), q(5)      ' lower-left
    RotatePt x0 + w, y0 + h, ROTATE_ANGLE, q(6), q(7)  ' lower-right
    pdf.SetAnnotQuadPoints a, q, 4
End Sub

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim a As Long
    Dim d As Double, w As Double
    Dim outFile As String, text As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""

    pdf.SetPageCoords pcTopDown

    pdf.Append

    pdf.SaveGraphicState

    pdf.SetGStateFlags gfRealTopDownCoords, False    ' This simplifies the handling a little bit.
    pdf.RotateCoords ROTATE_ANGLE, PIVOT_X, PIVOT_Y

    text = "Some rotated text on a page..."
    pdf.SetFontW "Helvetica", FS_REGULAR, 20#, False, CP_1252

    d = pdf.GetDescent()
    w = pdf.GetTextWidthA(text)

    ' Highlight annotations do not consider coordinate transformations made on a page.
    ' To get such annotations rotated we must set the annotation's quad points.
    pdf.WriteTextW 0#, 0#, text
    a = pdf.HighlightAnnotA(atHighlight, 50#, 50# + d, w, 20#, clYellow, "Test app", "Highligh Annotations", "This is a highlight annotation")
    SetRotatedQuad pdf, a, 50#, 50# + d, w, 20#

    pdf.WriteTextW 0#, 30#, text
    a = pdf.HighlightAnnotA(atSquiggly, 50#, 80#, w, 20#, clRed, "Test app", "Squiggly Annotations", "This is a squiggly annotation")
    SetRotatedQuad pdf, a, 50#, 80#, w, 20#

    pdf.WriteTextW 0#, 60#, text
    a = pdf.HighlightAnnotA(atStrikeOut, 50#, 110#, w, 20#, clRed, "Test app", "Strikeout Annotations", "This is a strikeout annotation")
    SetRotatedQuad pdf, a, 50#, 110#, w, 20#

    pdf.WriteTextW 0#, 90#, text
    a = pdf.HighlightAnnotA(atUnderline, 50#, 140#, w, 20#, clRed, "Test app", "Underline Annotations", "This is a underline annotation")
    SetRotatedQuad pdf, a, 50#, 140#, w, 20#

    text = "Link annotations support quad points too"
    w = pdf.GetTextWidthA(text)
    pdf.WriteTextW 0#, 120#, text
    ' Link annotations support quad points too.
    a = pdf.WebLinkA(0#, 120#, w, 20#, "www.lumaspdf.com")
    pdf.SetAnnotBorderWidth a, 1#
    pdf.SetAnnotColor a, fcBorderColor, csDeviceRGB, clBlue
    SetRotatedQuad pdf, a, 0#, 120#, w, 20#

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
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "quad_points (ActiveX)"
End Sub

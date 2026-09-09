Attribute VB_Name = "modMetafiles"
Option Explicit
' ============================================================================
'  metafiles -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt). Places three EMF metafiles,
'  each centered and scaled to a landscape page, with a red frame around them.
'  The AX exposes GetLogMetafileSize as four OleVariant out params (no TRectL
' pdf.RaiseExceptions = True
' ============================================================================

Private Const CLR_RED As Long = 255
Private Const MARGIN As Double = 10#

Private pdf As CPDF

Private Sub PlaceEMFCentered(ByVal MFile As String, ByVal Width As Double, ByVal Height As Double)
    Dim x As Double, y As Double, w As Double, h As Double, sx As Double
    Dim l As Variant, t As Variant, rt As Variant, b As Variant

    pdf.GetLogMetafileSize MFile, l, t, rt, b
    w = rt - l
    h = b - t
    Width = Width - 2# * MARGIN
    Height = Height - 2# * MARGIN
    sx = Width / w

    If (h * sx <= Height) Then
        x = MARGIN
        h = h * sx
        ' If the file should not be centered vertically set y to MARGIN.
        y = (Height - h) / 2#
        pdf.InsertMetafile MFile, x, y, Width, 0#
        pdf.SetStrokeColor CLR_RED
        pdf.Rectangle x, y, Width, h, fmStroke
    Else
        sx = Height / h
        w = w * sx
        x = (Width - w) / 2#
        y = MARGIN
        pdf.InsertMetafile MFile, x, y, 0#, Height
        pdf.SetStrokeColor CLR_RED
        pdf.Rectangle x, y, w, Height, fmStroke
    End If
End Sub

Public Sub Main()
    Dim outFile As String

    Set pdf = New CPDF
' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""                            ' output file opened later

    pdf.SetPageCoords pcTopDown

    ' We use a landscape paper format; SetOrientationEx rotates the coordinate system.
    pdf.Append
    pdf.SetOrientationEx 90
    PlaceEMFCentered App.Path & "\coords.emf", pdf.GetPageWidth, pdf.GetPageHeight
    pdf.EndPage

    pdf.Append
    pdf.SetOrientationEx 90
    PlaceEMFCentered App.Path & "\fulltest.emf", pdf.GetPageWidth, pdf.GetPageHeight
    pdf.EndPage

    pdf.Append
    pdf.SetOrientationEx 90
    PlaceEMFCentered App.Path & "\gdi.emf", pdf.GetPageWidth, pdf.GetPageHeight
    pdf.EndPage

    ' No fatal error occurred?
    If pdf.HaveOpenDoc <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
    End If
    If pdf.CloseFile <> 0 Then
        Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If
End Sub

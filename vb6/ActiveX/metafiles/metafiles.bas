Attribute VB_Name = "modMetafiles"
Option Explicit
' ============================================================================
'  metafiles -- ActiveX/COM edition (LumasPdf.PDF), late-bound, no project
'  reference required. Equivalent of ../../../Vb6/metafiles (flat-DLL / CPDF.cls
'  wrapper style). Places three EMF metafiles, each centered and scaled to a
'  landscape page, with a red frame around them.
'
'  GetLogMetafileSize is exposed by the AX server as four [in,out] VARIANT
'  out-parameters (Left/Top/Right/Bottom) rather than the flat-DLL's ByRef
'  TRectL struct -- see wrappers\activex\LumasPdfAX.ridl.
'
'  pdf.RaiseExceptions = True turns internal engine errors into VB6 runtime
'  errors, caught below via On Error GoTo ErrHandler.
' ============================================================================

Private Const CLR_RED As Long = 255
Private Const MARGIN As Double = 10#

' --- enum values used below (see wrappers\activex\LumasPdfAX.ridl / src\Lumas.Pdf.Types.pas) ---
Private Const pcTopDown As Long = 1        ' TPageCoord.pcTopDown
Private Const fmStroke As Long = 4         ' TPathFillMode.fmStroke

Private pdf As Object   ' LumasPdf.PDF (late-bound)

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

    On Error GoTo ErrHandler

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    pdf.CreateNewPDFW ""                            ' output file opened later

    pdf.SetPageCoords pcTopDown

    ' We use a landscape paper format; SetOrientationEx rotates the coordinate system.
    pdf.Append
    pdf.SetOrientationEx 90
    PlaceEMFCentered App.path & "\coords.emf", pdf.GetPageWidth, pdf.GetPageHeight
    pdf.EndPage

    pdf.Append
    pdf.SetOrientationEx 90
    PlaceEMFCentered App.path & "\fulltest.emf", pdf.GetPageWidth, pdf.GetPageHeight
    pdf.EndPage

    pdf.Append
    pdf.SetOrientationEx 90
    PlaceEMFCentered App.path & "\gdi.emf", pdf.GetPageWidth, pdf.GetPageHeight
    pdf.EndPage

    ' No fatal error occurred?
    If CBool(pdf.HaveOpenDoc()) Then
        outFile = App.path & "\out.pdf"
        If Not CBool(pdf.OpenOutputFileW(outFile)) Then Exit Sub
    End If
    If CBool(pdf.CloseFile()) Then
        Debug.Print "PDF file """ & outFile & """ successfully created!"
        MsgBox "PDF file """ & outFile & """ successfully created!", vbInformation, "metafiles (ActiveX)"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then
        extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "metafiles (ActiveX)"
End Sub

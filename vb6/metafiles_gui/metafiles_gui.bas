Attribute VB_Name = "modMetafilesGui"
Option Explicit
' ============================================================================
'  metafiles_gui -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp); all
'  enums (cfFlate, clNone, csDeviceRGB, mfDefault, pcTopDown) come from the
'  typelib. The Delphi original is a Forms application (a metafile
'  viewer/converter); the PDF logic lived in tbConvertClick. It is reproduced
'  here as a plain Sub Main() (no VB6 form): it loads an EMF/WMF file, places it
'  centered on a page and writes out.pdf. The interactive UI and preview flags
'  are dropped; the conversion flags default to mfDefault.
'  The AX exposes GetLogMetafileSize as four OleVariant out params (no TRectL
' pdf.RaiseExceptions = True
' ============================================================================

Private Const MARGIN As Double = 10#

Private pdf As CPDF

' Places a metafile (given by file name) centered on the page, preserving the
' aspect ratio. Mirrors the String overload of PlaceEMFCentered.
Private Sub PlaceEMFCentered(ByVal MFile As String, ByVal Width_ As Double, ByVal Height_ As Double)
    Dim x As Double, y As Double, w As Double, h As Double, sx As Double
    Dim l As Variant, t As Variant, rt As Variant, b As Variant

    pdf.GetLogMetafileSize MFile, l, t, rt, b
    w = rt - l
    h = b - t
    Width_ = Width_ - 2# * MARGIN
    Height_ = Height_ - 2# * MARGIN
    sx = Width_ / w
    If (h * sx <= Height_) Then
        x = MARGIN
        y = MARGIN
        pdf.InsertMetafile MFile, x, y, Width_, 0#
    Else
        sx = Height_ / h
        w = w * sx
        x = MARGIN + (Width_ - w) / 2#
        y = MARGIN
        pdf.InsertMetafile MFile, x, y, 0#, Height_
    End If
End Sub

Public Sub Main()
    Dim inFile As String, outFile As String

    Set pdf = New CPDF
' pdf.RaiseExceptions = True
    ' We use flate compression for better transparency support.
    pdf.SetCompressionFilter cfFlate
    pdf.SetJPEGQuality 70

    ' Original input came from an interactive shell tree; here a fixed file.
    inFile = App.Path & "\in.emf"
    outFile = App.Path & "\out.pdf"

    If pdf.CreateNewPDF("") = 0 Then Exit Sub

    pdf.SetCompressionLevel clNone         ' "compress" checkbox default off
    pdf.SetCompressionFilter cfFlate       ' "JPEG" checkbox default off
    pdf.SetColorSpace csDeviceRGB          ' "CMYK" checkbox default off
    pdf.SetMetaConvFlags mfDefault         ' no preview flags selected
    pdf.SetPageCoords pcTopDown
    pdf.Append
    pdf.SetResolution 300
    pdf.SetJPEGQuality 70
    PlaceEMFCentered inFile, pdf.GetPageWidth, pdf.GetPageHeight
    pdf.EndPage

    If pdf.HaveOpenDoc() <> 0 Then
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "OK: " & outFile
        End If
    End If
End Sub

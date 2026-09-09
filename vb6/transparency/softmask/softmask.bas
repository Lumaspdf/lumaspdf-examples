Attribute VB_Name = "modSoftmask"
Option Explicit
' ============================================================================
'  softmask -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Creates a transparency group used as a luminosity soft mask (radial shading)
'  and applies it to an image. CreateExtGState takes a positional Array() overlay
'  of TPDFExtGState: SoftMask is index 13 (the handle from CreateSoftMask),
'  SoftMaskNone is index 12. ComputeBBox returns the four box edges as [out]
'  OleVariants (instead of the flat TPDFRect record). Error callback dropped.
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim o As Object
    Dim gs As Long, grp As Long, sh As Long, smHandle As Variant
    Dim outFile As String
    Dim g As Variant
    Dim bl As Variant, bb As Variant, br As Variant, bt As Variant

    Set o = pdf     ' late-bound view for CreateSoftMask (returns Int64, which VB6
                    ' cannot receive early-bound; IDispatch::Invoke marshals it fine)

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""              ' The output file is opened later

    pdf.SetPageCoords pcTopDown
    pdf.SetUseTransparency 0          ' Disable color key masking for images

    pdf.Append

    pdf.SetFont "Helvetica", fsRegular, 12#, False, cp1252
    pdf.WriteText 50#, 50#, "Transparency effect with a soft mask."

    pdf.InsertImageEx 50#, 80#, pdf.GetPageWidth() - 100#, 0#, "../../../test_files/images/meadow-110719_640.jpg", 1

    ' A transparency group used as a soft mask has no own coordinate system.
    grp = pdf.BeginTransparencyGroup(0#, 0#, pdf.GetPageWidth(), pdf.GetPageHeight(), 1, 0, esDeviceGray, -1)
        pdf.SetColorSpace csDeviceGray
        sh = pdf.CreateRadialShading(400#, 230#, 20#, 400#, 230#, 150#, 1#, 255, 0, 1, 0)
        pdf.ApplyShading sh
        ' Optional but recommended: compute the real bounding box of the group.
        pdf.ComputeBBox bl, bb, br, bt, cbfNone
        pdf.SetBBox pbMediaBox, bl, bb, br, bt
    pdf.EndTemplate

    ' SoftMask = handle from CreateSoftMask (TPDFExtGState index 13).
    smHandle = o.CreateSoftMask(grp, smtLuminosity, 0)
    g = Array(Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, smHandle)
    gs = pdf.CreateExtGState(0&)

    ' Activate the mask and draw an image.
    pdf.SetExtGState gs
    pdf.InsertImageEx 220#, 80#, 500#, 0#, "../../../test_files/images/tree-frog-69813_640.jpg", 1

    ' Deactivate the soft mask: SoftMaskNone = 1 (index 12).
    g = Array(Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, 1)
    gs = pdf.CreateExtGState(0&)
    pdf.SetExtGState gs

    pdf.WriteText 50#, 400#, "The soft mask is now deactivated."
    pdf.EndPage

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

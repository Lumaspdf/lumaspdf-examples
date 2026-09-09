Attribute VB_Name = "modAlphaTransparency"
Option Explicit
' ============================================================================
'  alpha_transparency -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Draws an image at fill alpha 0.5 and a second at the default alpha 1.0 using
'  extended graphics states. CreateExtGState takes a positional Array() overlay
'  (index = TPDFExtGState field order; Empty = keep the InitExtGState default);
' pdf.RaiseExceptions = True
' ============================================================================

Private Const clWhite As Long = &HFFFFFF   ' VCL TColor, not a PDF constant
Private Const clBlack As Long = &H0

Public Sub Main()
    Dim pdf As New CPDF
    Dim gs As Long, img As Long
    Dim outFile As String
    Dim g As Variant

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""              ' The output file is opened later

    pdf.SetPageCoords pcTopDown
    pdf.SetUseTransparency 0          ' Disable color key masking for images

    pdf.Append

    pdf.SetFont "Helvetica", fsRegular, 12#, False, cp1252
    pdf.WriteText 50#, 50#, "Fill Alpha = 0.5"

    pdf.Rectangle 50#, 70#, 110#, 160#, fmFill
    pdf.SetFillColor clWhite
    pdf.WriteText 55#, 75#, "Background"

    ' FillAlpha = 0.5 (TPDFExtGState index 8).
    g = Array(Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, 0.5)
    gs = pdf.CreateExtGState(0&)
    pdf.SetExtGState gs

    img = pdf.InsertImageEx(60#, 84#, 200#, 0#, "../../../test_files/images/tree-frog-69813_640.jpg", 0)

    ' To restore an extended graphics state, create a second one that restores the changes.
    g = Array(Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, 1#)
    gs = pdf.CreateExtGState(0&)
    pdf.SetExtGState gs

    pdf.SetFillColor clBlack
    pdf.WriteText 340#, 50#, "Fill Alpha = 1.0 (default)"
    pdf.Rectangle 340#, 70#, 110#, 160#, fmFill
    pdf.SetFillColor clWhite
    pdf.WriteText 345#, 75#, "Background"
    pdf.PlaceImage img, 350#, 84#, 200#, 0#

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

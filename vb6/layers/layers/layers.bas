Attribute VB_Name = "modLayers"
Option Explicit
' ============================================================================
'  layers -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt). Creates three nested
'  optional-content groups (layers) and places text (with a web link) and an
'  image into them. The VarPtr(array) passed to CreateOCMD becomes a plain VB6
'  Array(...) marshalled to the OleVariant OCGs param. Errors surface as VB6
' pdf.RaiseExceptions = True
' ============================================================================

Private Const clBlue As Long = &HFF0000
Private Const clBlack As Long = &H0

Public Sub Main()
    Dim pdf As New CPDF
    Dim annot As Long, ocmd As Long, oc1 As Long, oc2 As Long, oc3 As Long
    Dim tw As Double
    Dim outFile As String, someText As String, img As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""   ' The output file is opened later

    pdf.SetPageCoords pcTopDown

    ' Disable color key masking for images
    pdf.SetUseTransparency 0

    img = "E:\LUMASPDFSDK\examples\test_files\images\margarita-102572_640.jpg"

    ' Create three layers
    oc1 = pdf.CreateOCGA("All", 1, 1, oiAll)
    oc2 = pdf.CreateOCGA("Text and Annotations", 1, 1, oiAll)
    oc3 = pdf.CreateOCGA("Images", 1, 1, oiAll)

    pdf.Append
        ' The main layer controls the visibility of all three layers in this example.
        pdf.BeginLayer oc1
            pdf.BeginLayer oc2
                pdf.SetFont "Helvetica", fsRegular, 12#, 0, cp1252
                someText = "Some text with a link!!!"
                pdf.SetFillColor clBlue
                pdf.WriteText 50#, 50#, someText
                tw = pdf.GetTextWidthA(someText)
                ' To reflect the same nesting as the text layer we use an OCMD for the annotation
                ' because the visibility of layer oc2 depends on oc1 at this position.
                pdf.SetBorderStyle bsUnderline
                pdf.SetStrokeColor clBlue
                annot = pdf.WebLinkA(50#, 51#, tw, 12#, "www.dynaforms.com")

                ocmd = pdf.CreateOCMD(ovAllOn, Array(oc1, oc2), 2)
                pdf.AddObjectToLayer ocmd, ooAnnotation, annot
            pdf.EndLayer

            pdf.BeginLayer oc3
                pdf.InsertImageEx 50#, 70#, 300#, 200#, img, 1
            pdf.EndLayer
        pdf.EndLayer

        pdf.SetFillColor clBlack
        pdf.WriteText 50#, 300#, "This text is not part of a layer!"
    pdf.EndPage

    pdf.SetPageMode pmUseOC

    ' No fatal error occurred?
    If pdf.HaveOpenDoc <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

Attribute VB_Name = "modLayerTree"
Option Explicit
' ============================================================================
'  layer_tree -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt). Creates three optional-content
'  groups (layers) arranged in a display tree with a titled group, and adds
'  text (with a web link) and an image to the layers. AddLayerToDisplTreeA
'  returns/takes a 64-bit handle, so its results are held in Variants (VB6 has
'  no native 64-bit integer). Errors surface as VB6 exceptions.
' ============================================================================

Private Const clBlue As Long = &HFF0000
Private Const clBlack As Long = &H0

Public Sub Main()
    Dim pdf As New CPDF
    Dim o As Object          ' same instance, late dispatch for the Int64 display-tree API
    Dim annot As Long, ocmd As Long, oc1 As Long, oc2 As Long, oc3 As Long
    Dim root As Variant, grp As Variant
    Dim tw As Double
    Dim outFile As String, someText As String, img As String

' pdf.RaiseExceptions = True
    Set o = pdf.pdf.CreateNewPDF ""   ' The output file is opened later

    pdf.SetPageCoords pcTopDown

    ' Disable color key masking for images
    pdf.SetUseTransparency 0

    img = "E:\LUMASPDFSDK\examples\test_files\images\margarita-102572_640.jpg"

    ' Create three layers
    oc1 = pdf.CreateOCGA("All", 0, 1, oiAll)
    oc2 = pdf.CreateOCGA("Text and Annotations", 0, 1, oiAll)
    oc3 = pdf.CreateOCGA("Images", 0, 1, oiAll)

    ' AddLayerToDisplTreeA uses a 64-bit tree-node handle; VB6 cannot early-bind
    ' an Int64 parameter/return, so these four calls go through late dispatch.
    root = o.AddLayerToDisplTreeA(0, oc1, "A layer group with a title")
    grp = o.AddLayerToDisplTreeA(root, -1, "")
    o.AddLayerToDisplTreeA grp, oc2, ""
    o.AddLayerToDisplTreeA grp, oc3, ""

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

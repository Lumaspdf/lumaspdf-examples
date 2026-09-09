Attribute VB_Name = "modLayerTree"
Option Explicit
' ============================================================================
'  layer_tree -- ActiveX/COM edition (LumasPdf.PDF), late-bound, no project
'  reference required. Equivalent of ../../../../Vb6/layers/layer_tree
'  (flat-DLL / CPDF.cls wrapper style). Creates three optional-content groups
'  (layers) arranged in a display tree with a titled group, and adds text
'  (with a web link) and an image to the layers.
'
'  AddLayerToDisplTreeA takes/returns a 64-bit tree-node handle. The flat-DLL
'  original needed a separate late-dispatch Object because its early-bound
'  CPDF class cannot represent an Int64 parameter/return in VB6 (which has no
'  native 64-bit integer type). Here `pdf` is ALREADY a late-bound Object
'  (CreateObject), so every call -- including AddLayerToDisplTreeA -- goes
'  through IDispatch and Variants naturally; no extra workaround is needed.
'
'  pdf.RaiseExceptions = True turns internal engine errors into VB6 runtime
'  errors, caught below via On Error GoTo ErrHandler.
' ============================================================================

Private Const clBlue As Long = &HFF0000
Private Const clBlack As Long = &H0

' --- enum values used below (see wrappers\activex\LumasPdfAX.ridl / src\Lumas.Pdf.Types.pas) ---
Private Const pcTopDown As Long = 1        ' TPageCoord.pcTopDown
Private Const oiAll As Long = 8            ' TOCGIntent.oiAll
Private Const fsRegular As Long = &H19000000 ' TFStyle.fsRegular
Private Const cp1252 As Long = 2           ' TCodepage.cp1252
Private Const bsUnderline As Long = 3      ' TBorderStyle.bsUnderline
Private Const ovAllOn As Long = 1          ' TOCVisibility.ovAllOn
Private Const ooAnnotation As Long = 0     ' TOCObject.ooAnnotation
Private Const pmUseOC As Long = 4          ' TPageMode.pmUseOC

Public Sub Main()
    Dim pdf As Object          ' LumasPdf.PDF (late-bound)
    Dim annot As Long, ocmd As Long, oc1 As Long, oc2 As Long, oc3 As Long
    Dim root As Variant, grp As Variant
    Dim tw As Double
    Dim outFile As String, someText As String, img As String

    On Error GoTo ErrHandler

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    pdf.CreateNewPDFW ""       ' The output file is opened later

    pdf.SetPageCoords pcTopDown

    ' Disable color key masking for images
    pdf.SetUseTransparency 0

    img = "E:\LUMASPDFSDK\examples\test_files\images\margarita-102572_640.jpg"

    ' Create three layers
    oc1 = pdf.CreateOCGA("All", 0, 1, oiAll)
    oc2 = pdf.CreateOCGA("Text and Annotations", 0, 1, oiAll)
    oc3 = pdf.CreateOCGA("Images", 0, 1, oiAll)

    ' AddLayerToDisplTreeA's 64-bit tree-node handles round-trip through
    ' Variants automatically since pdf is a late-bound Object.
    root = pdf.AddLayerToDisplTreeA(0, oc1, "A layer group with a title")
    grp = pdf.AddLayerToDisplTreeA(root, -1, "")
    pdf.AddLayerToDisplTreeA grp, oc2, ""
    pdf.AddLayerToDisplTreeA grp, oc3, ""

    pdf.Append
    ' The main layer controls the visibility of all three layers in this example.
    pdf.BeginLayer oc1
    pdf.BeginLayer oc2
        pdf.SetFontW "Helvetica", fsRegular, 12#, 0, cp1252
        someText = "Some text with a link!!!"
        pdf.SetFillColor clBlue
        pdf.WriteTextW 50#, 50#, someText
        tw = pdf.GetTextWidthW(someText)
        ' To reflect the same nesting as the text layer we use an OCMD for the annotation
        ' because the visibility of layer oc2 depends on oc1 at this position.
        pdf.SetBorderStyle bsUnderline
        pdf.SetStrokeColor clBlue
        annot = pdf.WebLinkW(50#, 51#, tw, 12#, "www.dynaforms.com")

        ocmd = pdf.CreateOCMD(ovAllOn, Array(oc1, oc2), 2)
        pdf.AddObjectToLayer ocmd, ooAnnotation, annot
    pdf.EndLayer

    pdf.BeginLayer oc3
        pdf.InsertImageEx 50#, 70#, 300#, 200#, img, 1
    pdf.EndLayer
    pdf.EndLayer

    pdf.SetFillColor clBlack
    pdf.WriteTextW 50#, 300#, "This text is not part of a layer!"
    pdf.EndPage

    pdf.SetPageMode pmUseOC

    ' No fatal error occurred?
    If CBool(pdf.HaveOpenDoc()) Then
        outFile = App.path & "\out.pdf"
        If Not CBool(pdf.OpenOutputFileW(outFile)) Then Exit Sub
        If CBool(pdf.CloseFile()) Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
            MsgBox "PDF file """ & outFile & """ successfully created!", vbInformation, "layer_tree (ActiveX)"
        End If
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then
        extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "layer_tree (ActiveX)"
End Sub

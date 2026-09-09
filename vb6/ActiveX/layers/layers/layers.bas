Attribute VB_Name = "modLayers"
Option Explicit
' ============================================================================
'  layers -- ActiveX/COM edition (LumasPdf.PDF), late-bound, no project
'  reference required. Equivalent of ../../../../Vb6/layers/layers (flat-DLL /
'  CPDF.cls wrapper style). Creates three nested optional-content groups
'  (layers) and places text (with a web link) and an image into them. The
'  VarPtr(array) passed to CreateOCMD in the flat-DLL original becomes a
'  plain VB6 Array(...) marshalled to the OleVariant OCGs param here, exactly
'  as it already was for the wrapper-class version.
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
    oc1 = pdf.CreateOCGA("All", 1, 1, oiAll)
    oc2 = pdf.CreateOCGA("Text and Annotations", 1, 1, oiAll)
    oc3 = pdf.CreateOCGA("Images", 1, 1, oiAll)

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
            MsgBox "PDF file """ & outFile & """ successfully created!", vbInformation, "layers (ActiveX)"
        End If
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then
        extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "layers (ActiveX)"
End Sub

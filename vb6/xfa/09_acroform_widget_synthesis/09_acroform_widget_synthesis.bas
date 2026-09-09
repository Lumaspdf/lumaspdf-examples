Attribute VB_Name = "mod09AcroformWidgetSynthesis"
Option Explicit
' ============================================================================
'  09_acroform_widget_synthesis -- VB6 port of the LumasPDF XFA "flavor tour"
'  example 9 of 10: ACROFORM WIDGET SYNTHESIS. Native C API DLL wrapper style
'  (wrappers\vb6\CPDF.cls), ZERO extra wrapper modules -- same convention as
'  every other examples\Vb6\* driver in this project.
'
'  Demonstrates pdf.SetXFARenderMode(1): turning an XFA form into a REAL
'  fillable AcroForm PDF instead of flattened ink. Renders the same
'  09_acroform_widget_synthesis.xdp TWICE:
'    mode0.pdf -- Mode 0 (default, pdf.SetXFARenderMode is never called):
'                 flattened ink only, /AcroForm/Fields empty.
'    mode1.pdf -- Mode 1 (pdf.SetXFARenderMode(1) called AFTER both
'                 pdf.CreateXFAStream calls, BEFORE pdf.RenderXFAForm --
'                 same position the Delphi driver calls pdfSetXFARenderMode
'                 in): flattened ink PLUS a real synthesized /AcroForm with
'                 9 fillable fields (ApplicantName, YearsExperience,
'                 ApplicationDate, EmploymentType exclGroup radio (3 Kids),
'                 Department combo, SubmitButton pushbutton with a real
'                 bevel /AP, and the 3 occur-repeated Employer[N].EmployerName
'                 fields).
'
'  Mirrors examples\delphi\xfa\09_acroform_widget_synthesis\09_acroform_widget_synthesis.dpr's
'  call sequence exactly for each pass: pdfNewPDF -> pdfCreateNewPDFA ->
'  pdfCreateXFAStreamA('template',...) -> pdfCreateXFAStreamA('datasets',...)
'  -> [pdfSetXFARenderMode(doc,1) only for the second pass] ->
'  pdfRenderXFAForm -> pdfCloseFile -> pdfDeletePDF. Reads the pre-split
'  packet files 09_acroform_widget_synthesis.template.xml / .datasets.xml as
'  raw bytes -- no XML parsing needed.
' ============================================================================

Private Sub LoadFileBytes(ByVal FileName As String, ByRef Buf() As Byte, ByRef GotData As Boolean)
    Dim fNum As Integer, sz As Long
    GotData = False
    fNum = FreeFile
    Open FileName For Binary Access Read As #fNum
    sz = LOF(fNum)
    If sz > 0 Then
        ReDim Buf(0 To sz - 1)
        Get #fNum, , Buf
        GotData = True
    End If
    Close #fNum
End Sub

' Mode: 0 = flatten-to-ink only (default, no SetXFARenderMode call at all --
' exercises the untouched default path); 1 = also synthesize real AcroForm
' fillable widgets. Each call gets its own fresh CPDF instance (New CPDF ->
' pdfNewPDF in Class_Initialize, pdfDeletePDF in Class_Terminate when it
' goes out of scope), matching the Delphi driver's own pdfNewPDF/pdfDeletePDF
' pair per pass.
Private Function RenderExample(ByVal templateFile As String, ByVal datasetsFile As String, ByVal outFile As String, ByVal Mode As Long) As Long
    Dim pdf As New CPDF
    Dim templateBuf() As Byte, datasetsBuf() As Byte
    Dim haveTemplate As Boolean, haveDatasets As Boolean
    Dim idx As Long, pages As Long, prevMode As Long

    RenderExample = -100
    Debug.Print "=== 09_acroform_widget_synthesis.xdp (mode=" & Mode & ") -> " & outFile & " ==="

    LoadFileBytes templateFile, templateBuf, haveTemplate
    LoadFileBytes datasetsFile, datasetsBuf, haveDatasets

    If Not haveTemplate Then
        Debug.Print "NO-TEMPLATE-PACKET"
        Exit Function
    End If
    Debug.Print "template packet bytes: " & (UBound(templateBuf) + 1)
    If haveDatasets Then
        Debug.Print "datasets packet bytes: " & (UBound(datasetsBuf) + 1)
    Else
        Debug.Print "(no datasets packet found -- template-only render)"
    End If

    pdf.CreateNewPDFA ""

    idx = pdf.CreateXFAStream("template", templateBuf)
    Debug.Print "pdfCreateXFAStreamA(template) -> index " & idx
    If idx < 0 Then
        Debug.Print "pdfCreateXFAStreamA(template) FAILED"
        Exit Function
    End If

    If haveDatasets Then
        idx = pdf.CreateXFAStream("datasets", datasetsBuf)
        Debug.Print "pdfCreateXFAStreamA(datasets) -> index " & idx
        If idx < 0 Then
            Debug.Print "pdfCreateXFAStreamA(datasets) FAILED"
            Exit Function
        End If
    End If

    If Mode <> 0 Then
        prevMode = pdf.SetXFARenderMode(Mode)
        Debug.Print "pdfSetXFARenderMode(PDF, " & Mode & ") -> previous=" & prevMode & " (expect 0, the default)"
    End If

    pages = pdf.RenderXFAForm()
    Debug.Print "pdfRenderXFAForm -> " & pages & " (expected: page count >= 1)"
    If pages < 1 Then
        Debug.Print "RENDER-FAILED, code " & pages
        RenderExample = pages
        Exit Function
    End If

    pdf.OpenOutputFile outFile
    If Not pdf.CloseFile() Then
        Debug.Print "pdfCloseFile FAILED"
        RenderExample = -101
        Exit Function
    End If
    Debug.Print "OK: wrote " & outFile & " (" & pages & " page(s))"
    RenderExample = pages
End Function

Public Sub Main()
    Dim templateFile As String, datasetsFile As String
    Dim r0 As Long, r1 As Long

    templateFile = App.Path & "\09_acroform_widget_synthesis.template.xml"
    datasetsFile = App.Path & "\09_acroform_widget_synthesis.datasets.xml"

    r0 = RenderExample(templateFile, datasetsFile, App.Path & "\mode0.pdf", 0)
    r1 = RenderExample(templateFile, datasetsFile, App.Path & "\mode1.pdf", 1)

    Debug.Print ""
    Debug.Print "RESULT|mode0=" & r0 & "|mode1=" & r1
    If r0 >= 1 And r1 >= 1 Then
        Debug.Print "OK: both renders succeeded."
        Debug.Print "  mode0.pdf -- flattened ink only, NO /AcroForm/Fields."
        Debug.Print "  mode1.pdf -- flattened ink PLUS a REAL fillable AcroForm."
    Else
        Debug.Print "FAILED, see errors above."
    End If
End Sub

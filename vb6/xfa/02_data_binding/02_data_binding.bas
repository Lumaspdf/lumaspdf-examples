Attribute VB_Name = "mod02DataBinding"
Option Explicit
' ============================================================================
'  02_data_binding -- VB6 port of the LumasPDF XFA "flavor tour" example 2 of
'  10: DATA BINDING. Native C API DLL wrapper style (wrappers\vb6\CPDF.cls),
'  ZERO extra wrapper modules -- same convention as every other examples\Vb6\*
'  driver in this project.
'
'  Demonstrates the three data-binding modes an XFA form mixes in practice:
'   1. Implicit binding (by-name, no <bind> element) -- CustomerName/AccountId
'      inside subform "Customer", and Street/State/Zip nested one level
'      deeper inside subform "Address".
'   2. Explicit <bind match="dataRef" ref="$data...."/> against a genuinely
'      nested SOM path -- ShippingCityField (3 levels), PrimaryContactEmailField
'      (4 levels).
'   3. <bind match="none"/> -- AccountStatusField's literal "Active - Verified"
'      is unaffected by a same-named trap node in the datasets packet.
'
'  Mirrors examples\delphi\xfa\02_data_binding\02_data_binding.dpr's call
'  sequence exactly: pdfNewPDF -> pdfCreateNewPDFA ->
'  pdfCreateXFAStreamA('template',...) -> pdfCreateXFAStreamA('datasets',...)
'  -> pdfRenderXFAForm -> pdfCloseFile. Reads the pre-split packet files
'  02_data_binding.template.xml / .datasets.xml as raw bytes -- no XML
'  parsing needed.
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

Public Sub Main()
    Dim pdf As New CPDF
    Dim templateBuf() As Byte, datasetsBuf() As Byte
    Dim haveTemplate As Boolean, haveDatasets As Boolean
    Dim idx As Long, pages As Long
    Dim outFile As String

    Debug.Print "=== 02_data_binding.xdp -> 02_data_binding.render.pdf ==="

    LoadFileBytes App.Path & "\02_data_binding.template.xml", templateBuf, haveTemplate
    LoadFileBytes App.Path & "\02_data_binding.datasets.xml", datasetsBuf, haveDatasets

    If Not haveTemplate Then
        Debug.Print "NO-TEMPLATE-PACKET"
        Exit Sub
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
        Exit Sub
    End If

    If haveDatasets Then
        idx = pdf.CreateXFAStream("datasets", datasetsBuf)
        Debug.Print "pdfCreateXFAStreamA(datasets) -> index " & idx
        If idx < 0 Then
            Debug.Print "pdfCreateXFAStreamA(datasets) FAILED"
            Exit Sub
        End If
    End If

    pages = pdf.RenderXFAForm()
    Debug.Print "pdfRenderXFAForm -> " & pages
    If pages < 0 Then
        Debug.Print "pdfRenderXFAForm FAILED, code " & pages
        Exit Sub
    End If

    outFile = App.Path & "\02_data_binding.render.pdf"
    pdf.OpenOutputFile outFile
    If pdf.CloseFile() Then
        Debug.Print "OK: wrote " & outFile
    Else
        Debug.Print "pdfCloseFile FAILED"
    End If

    Debug.Print "RESULT|02_data_binding=" & pages
End Sub

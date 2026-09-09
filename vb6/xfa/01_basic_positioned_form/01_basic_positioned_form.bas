Attribute VB_Name = "mod01BasicPositionedForm"
Option Explicit
' ============================================================================
'  01_basic_positioned_form -- VB6 port of the LumasPDF XFA "flavor tour"
'  example 1 of 10: POSITIONED LAYOUT (static field positioning, no flow/
'  occur/pagination). Native C API DLL wrapper style (wrappers\vb6\CPDF.cls),
'  ZERO extra wrapper modules -- same convention every other examples\Vb6\*
'  driver in this project uses (see acroform\form_fields, hello_world).
'
'  Mirrors examples\delphi\xfa\01_basic_positioned_form\01_basic_positioned_form.dpr's
'  call sequence exactly:
'    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
'    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
'
'  Reads the already pre-split packet files
'  01_basic_positioned_form.template.xml / .datasets.xml (raw <template>/
'  <xfa:datasets> subtree bytes, extracted once from the source .xdp by
'  examples\delphi\xfa\split_xfa_packets.exe) -- no XML parsing needed here,
'  they are just read as raw bytes and handed straight to pdfCreateXFAStreamA.
'
'  pdf.RenderXFAForm() / pdf.CreateXFAStream() / pdf.XFAFormPageCount() /
'  pdf.SetXFARenderMode() are hand-added to wrappers\vb6\CPDF.cls for this
'  tour (2026-07-25) -- the engine's pdfRenderXFAForm/pdfSetXFARenderMode/
'  pdfXFAFormPageCount exports post-date the VB6 wrapper's last regeneration
'  (every other wrapper -- Delphi/C/C#/VB.NET/Python -- already had them).
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

    Debug.Print "=== 01_basic_positioned_form.xdp -> output.pdf ==="

    LoadFileBytes App.Path & "\01_basic_positioned_form.template.xml", templateBuf, haveTemplate
    LoadFileBytes App.Path & "\01_basic_positioned_form.datasets.xml", datasetsBuf, haveDatasets

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

    outFile = App.Path & "\output.pdf"
    pdf.OpenOutputFile outFile
    If pdf.CloseFile() Then
        Debug.Print "OK: wrote " & outFile
    Else
        Debug.Print "pdfCloseFile FAILED"
    End If

    Debug.Print "RESULT|01_basic_positioned_form=" & pages
End Sub

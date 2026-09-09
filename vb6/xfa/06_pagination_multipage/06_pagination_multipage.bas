Attribute VB_Name = "mod06PaginationMultipage"
Option Explicit
' ============================================================================
'  06_pagination_multipage -- VB6 port of the LumasPDF XFA "flavor tour"
'  example 6 of 10: MULTI-PAGE PAGINATION. Native C API DLL wrapper style
'  (wrappers\vb6\CPDF.cls), ZERO extra wrapper modules -- same convention as
'  every other examples\Vb6\* driver in this project.
'
'  A 70-line-item "Invoice Line Items" report, pageSet/pageArea/contentArea
'  overflow across pages with leader/trailer "continued" banners. Hand-derived
'  page count (see examples\delphi\xfa\06_pagination_multipage\README.md) is
'  4. Mirrors the Delphi driver's own CheckPageCount=4 assertion: this driver
'  calls pdf.XFAFormPageCount() as a PRE-FLIGHT check (before any AppendPage,
'  same as pdfXFAFormPageCount in the .dpr) and again compares the actual
'  pdf.RenderXFAForm() return value against the same expected value.
'
'  Mirrors examples\delphi\xfa\06_pagination_multipage\06_pagination_multipage.dpr's
'  call sequence exactly: pdfNewPDF -> pdfCreateNewPDFA ->
'  pdfCreateXFAStreamA('template',...) -> pdfCreateXFAStreamA('datasets',...)
'  -> pdfXFAFormPageCount (pre-flight) -> pdfRenderXFAForm -> pdfCloseFile.
'  Reads the pre-split packet files 06_pagination_multipage.template.xml /
'  .datasets.xml as raw bytes -- no XML parsing needed.
' ============================================================================

Private Const EXPECTED_PAGE_COUNT As Long = 4

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
    Dim idx As Long, pages As Long, preCount As Long
    Dim outFile As String

    Debug.Print "=== 06_pagination_multipage.xdp -> 06_pagination_multipage.pdf ==="

    LoadFileBytes App.Path & "\06_pagination_multipage.template.xml", templateBuf, haveTemplate
    LoadFileBytes App.Path & "\06_pagination_multipage.datasets.xml", datasetsBuf, haveDatasets

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

    preCount = pdf.XFAFormPageCount()
    Debug.Print "pdfXFAFormPageCount (pre-flight, before any AppendPage) -> " & preCount
    If preCount <> EXPECTED_PAGE_COUNT Then
        Debug.Print "PAGECOUNT-MISMATCH: expected " & EXPECTED_PAGE_COUNT & " got " & preCount
    End If

    pages = pdf.RenderXFAForm()
    Debug.Print "pdfRenderXFAForm -> " & pages
    If pages < 0 Then
        Debug.Print "pdfRenderXFAForm FAILED, code " & pages
        Exit Sub
    End If
    If pages <> EXPECTED_PAGE_COUNT Then
        Debug.Print "RENDER-PAGECOUNT-MISMATCH: pre-flight said " & EXPECTED_PAGE_COUNT & " but render produced " & pages
    End If

    outFile = App.Path & "\06_pagination_multipage.pdf"
    pdf.OpenOutputFile outFile
    If pdf.CloseFile() Then
        Debug.Print "OK: wrote " & outFile & " (" & pages & " page(s))"
    Else
        Debug.Print "pdfCloseFile FAILED"
    End If

    Debug.Print "RESULT|06_pagination_multipage=" & pages
End Sub

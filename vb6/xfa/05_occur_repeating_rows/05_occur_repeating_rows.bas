Attribute VB_Name = "mod05OccurRepeatingRows"
Option Explicit
' ============================================================================
'  05_occur_repeating_rows -- VB6 port of the LumasPDF XFA "flavor tour"
'  example 5 of 10: OCCUR/REPEAT DATA-DRIVEN ROW CLONING. Native C API DLL
'  wrapper style (wrappers\vb6\CPDF.cls), ZERO extra wrapper modules -- same
'  convention as every other examples\Vb6\* driver in this project.
'
'  <occur min="1" max="-1"/> instantiates one repeating "Item" row per
'  matching dataset record (7 rows, an "Expense Report"), each instance
'  independently bound to its own record and independently re-running its
'  own calculate script (LineTotal = Qty * UnitPrice). All of this happens
'  inside the engine during pdfRenderXFAForm; this driver just drives the
'  same real-DLL pipeline every other example in the tour uses.
'
'  Mirrors examples\delphi\xfa\05_occur_repeating_rows\05_occur_repeating_rows.dpr's
'  call sequence exactly: pdfNewPDF -> pdfCreateNewPDFA ->
'  pdfCreateXFAStreamA('template',...) -> pdfCreateXFAStreamA('datasets',...)
'  -> pdfRenderXFAForm -> pdfCloseFile. Reads the pre-split packet files
'  05_occur_repeating_rows.template.xml / .datasets.xml as raw bytes -- no
'  XML parsing needed.
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

    Debug.Print "=== 05_occur_repeating_rows.xdp -> 05_occur_repeating_rows.pdf ==="

    LoadFileBytes App.Path & "\05_occur_repeating_rows.template.xml", templateBuf, haveTemplate
    LoadFileBytes App.Path & "\05_occur_repeating_rows.datasets.xml", datasetsBuf, haveDatasets

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

    outFile = App.Path & "\05_occur_repeating_rows.pdf"
    pdf.OpenOutputFile outFile
    If pdf.CloseFile() Then
        Debug.Print "OK: wrote " & outFile
    Else
        Debug.Print "pdfCloseFile FAILED"
    End If

    Debug.Print "RESULT|05_occur_repeating_rows=" & pages
End Sub

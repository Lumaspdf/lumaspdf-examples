Attribute VB_Name = "modTextExtraction2"
Option Explicit
' ============================================================================
'  content_parser / text_extraction2 -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper
'  modules. Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in .vbp).
'  Extracts text by driving ParseContent. ParseContent is a native callback;
'  the AX server delivers it as COM events via pdf.ParseContentEvents -> the
'  WithEvents sink class TextExtraction2Evt. The ShowText operator arrives
'  ALREADY DECODED to Unicode, so extraction is: collect each run per page.
'  Output is UTF-8 (with BOM) written via ADODB.Stream. One COM event per
'  operator is slow, so a small page range (MAXPAGES) is processed.
' ============================================================================

Public Const MAXPAGES As Long = 5

Public Sub Main()
    Dim pdf As New CPDF
    Dim ev As New TextExtraction2Evt
    Dim inFile As String, outFile As String
    Dim total As Long, nPages As Long, i As Long
    Dim stm As Object

    inFile = "E:\LUMASPDFSDK\dynapdf_help.pdf"
    outFile = App.Path & "\out.txt"

    Set ev.Pdf = New CPDF
' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    If pdf.OpenImportFile(inFile, ptOpen, "") < 0 Then
        Debug.Print "Input file not found: " & inFile
        Exit Sub
    End If
    pdf.ImportPDFFile 1, 1, 1
    pdf.FlattenAnnots affMarkupAnnots
    pdf.FlattenForm

    total = pdf.GetPageCount
    nPages = total
    If nPages > MAXPAGES Then nPages = MAXPAGES

    ' UTF-8 text output (BOM) built in a stream.
    Set stm = CreateObject("ADODB.Stream")
    stm.Type = 2 : stm.Charset = "utf-8" : stm.Open

    For i = 1 To nPages
        ev.PageText = "" : ev.LastY = -1E+30
        pdf.EditPage i
        pdf.ParseContentEvents pfNone     ' -> Pdf_OnParse* events for this page
        pdf.EndPage
        stm.WriteText "----- Page " & i & " -----" & vbCrLf
        stm.WriteText ev.PageText & vbCrLf & vbCrLf
    Next

    stm.SaveToFile outFile, 2   ' overwrite
    stm.Close
    Debug.Print "Text extracted from " & nPages & " of " & total & " page(s) -> " & outFile
End Sub

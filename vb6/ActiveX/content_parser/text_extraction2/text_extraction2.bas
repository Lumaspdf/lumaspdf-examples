Attribute VB_Name = "modTextExtraction2"
Option Explicit
' ============================================================================
'  content_parser / text_extraction2 (ActiveX) -- LumasPdf ActiveX/COM
'  component (LumasPdf.PDF).
'
'  Same feature as the flat-DLL "text_extraction2" example (examples\Vb6\
'  content_parser\text_extraction2\text_extraction2.bas, read-only reference):
'  extracts text by driving ParseContentEvents, delivered as COM events ->
'  the WithEvents sink class TextExtraction2Evt. The ShowText operator
'  arrives ALREADY DECODED to Unicode, so extraction is: collect each run per
'  page. Output is UTF-8 (with BOM) written via ADODB.Stream. One COM event
'  per operator is slow, so a small page range (MAXPAGES) is processed.
'
'  NOTE ON BINDING: see image_extractionEvt.cls -- this example genuinely
'  needs early binding (one project Reference) for WithEvents.
' ============================================================================

Public Const MAXPAGES As Long = 5

Public Sub Main()
    On Error GoTo ErrHandler

    Dim ev As New TextExtraction2Evt
    Dim inFile As String, outFile As String
    Dim total As Long, nPages As Long, i As Long
    Dim stm As Object

    inFile = "E:\LUMASPDFSDK\dynapdf_help.pdf"
    outFile = App.path & "\out.txt"

    Set ev.Pdf = New LumasPdfAX.LumasPDF
    ev.Pdf.RaiseExceptions = True

    ev.Pdf.CreateNewPDFW ""
    ev.Pdf.SetImportFlags ifImportAll Or ifImportAsPage
    If ev.Pdf.OpenImportFileW(inFile, ptOpen, "") < 0 Then
        Debug.Print "Input file not found: " & inFile
        Exit Sub
    End If
    ev.Pdf.ImportPDFFile 1, 1, 1
    ev.Pdf.FlattenAnnots affMarkupAnnots
    ev.Pdf.FlattenForm

    total = ev.Pdf.GetPageCount
    nPages = total
    If nPages > MAXPAGES Then nPages = MAXPAGES

    ' UTF-8 text output (BOM) built in a stream.
    Set stm = CreateObject("ADODB.Stream")
    stm.Type = 2 : stm.Charset = "utf-8" : stm.Open

    For i = 1 To nPages
        ev.PageText = "" : ev.LastY = -1E+30
        ev.Pdf.EditPage i
        ev.Pdf.ParseContentEvents pfNone     ' -> Pdf_OnParse* events for this page
        ev.Pdf.EndPage
        stm.WriteText "----- Page " & i & " -----" & vbCrLf
        stm.WriteText ev.PageText & vbCrLf & vbCrLf
    Next

    stm.SaveToFile outFile, 2   ' overwrite
    stm.Close
    Debug.Print "Text extracted from " & nPages & " of " & total & " page(s) -> " & outFile
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not ev Is Nothing Then
        If Not ev.Pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & ev.Pdf.LastErrorCode & " " & ev.Pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "text_extraction2 (ActiveX)"
End Sub

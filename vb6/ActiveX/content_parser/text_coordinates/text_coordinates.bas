Attribute VB_Name = "modTextCoordinates"
Option Explicit
' ============================================================================
'  content_parser / text_coordinates (ActiveX) -- LumasPdf ActiveX/COM
'  component (LumasPdf.PDF).
'
'  Same feature as the flat-DLL "text_coordinates" example (examples\Vb6\
'  content_parser\text_coordinates\text_coordinates.bas, read-only reference):
'  draws a baseline under every text record, alternating blue/red.
'  ParseContentEvents is delivered as COM events -> the WithEvents sink class
'  TextCoordinatesEvt (Pdf_OnParseShowText). Each run arrives with its start
'  matrix (M20/M21 = origin) + total advance Width -- exactly what a baseline
'  underline needs. A small page range (MAXPAGES) is processed.
'
'  NOTE ON BINDING: see image_extractionEvt.cls -- this example genuinely
'  needs early binding (one project Reference) for WithEvents.
' ============================================================================

Public Const MAXPAGES As Long = 15

Public Sub Main()
    On Error GoTo ErrHandler

    Dim ev As New TextCoordinatesEvt
    Dim inFile As String, outFile As String
    Dim total As Long, nPages As Long, i As Long

    inFile = "E:\LUMASPDFSDK\sample_multipage.pdf"
    outFile = App.path & "\out.pdf"

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

    ev.Toggle = 0
    total = ev.Pdf.GetPageCount
    nPages = total
    If nPages > MAXPAGES Then nPages = MAXPAGES

    For i = 1 To nPages
        ev.Pdf.EditPage i
        ev.Pdf.SetLineWidth 0.5
        ev.Pdf.ParseContentEvents pfNone     ' -> Pdf_OnParse* events (draws baselines)
        ev.Pdf.EndPage
    Next

    If ev.Pdf.HaveOpenDoc <> 0 Then
        ev.Pdf.OpenOutputFileW outFile
    End If
    ev.Pdf.CloseFile
    Debug.Print "Baselines drawn under text records over " & nPages & " of " & total & " page(s) -> " & outFile
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not ev Is Nothing Then
        If Not ev.Pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & ev.Pdf.LastErrorCode & " " & ev.Pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "text_coordinates (ActiveX)"
End Sub

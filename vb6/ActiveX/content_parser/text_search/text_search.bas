Attribute VB_Name = "modTextSearch"
Option Explicit
' ============================================================================
'  content_parser / text_search (ActiveX) -- LumasPdf ActiveX/COM component
'  (LumasPdf.PDF).
'
'  Same feature as the flat-DLL "text_search" example (examples\Vb6\
'  content_parser\text_search\text_search.bas, read-only reference): finds
'  "PDF" and highlights every match. ParseContentEvents is delivered as COM
'  events -> the WithEvents sink class TextSearchEvt (Pdf_OnParse* handlers).
'  Each ShowText run arrives already decoded, so we search the run text and
'  draw a proportional yellow highlight (multiply blend keeps the text
'  readable). One COM event per operator is slow, so a small page range
'  (MAXPAGES) is processed to demonstrate the mechanism.
'
'  NOTE ON BINDING: see image_extractionEvt.cls -- this example genuinely
'  needs early binding (one project Reference) for WithEvents.
' ============================================================================

Public Const MAXPAGES As Long = 20

Public Sub Main()
    On Error GoTo ErrHandler

    Dim ev As New TextSearchEvt
    Dim inFile As String, outFile As String, arr As Variant
    Dim total As Long, nPages As Long, i As Long, gTotal As Long

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

    ' A multiply-blend ExtGState so highlights darken but keep the text visible.
    ' (CreateExtGState via the field-overlay array: index 1 = BlendMode.)
    arr = Array(Empty, bmMultiply)
    ev.GS = ev.Pdf.CreateExtGState(arr)

    ev.TextSize = 10
    total = ev.Pdf.GetPageCount
    nPages = total
    If nPages > MAXPAGES Then nPages = MAXPAGES

    gTotal = 0
    For i = 1 To nPages
        ev.PageHits = 0
        ev.Pdf.EditPage i
        ev.Pdf.SetExtGState ev.GS
        ev.Pdf.SetFillColor RGB(255, 255, 0)
        ev.Pdf.ParseContentEvents pfNone     ' -> Pdf_OnParse* events (draws highlights)
        ev.Pdf.EndPage
        If ev.PageHits > 0 Then
            Debug.Print "Found ""PDF"" on page " & i & ": " & ev.PageHits & " time(s)"
            gTotal = gTotal + ev.PageHits
        End If
    Next

    If ev.Pdf.HaveOpenDoc <> 0 Then
        ev.Pdf.OpenOutputFileW outFile
    End If
    ev.Pdf.CloseFile
    Debug.Print "Total matches highlighted: " & gTotal & " over " & nPages & " of " & total & " page(s) -> " & outFile
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not ev Is Nothing Then
        If Not ev.Pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & ev.Pdf.LastErrorCode & " " & ev.Pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "text_search (ActiveX)"
End Sub

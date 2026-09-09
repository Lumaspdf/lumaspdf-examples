Attribute VB_Name = "modTextSearch"
Option Explicit
' ============================================================================
'  content_parser / text_search -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Finds "PDF" and highlights every match. ParseContent is a native callback;
'  the AX server delivers it as COM events via pdf.ParseContentEvents -> the
'  WithEvents sink class TextSearchEvt (Pdf_OnParse* handlers). Each ShowText
'  run arrives already decoded, so we search the run text and draw a
'  proportional yellow highlight (multiply blend keeps the text readable).
'  One COM event per operator is slow, so a small page range (MAXPAGES) is
'  processed to demonstrate the mechanism.
' ============================================================================

Public Const MAXPAGES As Long = 20

Public Sub Main()
    Dim pdf As New CPDF
    Dim ev As New TextSearchEvt
    Dim inFile As String, outFile As String, arr As Variant
    Dim total As Long, nPages As Long, i As Long, gTotal As Long

    inFile = "E:\LUMASPDFSDK\sample_multipage.pdf"
    outFile = App.Path & "\out.pdf"

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

    ' A multiply-blend ExtGState so highlights darken but keep the text visible.
    ' (CreateExtGState via the field-overlay array: index 1 = BlendMode.)
    arr = Array(Empty, bmMultiply)
    ev.GS = pdf.CreateExtGState(arr)

    ev.TextSize = 10
    total = pdf.GetPageCount
    nPages = total
    If nPages > MAXPAGES Then nPages = MAXPAGES

    gTotal = 0
    For i = 1 To nPages
        ev.PageHits = 0
        pdf.EditPage i
        pdf.SetExtGState ev.GS
        pdf.SetFillColor RGB(255, 255, 0)
        pdf.ParseContentEvents pfNone     ' -> Pdf_OnParse* events (draws highlights)
        pdf.EndPage
        If ev.PageHits > 0 Then
            Debug.Print "Found ""PDF"" on page " & i & ": " & ev.PageHits & " time(s)"
            gTotal = gTotal + ev.PageHits
        End If
    Next

    If pdf.HaveOpenDoc <> 0 Then
        pdf.OpenOutputFile outFile
    End If
    pdf.CloseFile
    Debug.Print "Total matches highlighted: " & gTotal & " over " & nPages & " of " & total & " page(s) -> " & outFile
End Sub

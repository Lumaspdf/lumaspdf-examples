Attribute VB_Name = "modTextCoordinates"
Option Explicit
' ============================================================================
'  content_parser / text_coordinates -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper
'  modules. Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in .vbp).
'  Draws a baseline under every text record, alternating blue/red. ParseContent
'  is delivered as COM events via pdf.ParseContentEvents -> the WithEvents sink
'  class TextCoordinatesEvt (Pdf_OnParseShowText). Each run arrives with its
'  start matrix (M20/M21 = origin) + total advance Width -- exactly what a
'  baseline underline needs. A small page range (MAXPAGES) is processed.
' ============================================================================

Public Const MAXPAGES As Long = 15

Public Sub Main()
    Dim pdf As New CPDF
    Dim ev As New TextCoordinatesEvt
    Dim inFile As String, outFile As String
    Dim total As Long, nPages As Long, i As Long

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

    ev.Toggle = 0
    total = pdf.GetPageCount
    nPages = total
    If nPages > MAXPAGES Then nPages = MAXPAGES

    For i = 1 To nPages
        pdf.EditPage i
        pdf.SetLineWidth 0.5
        pdf.ParseContentEvents pfNone     ' -> Pdf_OnParse* events (draws baselines)
        pdf.EndPage
    Next

    If pdf.HaveOpenDoc <> 0 Then
        pdf.OpenOutputFile outFile
    End If
    pdf.CloseFile
    Debug.Print "Baselines drawn under text records over " & nPages & " of " & total & " page(s) -> " & outFile
End Sub

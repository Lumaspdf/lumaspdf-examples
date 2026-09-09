Attribute VB_Name = "modImageExtraction"
Option Explicit
' ============================================================================
'  content_parser / image_extraction -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper
'  modules. Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in .vbp).
'  Detects & reports every image on a page by driving ParseContent, delivered
'  as COM events via pdf.ParseContentEvents -> the WithEvents sink class
'  ImageExtractionEvt (Pdf_OnParseInsertImage). The InsertImage event carries
'  each image's geometry (width/height/bpp + the four destination corners) --
'  enough to DETECT and REPORT every image (writes images.csv).
'  HONEST LIMITATION: rebuilding the actual TIFF requires the decompressed
'  PIXEL BUFFER, which a COM event cannot carry; so this reports image metadata
'  rather than re-emitting pixels -- the same graceful degradation the .vbs used.
'  A small page range (MAXPAGES) is processed.
' ============================================================================

Public Const MAXPAGES As Long = 60

Public Sub Main()
    Dim pdf As New CPDF
    Dim ev As New ImageExtractionEvt
    Dim inFile As String, outFile As String
    Dim total As Long, nPages As Long, i As Long, ff As Integer

    inFile = "E:\LUMASPDFSDK\dynapdf_help.pdf"
    outFile = App.Path & "\images.csv"

    Set ev.Pdf = New CPDF
' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    If pdf.OpenImportFile(inFile, ptOpen, "") < 0 Then
        Debug.Print "Input file not found: " & inFile
        Exit Sub
    End If
    pdf.ImportPDFFile 1, 1, 1

    ev.Count = 0
    ev.Csv = "Page,Width,Height,BitsPerPixel,X1,Y1,X2,Y2,X3,Y3,X4,Y4" & vbCrLf

    total = pdf.GetPageCount
    nPages = total
    If nPages > MAXPAGES Then nPages = MAXPAGES

    For i = 1 To nPages
        ev.Page = i
        pdf.EditPage i
        pdf.ParseContentEvents pfNone     ' -> Pdf_OnParse* events (records images)
        pdf.EndPage
    Next

    ff = FreeFile
    Open outFile For Output As #ff
    Print #ff, ev.Csv;
    Close #ff
    Debug.Print "Detected " & ev.Count & " image(s) over " & nPages & " of " & total & " page(s) -> " & outFile
End Sub

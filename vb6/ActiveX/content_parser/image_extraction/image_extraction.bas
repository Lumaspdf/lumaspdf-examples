Attribute VB_Name = "modImageExtraction"
Option Explicit
' ============================================================================
'  content_parser / image_extraction (ActiveX) -- LumasPdf ActiveX/COM
'  component (LumasPdf.PDF).
'
'  Same feature as the flat-DLL "image_extraction" example (examples\Vb6\
'  content_parser\image_extraction\image_extraction.bas, read-only reference):
'  detects & reports every image on a page by driving ParseContentEvents,
'  delivered as COM events via pdf.ParseContentEvents -> the WithEvents sink
'  class ImageExtractionEvt (Pdf_OnParseInsertImage). The InsertImage event
'  carries each image's geometry (width/height/bpp + the four destination
'  corners) -- enough to DETECT and REPORT every image (writes images.csv).
'  HONEST LIMITATION (same as the flat-DLL reference): rebuilding the actual
'  TIFF requires the decompressed PIXEL BUFFER, which a COM event cannot
'  carry; so this reports image metadata rather than re-emitting pixels.
'  A small page range (MAXPAGES) is processed.
'
'  NOTE ON BINDING: unlike the other ActiveX examples in this codebase (which
'  use late-bound CreateObject("LumasPdf.PDF") with no project reference),
'  this example's feature genuinely requires VB6's WithEvents to receive the
'  ParseContentEvents callbacks -- and WithEvents is only usable on a
'  compile-time-typed (early-bound) variable, which requires one project
'  Reference to the LumasPdfAX type library (see the .vbp). This is the one
'  place a project reference is unavoidable, not a style choice.
'
'  Mapping from the flat CPDF.cls calls (dropping the "pdf" prefix and the
'  handle argument; identical method names otherwise):
'    pdf.CreateNewPDF ""                -> pdf.CreateNewPDFW("")
'    pdf.OpenImportFile(f, pt, pw)      -> pdf.OpenImportFileW(f, pt, pw)
'    everything else (SetImportFlags, ImportPDFFile, GetPageCount, EditPage,
'    ParseContentEvents, EndPage) -> unchanged (already bare ActiveX names)
' ============================================================================

Public Const MAXPAGES As Long = 60

Public Sub Main()
    On Error GoTo ErrHandler

    Dim ev As New ImageExtractionEvt
    Dim inFile As String, outFile As String
    Dim total As Long, nPages As Long, i As Long, ff As Integer

    inFile = "E:\LUMASPDFSDK\dynapdf_help.pdf"
    outFile = App.path & "\images.csv"

    Set ev.Pdf = New LumasPdfAX.LumasPDF
    ev.Pdf.RaiseExceptions = True

    ev.Pdf.CreateNewPDFW ""
    ev.Pdf.SetImportFlags ifImportAll Or ifImportAsPage
    If ev.Pdf.OpenImportFileW(inFile, ptOpen, "") < 0 Then
        Debug.Print "Input file not found: " & inFile
        Exit Sub
    End If
    ev.Pdf.ImportPDFFile 1, 1, 1

    ev.Count = 0
    ev.Csv = "Page,Width,Height,BitsPerPixel,X1,Y1,X2,Y2,X3,Y3,X4,Y4" & vbCrLf

    total = ev.Pdf.GetPageCount
    nPages = total
    If nPages > MAXPAGES Then nPages = MAXPAGES

    For i = 1 To nPages
        ev.Page = i
        ev.Pdf.EditPage i
        ev.Pdf.ParseContentEvents pfNone     ' -> Pdf_OnParse* events (records images)
        ev.Pdf.EndPage
    Next

    ff = FreeFile
    Open outFile For Output As #ff
    Print #ff, ev.Csv;
    Close #ff
    Debug.Print "Detected " & ev.Count & " image(s) over " & nPages & " of " & total & " page(s) -> " & outFile
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not ev Is Nothing Then
        If Not ev.Pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & ev.Pdf.LastErrorCode & " " & ev.Pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "image_extraction (ActiveX)"
End Sub

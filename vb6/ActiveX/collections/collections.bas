Attribute VB_Name = "modCollections"
Option Explicit
' ============================================================================
'  collections (ActiveX) -- LumasPdf ActiveX/COM component (LumasPdf.PDF),
'  late-bound, no project reference required.
'
'  Same feature as the flat-DLL "collections" example: imports a cover page,
'  creates a PDF portfolio (collection) and attaches three files to it.
'
'  Mapping from the flat CPDF.cls calls (see the read-only reference at
'  examples\Vb6\collections\collections.bas):
'    pdf.CreateNewPDF ""                  -> pdf.CreateNewPDFA("")
'    pdf.SetImportFlags flags             -> pdf.SetImportFlags flags   (same)
'    pdf.OpenImportFile(path, pt, pwd)    -> pdf.OpenImportFileA(path, pt, pwd)
'    pdf.ImportPDFFile/.CloseImportFile    -> unchanged (already bare names)
'    pdf.CreateCollection civTile          -> unchanged
'    pdf.AttachFileA(...)                  -> unchanged (already the A export)
'    pdf.SetColDefFile/.HaveOpenDoc         -> unchanged
'    pdf.OpenOutputFile(path)               -> pdf.OpenOutputFileA(path)
'    pdf.CloseFile                          -> unchanged
'  The enum values below (ifImportAll, ifImportAsPage, ptOpen, civTile) are
'  copied verbatim from wrappers\vb6\LumasPDFInt.bas / LumasPdfAX.ridl since a
'  late-bound Object has no typelib enums available at compile time.
' ============================================================================

Const ifImportAll As Long = &HFFFFFFE      ' TImportFlags: default (import everything)
Const ifImportAsPage As Long = &H80000000  ' TImportFlags: don't convert page to template
Const ptOpen As Long = 0                   ' TPwdType: open password
Const civTile As Long = 2                  ' TCollectionInitialView: tiles

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object                      ' LumasPdf.PDF (late-bound)
    Dim ef As Long, outFile As String, tf As String
    Dim h As Long

    tf = "E:\LUMASPDFSDK\examples\test_files\"

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True             ' turn engine errors into VB6 errors

    If Not CBool(pdf.CreateNewPDFA("")) Then Err.Raise vbObjectError + 1, , "CreateNewPDFA failed"

    ' The page of this file is shown when opening the file with an older version of Adobe's Acrobat.
    ' Otherwise, the default document of the collection is opened. Click on "Cover sheet" to view the
    ' contents of this page.
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    h = pdf.OpenImportFileA(tf & "collection_en.pdf", ptOpen, "")
    If h < 0 Then
        Debug.Print "Input file """ & tf & "collection_en.pdf"" not found!"
        Exit Sub
    End If
    pdf.ImportPDFFile 1, 1, 1
    pdf.CloseImportFile
    pdf.CreateCollection civTile

    ef = pdf.AttachFileA(tf & "taxform.pdf", "A PDF file...", True)
    pdf.SetColDefFile ef                   ' This file is opened when viewing the file with Acrobat 8 or later
    pdf.AttachFileA tf & "fulltest.emf", "An EMF file...", True
    pdf.AttachFileA tf & "sample.txt", "A text file...", True

    If CBool(pdf.HaveOpenDoc()) Then
        outFile = App.path & "\out.pdf"
        If Not CBool(pdf.OpenOutputFileA(outFile)) Then Exit Sub
    End If
    pdf.CloseFile
    Debug.Print "PDF Collection """ & outFile & """ successfully created!"

    Set pdf = Nothing
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then
        extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "collections (ActiveX)"
End Sub

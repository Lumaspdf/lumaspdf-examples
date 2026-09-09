Attribute VB_Name = "modCollections2"
Option Explicit
' ============================================================================
'  collections2 (ActiveX) -- LumasPdf ActiveX/COM component (LumasPdf.PDF),
'  late-bound, no project reference required.
'
'  Same feature as the flat-DLL "collections2" example: like collections, but
'  adds sortable collection fields (index, file name, size, mod date) and
'  per-item field values, then validates the collection.
'
'  Mapping from the flat CPDF.cls calls (see the read-only reference at
'  examples\Vb6\collections2\collections2.bas):
'    pdf.CreateNewPDF ""                      -> pdf.CreateNewPDFA("")
'    pdf.OpenImportFile(path, pt, pwd)        -> pdf.OpenImportFileA(path, pt, pwd)
'    pdf.CreateCollectionFieldA(...)           -> unchanged (already the A export)
'    pdf.OpenOutputFile(path)                  -> pdf.OpenOutputFileA(path)
'    everything else (SetImportFlags, ImportPDFFile, CloseImportFile,
'    CreateCollection, SetColSortField, AttachFileA, SetColDefFile,
'    CreateColItemNumber, CheckCollection, HaveOpenDoc, CloseFile) -> unchanged
'  Enum values (ifImportAll, ifImportAsPage, ptOpen, civTile, cisCustomNumber,
'  cisFileName, cisSize, cisModDate) copied verbatim from wrappers\vb6\
'  LumasPDFInt.bas / LumasPdfAX.ridl since late-bound Objects have no
'  compile-time typelib enums.
' ============================================================================

Const ifImportAll As Long = &HFFFFFFE      ' TImportFlags: default (import everything)
Const ifImportAsPage As Long = &H80000000  ' TImportFlags: don't convert page to template
Const ptOpen As Long = 0                   ' TPwdType: open password
Const civTile As Long = 2                  ' TCollectionInitialView: tiles
Const cisCustomNumber As Long = 6          ' TColItemSubtype
Const cisFileName As Long = 2
Const cisSize As Long = 4
Const cisModDate As Long = 3

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object                      ' LumasPdf.PDF (late-bound)
    Dim ef As Long, outFile As String, tf As String
    Dim h As Long

    tf = "E:\LUMASPDFSDK\examples\test_files\"

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True             ' turn engine errors into VB6 errors

    If Not CBool(pdf.CreateNewPDFA("")) Then Err.Raise vbObjectError + 1, , "CreateNewPDFA failed"

    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    h = pdf.OpenImportFileA(tf & "collection_en.pdf", ptOpen, "")
    If h < 0 Then
        Debug.Print "Input file """ & tf & "collection_en.pdf"" not found!"
        Exit Sub
    End If
    pdf.ImportPDFFile 1, 1, 1
    pdf.CloseImportFile
    pdf.CreateCollection civTile

    ' A user defined field Index so that we can sort it in every order we want.
    ef = pdf.CreateCollectionFieldA(cisCustomNumber, 0, "File index", "Index", False, True)
    pdf.SetColSortField ef, 1

    pdf.CreateCollectionFieldA cisFileName, 1, "File name", "", True, True
    pdf.CreateCollectionFieldA cisSize, 2, "File size", "", True, False
    pdf.CreateCollectionFieldA cisModDate, 3, "Modification date", "", True, False

    ef = pdf.AttachFileA(tf & "taxform.pdf", "A PDF file...", True)
    pdf.SetColDefFile ef                   ' This file is opened when viewing the file with Acrobat 8 or later
    pdf.CreateColItemNumber ef, "Index", 0, ""

    ef = pdf.AttachFileA(tf & "fulltest.emf", "An EMF file...", True)
    pdf.CreateColItemNumber ef, "Index", 1, ""

    ef = pdf.AttachFileA(tf & "sample.txt", "A text file...", True)
    pdf.CreateColItemNumber ef, "Index", 2, ""

    ' Let's check whether the collection is valid.
    pdf.CheckCollection

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
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "collections2 (ActiveX)"
End Sub

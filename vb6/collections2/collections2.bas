Attribute VB_Name = "modCollections2"
Option Explicit
' ============================================================================
'  collections2 -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Like collections, but adds sortable collection fields (index, file name,
'  size, mod date) and per-item field values, then validates the collection.
'  Enums come from the typelib.
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim ef As Long, outFile As String, tf As String

    tf = "E:\LUMASPDFSDK\examples\test_files\"

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    If pdf.OpenImportFile(tf & "collection_en.pdf", ptOpen, "") < 0 Then
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
    pdf.SetColDefFile ef              ' This file is opened when viewing the file with Acrobat 8 or later
    pdf.CreateColItemNumber ef, "Index", 0, ""

    ef = pdf.AttachFileA(tf & "fulltest.emf", "An EMF file...", True)
    pdf.CreateColItemNumber ef, "Index", 1, ""

    ef = pdf.AttachFileA(tf & "sample.txt", "A text file...", True)
    pdf.CreateColItemNumber ef, "Index", 2, ""

    ' Let's check whether the collection is valid.
    pdf.CheckCollection

    If pdf.HaveOpenDoc <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
    End If
    pdf.CloseFile
    Debug.Print "PDF Collection """ & outFile & """ successfully created!"
End Sub

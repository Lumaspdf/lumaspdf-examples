Attribute VB_Name = "modCollections"
Option Explicit
' ============================================================================
'  collections -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Imports a cover page, creates a PDF portfolio (collection) and attaches
'  three files to it. Enums come from the typelib.
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim ef As Long, outFile As String, tf As String

    tf = "E:\LUMASPDFSDK\examples\test_files\"

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    ' The page of this file is shown when opening the file with an older version of Adobe's Acrobat.
    ' Otherwise, the default document of the collection is opened. Click on "Cover sheet" to view the
    ' contents of this page.
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    If pdf.OpenImportFile(tf & "collection_en.pdf", ptOpen, "") < 0 Then
        Debug.Print "Input file """ & tf & "collection_en.pdf"" not found!"
        Exit Sub
    End If
    pdf.ImportPDFFile 1, 1, 1
    pdf.CloseImportFile
    pdf.CreateCollection civTile

    ef = pdf.AttachFileA(tf & "taxform.pdf", "A PDF file...", True)
    pdf.SetColDefFile ef              ' This file is opened when viewing the file with Acrobat 8 or later
    pdf.AttachFileA tf & "fulltest.emf", "An EMF file...", True
    pdf.AttachFileA tf & "sample.txt", "A text file...", True

    If pdf.HaveOpenDoc <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
    End If
    pdf.CloseFile
    Debug.Print "PDF Collection """ & outFile & """ successfully created!"
End Sub

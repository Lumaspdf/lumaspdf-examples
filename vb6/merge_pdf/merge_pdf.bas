Attribute VB_Name = "modMergePdf"
Option Explicit
' ============================================================================
'  merge_pdf -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt). Generic code to merge arbitrary
'  PDF files (with special handling for interactive forms / PDF collections).
' pdf.RaiseExceptions = True
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim i As Long, destPage As Long
    Dim first As Boolean, haveXFA As Boolean, isCollection As Boolean
    Dim outFile As String, files(0 To 1) As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""                           ' output file opened later

    pdf.SetPageCoords pcTopDown

    pdf.Append
        pdf.SetFont "Helvetica", fsRegular, 14#, 0, cp1252
        pdf.WriteFTextEx 50#, 50#, pdf.GetPageWidth - 100#, -1#, taJustify, _
            "The following pages were imported from different PDF files. DynaPDF adjusts the destinations of link annotations and bookmarks so that " & _
            "all destinations refer to the new page numbers after import." & Chr$(13) & Chr$(13) & _
            "Entire PDF files can be easily merged with ImportPDFFile() but it is also possible to import only specific pages of an arbitrary number " & _
            "of PDF files. You can also add further pages or edit imported pages if necessary. An existing page can be opened for editing with EditPage()."
    pdf.EndPage

    first = True
    destPage = 1
    haveXFA = False
    isCollection = False

    files(0) = App.Path & "\license.pdf"
    files(1) = App.Path & "\dynapdf_help.pdf"

    ' Generic code to merge arbitrary PDF files.
    For i = 0 To 1
        If pdf.OpenImportFile(files(i), ptOpen, "") < 0 Then Exit Sub
        If first Then
            first = False
            haveXFA = (pdf.GetInIsXFAForm <> 0)
            isCollection = (pdf.GetInIsCollection <> 0)
            destPage = pdf.ImportPDFFile(destPage + 1, 1#, 1#)
            If destPage < 0 Then Exit For
        Else
            ' Special handling for PDF Collections
            If isCollection Then
                If pdf.GetInIsCollection <> 0 Then
                    ' Import the embedded files only
                    pdf.SetImportFlags ifEmbeddedFiles
                    If pdf.ImportCatalogObjects = 0 Then Exit For
                Else
                    pdf.CloseImportFile
                    ' Add the file to the collection
                    pdf.AttachFileA files(i), ExtractFileName(files(i)), 1
                End If
            Else
                If (pdf.GetInIsCollection <> 0) Or (((pdf.GetInIsXFAForm <> 0) Or (pdf.GetInFieldCount > 0)) And ((pdf.GetFieldCount > 0) Or haveXFA)) Then Exit For
                pdf.SetImportFlags ifImportAll Or ifImportAsPage  ' avoid conversion of pages to templates
                pdf.SetImportFlags2 if2UseProxy                   ' reduces the memory usage
                destPage = pdf.ImportPDFFile(destPage + 1, 1#, 1#)
                If destPage < 0 Then Exit For
            End If
        End If
        pdf.CloseImportFile
    Next i

    ' No fatal error occurred?
    If pdf.HaveOpenDoc <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

Private Function ExtractFileName(ByVal Path As String) As String
    Dim p As Long
    p = InStrRev(Path, "\")
    If p = 0 Then p = InStrRev(Path, "/")
    If p = 0 Then ExtractFileName = Path Else ExtractFileName = Mid$(Path, p + 1)
End Function

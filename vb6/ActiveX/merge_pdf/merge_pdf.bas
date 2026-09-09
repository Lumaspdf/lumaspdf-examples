Attribute VB_Name = "modMergePdf"
Option Explicit
' ============================================================================
'  merge_pdf -- LumasPdf ActiveX/COM component style (late-bound, no project
'  reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\merge_pdf -- same feature: generic code to merge arbitrary
'  PDF files (with special handling for interactive forms / PDF collections).
' ============================================================================

'--- TPageCoord ---------------------------------------------------------------
Const pcTopDown As Long = 1

'--- TFStyle / TCodepage -------------------------------------------------------
Const fsRegular As Long = &H19000000
Const cp1252 As Long = 2

'--- TTextAlign -----------------------------------------------------------------
Const taJustify As Long = 3

'--- TPwdType (ptOpen = 0) -------------------------------------------------------
Const ptOpen As Long = 0

'--- TImportFlags ---------------------------------------------------------------
Const ifImportAll As Long = &HFFFFFFE
Const ifImportAsPage As Long = &H80000000
Const ifEmbeddedFiles As Long = &H200000

'--- TImportFlags2 --------------------------------------------------------------
Const if2UseProxy As Long = &H4

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim i As Long, destPage As Long
    Dim first As Boolean, haveXFA As Boolean, isCollection As Boolean
    Dim outFile As String, files(0 To 1) As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    pdf.CreateNewPDFW ""                          ' output file opened later

    pdf.SetPageCoords pcTopDown

    pdf.Append
        pdf.SetFontW "Helvetica", fsRegular, 14#, False, cp1252
        pdf.WriteFTextExW 50#, 50#, pdf.GetPageWidth - 100#, -1#, taJustify, _
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
        If pdf.OpenImportFileW(files(i), ptOpen, "") < 0 Then Exit Sub
        If first Then
            first = False
            haveXFA = CBool(pdf.GetInIsXFAForm)
            isCollection = CBool(pdf.GetInIsCollection)
            destPage = pdf.ImportPDFFile(destPage + 1, 1#, 1#)
            If destPage < 0 Then Exit For
        Else
            ' Special handling for PDF Collections
            If isCollection Then
                If CBool(pdf.GetInIsCollection) Then
                    ' Import the embedded files only
                    pdf.SetImportFlags ifEmbeddedFiles
                    If Not pdf.ImportCatalogObjects Then Exit For
                Else
                    pdf.CloseImportFile
                    ' Add the file to the collection
                    pdf.AttachFileA files(i), ExtractFileName(files(i)), True
                End If
            Else
                If CBool(pdf.GetInIsCollection) Or ((CBool(pdf.GetInIsXFAForm) Or (pdf.GetInFieldCount > 0)) And ((pdf.GetFieldCount > 0) Or haveXFA)) Then Exit For
                pdf.SetImportFlags ifImportAll Or ifImportAsPage  ' avoid conversion of pages to templates
                pdf.SetImportFlags2 if2UseProxy                   ' reduces the memory usage
                destPage = pdf.ImportPDFFile(destPage + 1, 1#, 1#)
                If destPage < 0 Then Exit For
            End If
        End If
        pdf.CloseImportFile
    Next i

    ' No fatal error occurred?
    If pdf.HaveOpenDoc Then
        outFile = App.Path & "\out.pdf"
        If Not pdf.OpenOutputFileW(outFile) Then Exit Sub
        If pdf.CloseFile Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "merge_pdf (ActiveX)"
End Sub

Private Function ExtractFileName(ByVal Path As String) As String
    Dim p As Long
    p = InStrRev(Path, "\")
    If p = 0 Then p = InStrRev(Path, "/")
    If p = 0 Then ExtractFileName = Path Else ExtractFileName = Mid$(Path, p + 1)
End Function

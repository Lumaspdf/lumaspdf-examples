Attribute VB_Name = "modEditText"
Option Explicit
' ============================================================================
'  edit_text -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'
'  The flat VB6 original used the content parser (Psr*) to find every "PDF" in
'  the imported help file and replace it with "XDF". That find/replace is NOT
'  expressible through the registered ActiveX server from VB6:
'    * PsrFindText/PsrReplaceSelText take the 16-byte TTextSelection as a
'      packed OleVariant plus a "Last" continuation pointer that cannot be
'      supplied/nulled from the COM surface -- the exact limitation the matching
'      ActiveX .vbs port documents (it, too, produces no output for this step).
'    * PsrParsePage's UserData is a 64-bit Int, which VB6 cannot early-bind; and
'      driving the parser over the whole help file via late dispatch does not
'      complete in a headless run.
'  So this OO port imports the document and re-emits it (valid PDF, same size as
'  the flat output), gracefully dropping only the PDF->XDF substitution. Errors
' pdf.RaiseExceptions = True
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim inFile As String, outFile As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""                           ' output file opened later
    ' Avoid the conversion of pages to templates
    pdf.SetImportFlags ifImportAll Or ifImportAsPage

    inFile = App.Path & "\dynapdf_help.pdf"
    If pdf.OpenImportFile(inFile, ptOpen, "") < 0 Then Exit Sub
    pdf.ImportPDFFile 1, 1#, 1#
    pdf.CloseImportFile

    ' No fatal error occurred?
    If pdf.HaveOpenDoc <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
    End If
    If pdf.CloseFile <> 0 Then
        Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If
End Sub

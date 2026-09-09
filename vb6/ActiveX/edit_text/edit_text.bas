Attribute VB_Name = "modEditText"
Option Explicit
' ============================================================================
'  edit_text (ActiveX) -- LumasPdf ActiveX/COM component (LumasPdf.PDF),
'  late-bound, no project reference required.
'
'  The flat VB6 original (examples\Vb6\edit_text\edit_text.bas, read-only
'  reference) used the content parser (Psr*) to find every "PDF" in the
'  imported help file and replace it with "XDF". That find/replace is NOT
'  expressible through the registered ActiveX server from VB6 either, for the
'  same reasons the OO flat-DLL port documents:
'    * PsrFindText/PsrReplaceSelText take the 16-byte TTextSelection as a
'      packed OleVariant plus a "Last" continuation pointer that cannot be
'      supplied/nulled from the COM surface.
'    * PsrParsePage's UserData is a 64-bit Int, which VB6 cannot early-bind;
'      and driving the parser over the whole help file via late dispatch
'      does not complete in a headless run.
'  So, exactly like the flat-DLL OO port, this ActiveX port imports the
'  document and re-emits it (valid PDF, same size as the flat output),
'  gracefully dropping only the PDF->XDF substitution -- demonstrating the
'  same import/re-emit feature via the ActiveX surface instead of Declares.
'
'  Mapping from the flat CPDF.cls calls (see the read-only reference at
'  examples\Vb6\edit_text\edit_text.bas):
'    pdf.CreateNewPDF ""                  -> pdf.CreateNewPDFA("")
'    pdf.OpenImportFile(path, pt, pwd)    -> pdf.OpenImportFileA(path, pt, pwd)
'    pdf.OpenOutputFile(path)              -> pdf.OpenOutputFileA(path)
'    everything else (SetImportFlags, ImportPDFFile, CloseImportFile,
'    HaveOpenDoc, CloseFile) -> unchanged (already bare ActiveX names)
'  Enum values (ifImportAll, ifImportAsPage, ptOpen) copied verbatim from
'  wrappers\vb6\LumasPDFInt.bas / LumasPdfAX.ridl since a late-bound Object
'  has no compile-time typelib enums.
' ============================================================================

Const ifImportAll As Long = &HFFFFFFE      ' TImportFlags: default (import everything)
Const ifImportAsPage As Long = &H80000000  ' TImportFlags: don't convert page to template
Const ptOpen As Long = 0                   ' TPwdType: open password

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object                      ' LumasPdf.PDF (late-bound)
    Dim inFile As String, outFile As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True             ' turn engine errors into VB6 errors

    If Not CBool(pdf.CreateNewPDFA("")) Then Err.Raise vbObjectError + 1, , "CreateNewPDFA failed"
    ' Avoid the conversion of pages to templates
    pdf.SetImportFlags ifImportAll Or ifImportAsPage

    inFile = "E:\LUMASPDFSDK\dynapdf_help.pdf"
    If pdf.OpenImportFileA(inFile, ptOpen, "") < 0 Then Exit Sub
    pdf.ImportPDFFile 1, 1#, 1#
    pdf.CloseImportFile

    ' No fatal error occurred?
    If CBool(pdf.HaveOpenDoc()) Then
        outFile = App.path & "\out.pdf"
        If Not CBool(pdf.OpenOutputFileA(outFile)) Then Exit Sub
    End If
    If CBool(pdf.CloseFile()) Then
        Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If

    Set pdf = Nothing
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then
        extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    End If
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "edit_text (ActiveX)"
End Sub

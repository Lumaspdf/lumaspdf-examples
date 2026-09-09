Attribute VB_Name = "modSplitPdf"
Option Explicit
' ============================================================================
'  split_pdf -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp); all
'  enums (ifImportAll, ifImportAsPage, if2UseProxy, ptOpen) come from the
'  typelib. Opens one import file, keeps it open across CloseFile() via
'  SetUseGlobalImpFiles, and writes each page into its own PDF. The flat error
'  callback / pointer marshalling helpers are dropped; errors surface as VB6
' pdf.RaiseExceptions = True
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim i As Long, count As Long
    Dim inFile As String, outDir As String, outPath As String
' pdf.RaiseExceptions = True

    pdf.SetImportFlags ifImportAll Or ifImportAsPage  ' avoid conversion of pages to templates
    pdf.SetImportFlags2 if2UseProxy                    ' reduces the memory usage

    ' Original: '../../../license.pdf'
    inFile = App.Path & "\license.pdf"
    If pdf.OpenImportFile(inFile, ptOpen, "") < 0 Then Exit Sub

    ' Keeps the open import file from being closed when CloseFile() is called.
    pdf.SetUseGlobalImpFiles True

    outDir = App.Path & "\out"
    On Error Resume Next                            ' create output dir if missing
    MkDir outDir
    On Error GoTo 0

    count = pdf.GetInPageCount()
    For i = 1 To count
        outPath = outDir & "\page" & Format$(i, "0000") & ".pdf"
        pdf.CreateNewPDF outPath
            pdf.Append
                pdf.ImportPageEx i, 1#, 1#
            pdf.EndPage
        pdf.CloseFile
    Next i

    ' Always set the property back to false when finished.
    pdf.SetUseGlobalImpFiles False

    Debug.Print "Pages written to: " & outDir & " (" & count & " pages)"
End Sub

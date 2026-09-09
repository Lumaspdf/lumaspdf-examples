Attribute VB_Name = "modSplitPdf"
Option Explicit
' ============================================================================
'  split_pdf -- LumasPdf ActiveX/COM component style (late-bound, no project
'  reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\split_pdf -- same feature: opens one import file, keeps it
'  open across CloseFile() via SetUseGlobalImpFiles, and writes each page
'  into its own PDF.
' ============================================================================

'--- TImportFlags ---------------------------------------------------------------
Const ifImportAll As Long = &HFFFFFFE
Const ifImportAsPage As Long = &H80000000

'--- TImportFlags2 --------------------------------------------------------------
Const if2UseProxy As Long = &H4

'--- TPwdType (ptOpen = 0) -------------------------------------------------------
Const ptOpen As Long = 0

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim i As Long, count As Long
    Dim inFile As String, outDir As String, outPath As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    pdf.SetImportFlags ifImportAll Or ifImportAsPage  ' avoid conversion of pages to templates
    pdf.SetImportFlags2 if2UseProxy                    ' reduces the memory usage

    inFile = App.Path & "\license.pdf"
    If pdf.OpenImportFileW(inFile, ptOpen, "") < 0 Then Exit Sub

    ' Keeps the open import file from being closed when CloseFile() is called.
    pdf.SetUseGlobalImpFiles True

    outDir = App.Path & "\out"
    On Error Resume Next                            ' create output dir if missing
    MkDir outDir
    On Error GoTo ErrHandler

    count = pdf.GetInPageCount()
    For i = 1 To count
        outPath = outDir & "\page" & Format$(i, "0000") & ".pdf"
        pdf.CreateNewPDFW outPath
            pdf.Append
                pdf.ImportPageEx i, 1#, 1#
            pdf.EndPage
        pdf.CloseFile
    Next i

    ' Always set the property back to false when finished.
    pdf.SetUseGlobalImpFiles False

    Debug.Print "Pages written to: " & outDir & " (" & count & " pages)"
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "split_pdf (ActiveX)"
End Sub

Attribute VB_Name = "modPdfToText"
Option Explicit
' ============================================================================
'  pdf_to_text -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\pdf_to_text -- same feature: import in.pdf and extract the
'  text of every page (via SplitPageText) to out.txt.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF ""      -> pdf.CreateNewPDFW ""
'    pdf.OpenImportFile ...   -> pdf.OpenImportFileW ...
'    pdf.SplitPageText(i)     -> pdf.SplitPageText(i)   (unchanged, [out,retval] BSTR)
' ============================================================================

' emNoFuncNames is a dynapdf.pas value, not a TLB enum -- define it locally
' (same value used by the flat-DLL original).
Private Const emNoFuncNames As Long = &H10000000

'--- TImportFlags ----------------------------------------------------------------
Const ifContentOnly As Long = &H0
Const ifImportAsPage As Long = &H80000000

'--- TPwdType ---------------------------------------------------------------------
Const ptOpen As Long = 0

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim i As Long, count As Long, f As Integer
    Dim inFile As String, outFile As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True            ' turn engine errors into VB6 errors
    pdf.SetErrorMode emNoFuncNames        ' do not print function names in errors

    ' We do not produce a PDF file here.
    If Not CBool(pdf.CreateNewPDFW("")) Then Exit Sub

    ' Import the page contents only (anything else is ignored for text extraction).
    pdf.SetImportFlags ifContentOnly Or ifImportAsPage
    inFile = App.Path & "\in.pdf"
    If pdf.OpenImportFileW(inFile, ptOpen, "") < 0 Then Exit Sub
    If pdf.ImportPDFFile(1, 1#, 1#) < 0 Then Exit Sub
    pdf.CloseImportFile

    outFile = App.Path & "\out.txt"
    f = FreeFile
    Open outFile For Output As #f

    count = pdf.GetPageCount()
    For i = 1 To count
        Print #f, "----- Page " & i & " -----"
        ' Open the page, extract its text, close the page (mirrors the GUI flow).
        pdf.EditPage i
        Print #f, pdf.SplitPageText(i)
        pdf.EndPage
    Next i

    Close #f
    Debug.Print "Text written to: " & outFile
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "pdf_to_text (ActiveX)"
End Sub

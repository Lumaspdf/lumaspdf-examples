Attribute VB_Name = "modPdfToText"
Option Explicit
' ============================================================================
'  pdf_to_text -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Imports a PDF and extracts the text of every page (via SplitPageText) to a
'  .txt file. The GUI form and the CPDFToText callback stack are dropped; the
'  same functional result is produced with the engine's page-text export.
' pdf.RaiseExceptions = True
' ============================================================================

' emNoFuncNames is a LumasPdf.pas value, not a TLB enum -- define it locally.
Private Const emNoFuncNames As Long = &H10000000

Public Sub Main()
    Dim pdf As New CPDF
    Dim i As Long, count As Long, f As Integer
    Dim inFile As String, outFile As String

' pdf.RaiseExceptions = True
    pdf.SetErrorMode emNoFuncNames                     ' do not print function names in errors

    ' We do not produce a PDF file here.
    If pdf.CreateNewPDF("") = 0 Then Exit Sub

    ' Import the page contents only (anything else is ignored for text extraction).
    pdf.SetImportFlags ifContentOnly Or ifImportAsPage
    inFile = App.Path & "\in.pdf"
    If pdf.OpenImportFile(inFile, ptOpen, "") < 0 Then Exit Sub
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
End Sub

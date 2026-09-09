Attribute VB_Name = "modTextExtraction3"
Option Explicit
' ============================================================================
'  text_extraction3 -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Imports a PDF and extracts its text page by page with the COM ExtractText,
'  which returns the page text through an [out] OleVariant string (no raw pointer
'  handling), then writes it to out.txt as UTF-16LE (with BOM).
'  The flat pdfMethod[A](pdf, args) maps to pdf.Method[A](args); the error
' pdf.RaiseExceptions = True
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim i As Long, cnt As Long, fNum As Integer
    Dim outFile As String, inFile As String
    Dim area As Variant, txt As Variant, s As String, b() As Byte
    Dim bom(0 To 1) As Byte

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""                ' We do not create a PDF file in this example

    ' External cmaps should always be loaded when extracting text from PDF files.
    pdf.SetCMapDir App.Path & "\CMap", lcmRecursive Or lcmDelayed

    ' Import anything and don't convert pages to templates
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    inFile = App.Path & "\in.pdf"
    If pdf.OpenImportFile(inFile, ptOpen, "") < 0 Then Exit Sub
    pdf.ImportPDFFile 1, 1#, 1#
    pdf.CloseImportFile

    ' Flatten markup annotations and form fields so their text can be extracted too.
    pdf.FlattenAnnots affMarkupAnnots
    pdf.FlattenForm

    outFile = App.Path & "\out.txt"
    fNum = FreeFile
    Open outFile For Binary Access Write As #fNum
    ' UTF-16LE BOM (Byte Order Mark)
    bom(0) = 255: bom(1) = 254
    Put #fNum, , bom

    cnt = pdf.GetPageCount()
    For i = 1 To cnt
        If i > 1 Then
            s = vbCrLf
            b = s
            Put #fNum, , b
        End If
        s = "%----------------------- Page " & i & " -----------------------------" & vbCrLf
        b = s
        Put #fNum, , b

        area = 0
        txt = ""
        ' It is not recommended to sort text on the y-axis since it sometimes causes strange results.
        If pdf.ExtractText(i, tefDeleteOverlappingText Or tefSortTextX, area, txt) Then
            If Not IsNull(txt) Then
                s = CStr(txt)
                If LenB(s) > 0 Then
                    b = s               ' VB strings are UTF-16LE internally
                    Put #fNum, , b
                End If
            End If
        End If
    Next i
    Close #fNum

    Debug.Print "Text successfully extracted to " & outFile
End Sub

Attribute VB_Name = "modTextExtraction3"
Option Explicit
' ============================================================================
'  text_extraction3 -- ActiveX/COM version (LumasPdf.PDF, late-bound),
'  mirrors the plain-DLL example at examples\Vb6\text_extraction3 (read-only
'  reference, not modified). Imports a PDF and extracts its text page by
'  page with ExtractText, which returns the page text through an [out]
'  OleVariant string (no raw pointer handling), then writes it to out.txt as
'  UTF-16LE (with BOM).
'
'  Mapping: pdfExtractText(pdf, PageNum, Flags, Area, Text) ->
'  pdf.ExtractText(PageNum, Flags, Area, Text).
' ============================================================================

Private Const ifImportAll As Long = &HFFFFFFE
Private Const ifImportAsPage As Long = &H80000000
Private Const ptOpen As Long = 0
Private Const affMarkupAnnots As Long = &H2&
Private Const lcmRecursive As Long = 1
Private Const lcmDelayed As Long = 2
Private Const tefSortTextX As Long = 1
Private Const tefDeleteOverlappingText As Long = 4

Public Sub Main()
    Dim pdf As Object
    Dim i As Long, cnt As Long, fNum As Integer
    Dim outFile As String, inFile As String
    Dim area As Variant, txt As Variant, s As String, b() As Byte
    Dim bom(0 To 1) As Byte

    On Error GoTo ErrHandler
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True
    pdf.CreateNewPDFA ""                ' We do not create a PDF file in this example

    ' External cmaps should always be loaded when extracting text from PDF files.
    pdf.SetCMapDirA App.path & "\CMap", lcmRecursive Or lcmDelayed

    ' Import anything and don't convert pages to templates
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    inFile = App.path & "\in.pdf"
    If pdf.OpenImportFileA(inFile, ptOpen, "") < 0 Then Exit Sub
    pdf.ImportPDFFile 1, 1#, 1#
    pdf.CloseImportFile

    ' Flatten markup annotations and form fields so their text can be extracted too.
    pdf.FlattenAnnots affMarkupAnnots
    pdf.FlattenForm

    outFile = App.path & "\out.txt"
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
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "text_extraction3"
End Sub

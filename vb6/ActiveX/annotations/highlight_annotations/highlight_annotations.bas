Attribute VB_Name = "modHighlightAnnotations"
Option Explicit
' ============================================================================
'  highlight_annotations -- LumasPdf ActiveX/COM component style (late-bound,
'  no project reference needed). Equivalent of the flat-DLL/CPDF.cls example
'  at examples\Vb6\annotations\highlight_annotations -- same feature:
'  highlight / squiggly / strikeout / underline markup annotations placed
'  directly over rendered text, sized with GetTextWidthA + GetDescent.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF ""    -> pdf.CreateNewPDFW ""
'    pdf.SetFont ...        -> pdf.SetFontW ...
'    pdf.WriteText ...      -> pdf.WriteTextW ...
'    pdf.GetTextWidthA ...  -> pdf.GetTextWidthA ...  (kept -- explicit A in reference)
'    pdf.HighlightAnnotA .. -> pdf.HighlightAnnotA ..  (kept -- explicit A in reference)
'    pdf.OpenOutputFile ... -> pdf.OpenOutputFileW ...
'  All other calls (GetDescent, SetPageCoords, Append, EndPage, HaveOpenDoc,
'  CloseFile) map 1:1, just with the instance handle dropped.
' ============================================================================

Private Const clYellow As Long = 65535
Private Const clRed As Long = 255

'--- TFStyle (see src\Lumas.Pdf.Types.pas) --------------------------------------
Const FS_REGULAR As Long = &H19000000   ' weight 400 -> same as "no bold/italic"

'--- TCodepage (index 2 = cp1252) -------------------------------------------------
Const CP_1252 As Long = 2

'--- TPageCoord --------------------------------------------------------------------
Const pcTopDown As Long = 1

'--- TAnnotType (highlight family subtypes) ------------------------------------------
Const atHighlight As Long = 4
Const atSquiggly As Long = 12
Const atStrikeOut As Long = 14
Const atUnderline As Long = 16

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim d As Double, w As Double
    Dim outFile As String, text As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""

    pdf.SetPageCoords pcTopDown

    pdf.Append
    text = "Some text on a page..."
    pdf.SetFontW "Helvetica", FS_REGULAR, 20#, False, CP_1252

    d = pdf.GetDescent()
    w = pdf.GetTextWidthA(text)

    pdf.WriteTextW 50#, 50#, text
    pdf.HighlightAnnotA atHighlight, 50#, 50# + d, w, 20#, clYellow, "Test app", "Highligh Annotations", "This is a highlight annotation"

    pdf.WriteTextW 50#, 80#, text
    pdf.HighlightAnnotA atSquiggly, 50#, 80# + d, w, 20#, clRed, "Test app", "Squiggly Annotations", "This is a squiggly annotation"

    pdf.WriteTextW 50#, 110#, text
    pdf.HighlightAnnotA atStrikeOut, 50#, 110# + d, w, 20#, clRed, "Test app", "Strikeout Annotations", "This is a strikeout annotation"

    pdf.WriteTextW 50#, 140#, text
    pdf.HighlightAnnotA atUnderline, 50#, 140# + d, w, 20#, clRed, "Test app", "Underline Annotations", "This is a underline annotation"
    pdf.EndPage

    If CBool(pdf.HaveOpenDoc()) Then
        outFile = App.Path & "\out.pdf"
        pdf.OpenOutputFileW outFile
        pdf.CloseFile
        Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "highlight_annotations (ActiveX)"
End Sub

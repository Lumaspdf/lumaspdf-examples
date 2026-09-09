Attribute VB_Name = "modAnnotationTypes"
Option Explicit
' ============================================================================
'  annotation_types -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\annotations\annotation_types -- same feature: a tour of
'  annotation types -- the highlight family, circle/square, text (note),
'  file attachment, free text (+ callout) and line annotations with every
'  line-end style.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF ""       -> pdf.CreateNewPDFW ""
'    pdf.SetFont ...           -> pdf.SetFontW ...
'    pdf.WriteText ...         -> pdf.WriteTextW ...
'    pdf.WriteFTextEx ...      -> pdf.WriteFTextExW ...
'    pdf.GetTextWidthA ...     -> pdf.GetTextWidthA ...     (kept -- explicit A in reference)
'    pdf.HighlightAnnotA ...   -> pdf.HighlightAnnotA ...   (kept -- explicit A in reference)
'    pdf.CircleAnnotA ...      -> pdf.CircleAnnotA ...      (kept -- explicit A in reference)
'    pdf.TextAnnotA ...        -> pdf.TextAnnotA ...        (kept -- explicit A in reference)
'    pdf.FileAttachAnnotA ...  -> pdf.FileAttachAnnotA ...  (kept -- explicit A in reference)
'    pdf.FreeTextAnnotA ...    -> pdf.FreeTextAnnotA ...    (kept -- explicit A in reference)
'    pdf.LineAnnotA ...        -> pdf.LineAnnotA ...        (kept -- explicit A in reference)
'    pdf.OpenOutputFile ...    -> pdf.OpenOutputFileW ...
'  SquareAnnot (no explicit suffix in the reference) wraps the native W
'  export, so it maps to SquareAnnotW here (see check_boxes/measure_lines
'  notes on this same convention). All other calls (SetAnnotColor,
'  SetAnnotBorderWidth, SetAnnotBorderEffect, ConvToFreeTextCallout,
'  GetDescent, ChangeFontSize, GetPageWidth, GetPageHeight, GetLastTextPosY,
'  SetPageCoords, Append, EndPage, HaveOpenDoc, CloseFile) map 1:1, just with
'  the instance handle dropped.
' ============================================================================

Private Const clYellow As Long = 65535
Private Const clRed As Long = 255
Private Const clCream As Long = 15793151
Private Const clBlack As Long = 0
Private Const clGray As Long = 8421504

'--- TFStyle (see src\Lumas.Pdf.Types.pas) --------------------------------------
Const FS_REGULAR As Long = &H19000000   ' weight 400 -> same as "no bold/italic"

'--- TTextAlign -------------------------------------------------------------------
Const taLeft As Long = 0
Const taCenter As Long = 1

'--- TCodepage (index 2 = cp1252) -------------------------------------------------
Const CP_1252 As Long = 2

'--- TPageCoord --------------------------------------------------------------------
Const pcTopDown As Long = 1

'--- TPDFColorSpace ------------------------------------------------------------------
Const csDeviceRGB As Long = 0

'--- TAnnotType (highlight family subtypes) ------------------------------------------
Const atHighlight As Long = 4
Const atSquiggly As Long = 12
Const atStrikeOut As Long = 14
Const atUnderline As Long = 16

'--- TAnnotIcon ------------------------------------------------------------------------
Const aiComment As Long = 0
Const aiHelp As Long = 1
Const aiInsert As Long = 2
Const aiKey As Long = 3
Const aiNewParagraph As Long = 4
Const aiNote As Long = 5
Const aiParagraph As Long = 6

'--- TFileAttachIcon --------------------------------------------------------------------
Const faiGraph As Long = 0
Const faiPaperClip As Long = 1
Const faiPushPin As Long = 2
Const faiTag As Long = 3

'--- TFieldColor (reused for annotation color type) -------------------------------------
Const fcBackColor As Long = 0
Const fcBorderColor As Long = 1

'--- TBorderEffect -----------------------------------------------------------------------
Const beCloudy1 As Long = 1

'--- TLineEndStyle -----------------------------------------------------------------------
Const leNone As Long = 0
Const leButt As Long = 1
Const leCircle As Long = 2
Const leClosedArrow As Long = 3
Const leDiamond As Long = 4
Const leOpenArrow As Long = 5
Const leRClosedArrow As Long = 6
Const leROpenArrow As Long = 7
Const leSlash As Long = 8
Const leSquare As Long = 9

' Delphi AddHighlightAnnot helper.
Private Sub AddHighlightAnnot(ByVal pdf As Object, ByVal AnnotType As Long, ByVal Color As Long, ByVal x As Double, ByVal y As Double, ByVal text As String, ByVal Subject As String, ByVal Comment As String)
    Dim w As Double
    w = pdf.GetTextWidthA(text)
    pdf.WriteTextW x, y, text
    pdf.HighlightAnnotA AnnotType, x, y + pdf.GetDescent(), w, 20#, Color, "Test app", Subject, Comment
End Sub

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim a As Long
    Dim y As Double
    Dim outFile As String
    Dim cr As String
    Dim attachFile As String

    cr = Chr$(13)
    attachFile = App.Path & "\..\..\..\..\test_files\gdi.emf"

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""

    pdf.SetPageCoords pcTopDown

    pdf.Append

    y = 50#
    pdf.SetFontW "Helvetica", FS_REGULAR, 20#, False, CP_1252
    AddHighlightAnnot pdf, atHighlight, clYellow, 50#, y, "Highlight Annotation", "Highlight Annotations", "This is a highlight annotation"
    AddHighlightAnnot pdf, atSquiggly, clRed, 300#, y, "Squiggly Annotation", "Highlight Annotations", "This is a squiggly annotation"
    y = y + 30#
    AddHighlightAnnot pdf, atStrikeOut, clRed, 50#, y, "Strikeout Annotation", "Highlight Annotations", "This is a strikeout annotation"
    AddHighlightAnnot pdf, atUnderline, clRed, 300#, y, "Underline Annotation", "Highlight Annotations", "This is a underline annotation"

    y = y + 40#
    pdf.CircleAnnotA 50#, y, 200#, 100#, 1#, clCream, clBlack, csDeviceRGB, "Test app", "Circle Annotations", "This is a circle annotation"
    pdf.SquareAnnotW 300#, y, 200#, 100#, 1#, clCream, clBlack, csDeviceRGB, "Test app", "Square Annotations", "This is a square annotation"

    y = y + 130#
    pdf.ChangeFontSize 12#
    pdf.WriteFTextExW 50#, y, pdf.GetPageWidth() - 100#, -1#, taLeft, "The icon color of text and file attachment annotations can be changed if " & _
        "necessary with SetAnnotColor(). The background color must be set." & cr & cr & "Text Annotations:"

    y = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 10#
    ' The default icon color can be changed if necessary
    pdf.TextAnnotA 50#, y, 200#, 100#, "Test app", "This is a text annotation", aiComment, False
    a = pdf.TextAnnotA(100#, y, 200#, 100#, "Test app", "This is a text annotation", aiHelp, False)
    pdf.SetAnnotColor a, fcBackColor, csDeviceRGB, RGB(200, 20, 30)

    pdf.TextAnnotA 150#, y, 200#, 100#, "Test app", "This is a text annotation", aiInsert, False
    a = pdf.TextAnnotA(200#, y, 200#, 100#, "Test app", "This is a text annotation", aiKey, False)
    pdf.SetAnnotColor a, fcBackColor, csDeviceRGB, RGB(50, 200, 30)
    pdf.TextAnnotA 250#, y, 200#, 100#, "Test app", "This is a text annotation", aiNewParagraph, False
    a = pdf.TextAnnotA(300#, y, 200#, 100#, "Test app", "This is a text annotation", aiNote, False)
    pdf.SetAnnotColor a, fcBackColor, csDeviceRGB, RGB(70, 120, 210)
    pdf.TextAnnotA 350#, y, 200#, 100#, "Test app", "This is a text annotation", aiParagraph, False

    y = y + 50#
    pdf.WriteTextW 50#, y, "File Attachment Annotations:"

    y = y + 20#
    pdf.FileAttachAnnotA 50#, y, faiGraph, "Test app", "An example attachment", attachFile, True
    pdf.FileAttachAnnotA 100#, y, faiPaperClip, "Test app", "An example attachment", attachFile, True
    a = pdf.FileAttachAnnotA(150#, y, faiPushPin, "Test app", "An example attachment", attachFile, True)
    pdf.SetAnnotColor a, fcBackColor, csDeviceRGB, RGB(70, 120, 210)
    pdf.FileAttachAnnotA 200#, y, faiTag, "Test app", "An example attachment", attachFile, True

    y = y + 60#
    a = pdf.FreeTextAnnotA(50#, y, 200#, 80#, "Test app", "This is a FreeText Annotation.", taCenter)
    pdf.SetAnnotBorderWidth a, 3#
    pdf.SetAnnotColor a, fcBorderColor, csDeviceRGB, clGray

    a = pdf.FreeTextAnnotA(400#, y, 150#, 45#, "Test app", "This is a FreeText Callout Annotation with a cloudy border.", taCenter)
    pdf.SetAnnotBorderWidth a, 2#
    pdf.SetAnnotColor a, fcBorderColor, csDeviceRGB, clRed
    pdf.SetAnnotBorderEffect a, beCloudy1
    pdf.ConvToFreeTextCallout a, 300#, y + 40#, 30#, leOpenArrow

    y = y + 120#
    pdf.WriteTextW 50#, y, "Line Annotations:"

    y = y + 30#: pdf.LineAnnotA 50#, y, 350#, y, 1#, leNone, leNone, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation"
    y = y + 20#: pdf.LineAnnotA 50#, y, 350#, y, 1#, leButt, leButt, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation"
    y = y + 20#: pdf.LineAnnotA 50#, y, 350#, y, 1#, leCircle, leCircle, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation"
    y = y + 20#: pdf.LineAnnotA 50#, y, 350#, y, 1#, leClosedArrow, leClosedArrow, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation"
    y = y + 20#: pdf.LineAnnotA 50#, y, 350#, y, 1#, leRClosedArrow, leRClosedArrow, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation"
    y = y + 20#: pdf.LineAnnotA 50#, y, 350#, y, 1#, leDiamond, leDiamond, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation"
    y = y + 20#: pdf.LineAnnotA 50#, y, 350#, y, 1#, leOpenArrow, leOpenArrow, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation"
    y = y + 20#: pdf.LineAnnotA 50#, y, 350#, y, 1#, leROpenArrow, leROpenArrow, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation"
    y = y + 20#: pdf.LineAnnotA 50#, y, 350#, y, 1#, leSlash, leSlash, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation"
    y = y + 20#: pdf.LineAnnotA 50#, y, 350#, y, 1#, leSquare, leSquare, clRed, clBlack, csDeviceRGB, "Test app", "Line Annotations", "This is a line annotation"

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
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "annotation_types (ActiveX)"
End Sub

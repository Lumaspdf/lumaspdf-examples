Attribute VB_Name = "modAnnotationTypes"
Option Explicit
' ============================================================================
'  annotation_types -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules (early-bound
'  to CPDF). A tour of annotation types: highlight family, circle/square,
'  text (note), file attachment, free text (+callout) and line annotations with
'  every line-end style.
' ============================================================================

Private Const clYellow As Long = 65535
Private Const clRed As Long = 255
Private Const clCream As Long = 15793151
Private Const clBlack As Long = 0
Private Const clGray As Long = 8421504

' Delphi AddHighlightAnnot helper.
Private Sub AddHighlightAnnot(ByVal pdf As CPDF, ByVal AnnotType As Long, ByVal Color As Long, ByVal x As Double, ByVal y As Double, ByVal Text As String, ByVal Subject As String, ByVal Comment As String)
    Dim w As Double
    w = pdf.GetTextWidthA(Text)
    pdf.WriteText x, y, Text
    pdf.HighlightAnnotA AnnotType, x, y + pdf.GetDescent(), w, 20#, Color, "Test app", Subject, Comment
End Sub

Public Sub Main()
    Dim pdf As New CPDF
    Dim a As Long
    Dim y As Double
    Dim outFile As String
    Dim cr As String
    Dim attachFile As String

    cr = Chr$(13)
    attachFile = "../../../test_files/gdi.emf"

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown

    pdf.Append

    y = 50#
    pdf.SetFont "Helvetica", fsRegular, 20#, False, cp1252
    AddHighlightAnnot pdf, atHighlight, clYellow, 50#, y, "Highlight Annotation", "Highlight Annotations", "This is a highlight annotation"
    AddHighlightAnnot pdf, atSquiggly, clRed, 300#, y, "Squiggly Annotation", "Highlight Annotations", "This is a squiggly annotation"
    y = y + 30#
    AddHighlightAnnot pdf, atStrikeOut, clRed, 50#, y, "Strikeout Annotation", "Highlight Annotations", "This is a strikeout annotation"
    AddHighlightAnnot pdf, atUnderline, clRed, 300#, y, "Underline Annotation", "Highlight Annotations", "This is a underline annotation"

    y = y + 40#
    pdf.CircleAnnotA 50#, y, 200#, 100#, 1#, clCream, clBlack, csDeviceRGB, "Test app", "Circle Annotations", "This is a circle annotation"
    pdf.SquareAnnot 300#, y, 200#, 100#, 1#, clCream, clBlack, csDeviceRGB, "Test app", "Square Annotations", "This is a square annotation"

    y = y + 130#
    pdf.ChangeFontSize 12#
    pdf.WriteFTextEx 50#, y, pdf.GetPageWidth() - 100#, -1#, taLeft, "The icon color of text and file attachment annotations can be changed if " & _
        "necessary with SetAnnotColor(). The background color must be set." & cr & cr & "Text Annotations:"

    y = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 10#
    ' The default icon color can be changed if necessary
    pdf.TextAnnotA 50#, y, 200#, 100#, "Test app", "This is a text annotation", aiComment, 0
    a = pdf.TextAnnotA(100#, y, 200#, 100#, "Test app", "This is a text annotation", aiHelp, 0)
    pdf.SetAnnotColor a, fcBackColor, csDeviceRGB, RGB(200, 20, 30)

    pdf.TextAnnotA 150#, y, 200#, 100#, "Test app", "This is a text annotation", aiInsert, 0
    a = pdf.TextAnnotA(200#, y, 200#, 100#, "Test app", "This is a text annotation", aiKey, 0)
    pdf.SetAnnotColor a, fcBackColor, csDeviceRGB, RGB(50, 200, 30)
    pdf.TextAnnotA 250#, y, 200#, 100#, "Test app", "This is a text annotation", aiNewParagraph, 0
    a = pdf.TextAnnotA(300#, y, 200#, 100#, "Test app", "This is a text annotation", aiNote, 0)
    pdf.SetAnnotColor a, fcBackColor, csDeviceRGB, RGB(70, 120, 210)
    pdf.TextAnnotA 350#, y, 200#, 100#, "Test app", "This is a text annotation", aiParagraph, 0

    y = y + 50#
    pdf.WriteText 50#, y, "File Attachment Annotations:"

    y = y + 20#
    pdf.FileAttachAnnotA 50#, y, faiGraph, "Test app", "An example attachment", attachFile, 1
    pdf.FileAttachAnnotA 100#, y, faiPaperClip, "Test app", "An example attachment", attachFile, 1
    a = pdf.FileAttachAnnotA(150#, y, faiPushPin, "Test app", "An example attachment", attachFile, 1)
    pdf.SetAnnotColor a, fcBackColor, csDeviceRGB, RGB(70, 120, 210)
    pdf.FileAttachAnnotA 200#, y, faiTag, "Test app", "An example attachment", attachFile, 1

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
    pdf.WriteText 50#, y, "Line Annotations:"

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

    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

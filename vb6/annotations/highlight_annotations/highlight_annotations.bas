Attribute VB_Name = "modHighlightAnnotations"
Option Explicit
' ============================================================================
'  highlight_annotations -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules
'  (early-bound to CPDF). Highlight / squiggly / strikeout / underline
'  annotations over text.
' ============================================================================

Private Const clYellow As Long = 65535
Private Const clRed As Long = 255

Public Sub Main()
    Dim pdf As New CPDF
    Dim d As Double, w As Double
    Dim outFile As String, text As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown

    pdf.Append
    text = "Some text on a page..."
    pdf.SetFont "Helvetica", fsRegular, 20#, False, cp1252

    d = pdf.GetDescent()
    w = pdf.GetTextWidthA(text)

    pdf.WriteText 50#, 50#, text
    pdf.HighlightAnnotA atHighlight, 50#, 50# + d, w, 20#, clYellow, "Test app", "Highligh Annotations", "This is a highlight annotation"

    pdf.WriteText 50#, 80#, text
    pdf.HighlightAnnotA atSquiggly, 50#, 80# + d, w, 20#, clRed, "Test app", "Squiggly Annotations", "This is a squiggly annotation"

    pdf.WriteText 50#, 110#, text
    pdf.HighlightAnnotA atStrikeOut, 50#, 110# + d, w, 20#, clRed, "Test app", "Strikeout Annotations", "This is a strikeout annotation"

    pdf.WriteText 50#, 140#, text
    pdf.HighlightAnnotA atUnderline, 50#, 140# + d, w, 20#, clRed, "Test app", "Underline Annotations", "This is a underline annotation"
    pdf.EndPage

    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

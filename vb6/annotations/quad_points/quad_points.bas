Attribute VB_Name = "modQuadPoints"
Option Explicit
' ============================================================================
'  quad_points -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules (early-bound to
'  CPDF). Highlight and link annotations rotated with the coordinate
'  system by setting their quad points explicitly.
'
'  The VB6 original passed pdfSetAnnotQuadPoints pdf, a, VarPtr(points(0)), 4
'  where points() is an array of TFltPoint (x,y). Here the flat list of
'  coordinates is built with Array(x1,y1, x2,y2, ...) and the AX marshaller
'  packs it into the native TFltPoint[] buffer. Count stays the point count (4).
' ============================================================================

Private Const clYellow As Long = 65535
Private Const clRed As Long = 255
Private Const clBlue As Long = 16711680

Public Sub Main()
    Dim pdf As New CPDF
    Dim a As Long
    Dim d As Double, w As Double
    Dim outFile As String, text As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown

    pdf.Append

    pdf.SaveGraphicState

    pdf.SetGStateFlags gfRealTopDownCoords, 0    ' This simplifies the handling a little bit.
    pdf.RotateCoords -30#, 50#, 200#

    text = "Some rotated text on a page..."
    pdf.SetFont "Helvetica", fsRegular, 20#, False, cp1252

    d = pdf.GetDescent()
    w = pdf.GetTextWidthA(text)

    ' Highlight annotations do not consider coordinate transformations made on a page.
    ' To get such annotations rotated we must set the annotation's quad points.
    pdf.WriteText 0#, 0#, text
    a = pdf.HighlightAnnotA(atHighlight, 50#, 50# + d, w, 20#, clYellow, "Test app", "Highligh Annotations", "This is a highlight annotation")
    ' Consider the unusual order of the points!
    pdf.SetAnnotQuadPoints a, VarPtr(Array(0#(0)), d, w, d, 0#, 20# + d, w, 20# + d), 4

    pdf.WriteText 0#, 30#, text
    a = pdf.HighlightAnnotA(atSquiggly, 50#, 80#, w, 20#, clRed, "Test app", "Squiggly Annotations", "This is a squiggly annotation")
    pdf.SetAnnotQuadPoints a, VarPtr(Array(0#(0)), 30# + d, w, 30# + d, 0#, 50# + d, w, 50# + d), 4

    pdf.WriteText 0#, 60#, text
    a = pdf.HighlightAnnotA(atStrikeOut, 50#, 110#, w, 20#, clRed, "Test app", "Strikeout Annotations", "This is a strikeout annotation")
    pdf.SetAnnotQuadPoints a, VarPtr(Array(0#(0)), 60# + d, w, 60# + d, 0#, 80# + d, w, 80# + d), 4

    pdf.WriteText 0#, 90#, text
    a = pdf.HighlightAnnotA(atUnderline, 50#, 140#, w, 20#, clRed, "Test app", "Underline Annotations", "This is a underline annotation")
    pdf.SetAnnotQuadPoints a, VarPtr(Array(0#(0)), 90# + d, w, 90# + d, 0#, 110# + d, w, 110# + d), 4

    text = "Link annotations support quad points too"
    w = pdf.GetTextWidthA(text)
    pdf.WriteText 0#, 120#, text
    ' Link annotations support quad points too.
    a = pdf.WebLinkA(0#, 120#, w, 20#, "www.lumaspdf.com")
    pdf.SetAnnotBorderWidth a, 1#
    pdf.SetAnnotColor a, fcBorderColor, csDeviceRGB, clBlue
    pdf.SetAnnotQuadPoints a, VarPtr(Array(0#(0)), 120# + d, w, 120# + d, 0#, 140# + d, w, 140# + d), 4

    pdf.RestoreGraphicState

    pdf.EndPage

    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

Attribute VB_Name = "modTextFormatting"
Option Explicit
' ============================================================================
'  text_formatting -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Lays out sample.txt into N columns (justified) using a page-break callback.
'  The flat pdfSetOnPageBreakProc + AddressOf OnPageBreakProc callback is now
'  delivered as the COM event Pdf_OnPageBreak, sunk with WithEvents in the
'  companion class TextFormattingEvt (text_formattingEvt.cls). The output
'  rectangle / column state is shared with the event via module-level globals.
' ============================================================================

' ---- output-rectangle state shared with the page-break event ----------------
Public gPosX As Double, gPosY As Double, gWidth As Double, gHeight As Double
Public gDistance As Double
Public gColumn As Long, gColCount As Long

Private Function LoadTextFile(ByVal fileName As String) As String
    Dim fNum As Integer, b() As Byte, sz As Long
    On Error GoTo done
    fNum = FreeFile
    Open fileName For Binary Access Read As #fNum
    sz = LOF(fNum)
    If sz > 0 Then
        ReDim b(0 To sz - 1)
        Get #fNum, , b
        LoadTextFile = StrConv(b, vbUnicode)   ' sample.txt is an ANSI text file
    End If
    Close #fNum
done:
End Function

Public Sub Main()
    Dim e As New TextFormattingEvt
    Dim outFile As String, fText As String

    ' The text is stored in a file. Original: ..\..\test_files\sample.txt
    fText = LoadTextFile(App.Path & "\sample.txt")

    Set e.Pdf = New CPDF
' pdf.RaiseExceptions = True
    e.Pdf.SetDocInfoA diCreator, "C++ test app"
    e.Pdf.SetDocInfoA diSubject, "Multi-column text"
    e.Pdf.SetDocInfoA diTitle, "Multi-column text"
    e.Pdf.SetPageCoords pcTopDown

    If e.Pdf.CreateNewPDFA("") = 0 Then Exit Sub   ' The output file is opened later
    ' CreateNewPDF resets the page-break proc in the engine, so (re)arm it now.
    ' This routes the engine's page-break callback to Pdf_OnPageBreak below.
    e.Pdf.SetOnPageBreakProc

    ' Initialize the output rectangle, number of columns and so on.
    gColCount = 3                 ' Form combo default was 3 columns
    gColumn = 0
    gDistance = 10#
    gPosX = 50#
    gPosY = 50#

    e.Pdf.Append                  ' Append a new page
    gHeight = e.Pdf.GetPageHeight() - 100#
    gWidth = (e.Pdf.GetPageWidth() - 100# - (gColCount - 1) * gDistance) / gColCount

    e.Pdf.SetTextRect gPosX, gPosY, gWidth, gHeight
    e.Pdf.SetFontA "Arial", fsNone, 9#, True, cp1252   ' A font is always required
    e.Pdf.WriteFTextA taJustify, fText                 ' Now print the text
    e.Pdf.EndPage                 ' Close the last page

    ' No fatal error occurred?
    If e.Pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If e.Pdf.OpenOutputFileA(outFile) = 0 Then Exit Sub
        If e.Pdf.CloseFile() <> 0 Then Debug.Print "OK: " & outFile
    End If
End Sub

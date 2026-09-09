Attribute VB_Name = "modTextFormatting"
Option Explicit
' ============================================================================
'  text_formatting -- ActiveX/COM version (LumasPdf.PDF), mirrors the
'  plain-DLL example at examples\Vb6\text_formatting (read-only reference,
'  not modified). Lays out sample.txt into N columns (justified) using a
'  page-break callback.
'
'  The flat pdfSetOnPageBreakProc + AddressOf OnPageBreakProc callback is
'  delivered as the COM event LumasPDF_OnPageBreak, sunk with WithEvents in
'  the companion class TextFormattingEvt (text_formattingEvt.cls). VB6 can
'  only sink COM events through an early-bound WithEvents declaration, so
'  that class carries a project reference to the "LumasPdf PDF engine
'  Automation library" type library. A single early-bound Pdf variable
'  (LumasPdfAX.LumasPDF) is used both to sink the event AND for every real
'  engine call below and inside the event handler -- there is no need for a
'  second late-bound alias to the same object (see note below).
'
'  Investigation note (2026-07-24): an earlier version of this example used
'  a dual-object workaround (an early-bound Pdf purely for WithEvents, plus
'  a late-bound PdfLate Object used for every actual call), based on a
'  belief that this server's compiled vtable did not marshal [in] BSTR
'  arguments correctly on early-bound calls (SetDocInfoA/SetFontA/
'  WriteFTextA/OpenOutputFileA all failing with "engine call failed" early-
'  bound but not late-bound). That belief does not hold up: a from-scratch
'  VB6 repro exercising a single early-bound LumasPdfAX.LumasPDF variable
'  (WithEvents live, real OnPageBreak firing many times over this same
'  sample.txt, every BSTR-argument call included) runs end-to-end with no
'  error and produces byte-identical PDF output to the late-bound version
'  (aside from the expected random /ID). The true, and only, cause of the
'  "engine call failed" seen previously is that SetDocInfoA (and, more
'  generally, document-info/metadata calls) must be made AFTER
'  CreateNewPDFA has opened a document, not before -- calling it first
'  raises "engine call failed" REGARDLESS of early- vs late-bound, unlike
'  the flat-DLL/CPDF.cls original, which tolerates the call before a
'  document is open. Reordering (document info set right after
'  CreateNewPDFA, as below) is what actually fixes it; switching to
'  late-bound was a coincidental, unnecessary workaround for a document-
'  ordering issue, not a real ActiveX-server bug.
'
'  The output rectangle / column state is shared with the event via
'  module-level globals, exactly like the reference.
' ============================================================================

' ---- output-rectangle state shared with the page-break event ----------------
Public gPosX As Double, gPosY As Double, gWidth As Double, gHeight As Double
Public gDistance As Double
Public gColumn As Long, gColCount As Long

' TDocumentInfo / TPageCoord / TFStyle / TCodepage / TTextAlign
Private Const diCreator As Long = 1
Private Const diSubject As Long = 4
Private Const diTitle As Long = 5
Private Const pcTopDown As Long = 1
Private Const fsNone As Long = &H0
Private Const cp1252 As Long = 2
Private Const taJustify As Long = 3

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
    Dim pdf As LumasPdfAX.LumasPDF
    Dim outFile As String, fText As String

    On Error GoTo ErrHandler

    ' The text is stored in a file. Original: ..\..\test_files\sample.txt
    fText = LoadTextFile(App.path & "\sample.txt")

    Set pdf = New LumasPdfAX.LumasPDF
    Set e.Pdf = pdf          ' hook WithEvents to the same object (OnPageBreak);
                             ' also used directly for every real call below
    pdf.RaiseExceptions = True

    If pdf.CreateNewPDFA("") = 0 Then Exit Sub   ' The output file is opened later

    pdf.SetDocInfoA diCreator, "C++ test app"
    pdf.SetDocInfoA diSubject, "Multi-column text"
    pdf.SetDocInfoA diTitle, "Multi-column text"
    pdf.SetPageCoords pcTopDown
    ' CreateNewPDF resets the page-break proc in the engine, so (re)arm it now.
    ' This routes the engine's page-break callback to Pdf_OnPageBreak in e.
    pdf.SetOnPageBreakProc

    ' Initialize the output rectangle, number of columns and so on.
    gColCount = 3                 ' Form combo default was 3 columns
    gColumn = 0
    gDistance = 10#
    gPosX = 50#
    gPosY = 50#

    pdf.Append                    ' Append a new page
    gHeight = pdf.GetPageHeight() - 100#
    gWidth = (pdf.GetPageWidth() - 100# - (gColCount - 1) * gDistance) / gColCount

    pdf.SetTextRect gPosX, gPosY, gWidth, gHeight
    pdf.SetFontA "Arial", fsNone, 9#, True, cp1252   ' A font is always required
    pdf.WriteFTextA taJustify, fText                 ' Now print the text
    pdf.EndPage                   ' Close the last page

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.path & "\out.pdf"
        If pdf.OpenOutputFileA(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then Debug.Print "OK: " & outFile
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "text_formatting"
End Sub

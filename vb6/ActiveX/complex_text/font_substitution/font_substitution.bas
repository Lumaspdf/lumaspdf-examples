Attribute VB_Name = "modFontSubstitution"
Option Explicit
' ============================================================================
'  font_substitution (ActiveX) -- LumasPdf ActiveX/COM component (LumasPdf.PDF),
'  late-bound, no project reference required.
'
'  Same feature as the flat-DLL "font_substitution" example (examples\Vb6\
'  complex_text\font_substitution\font_substitution.bas, read-only reference):
'  complex text layout of a multi-language text relying on automatic font
'  substitution (no alternate font list is registered -- contrast with the
'  sibling alternate_font_lists example). The UTF-16LE text is read via
'  ADODB.Stream and laid out with the wide WriteFTextExW.
'
'  Mapping from the flat CPDF.cls calls:
'    pdf.CreateNewPDF ""             -> pdf.CreateNewPDFW("")
'    pdf.SetFont Name,Style,Size,Embed,CP -> pdf.SetFontW Name,Style,Size,Embed,CP
'    everything else (SetPageCoords, SetGStateFlags, Append, SetLeading,
'    GetTypoLeading, WriteFTextExW, GetPageWidth, GetPageHeight, EndPage,
'    HaveOpenDoc, CloseFile) -> unchanged (already bare ActiveX names)
'  Enum values (pcTopDown, gfComplexText, fsRegular, cpUnicode, taJustify)
'  copied verbatim from wrappers\vb6\LumasPDFInt.bas / LumasPdfAX.ridl since a
'  late-bound Object has no compile-time typelib enums.
' ============================================================================

Const pcTopDown As Long = 1            ' TPageCoords: top-down
Const gfComplexText As Long = 1024      ' TGStateFlags: enable complex text layout
Const fsRegular As Long = 419430400     ' TFStyle: regular weight
Const cpUnicode As Long = 39            ' TCodepage: Unicode
Const taJustify As Long = 3             ' TTextAlign: justify

Private Function ReadUnicodeFile(ByVal path As String) As String
    Dim st As Object
    Set st = CreateObject("ADODB.Stream")
    st.Type = 2                 ' text
    st.Charset = "unicode"      ' UTF-16LE, honours BOM
    st.Open
    st.LoadFromFile path
    ReadUnicodeFile = st.ReadText
    st.Close
End Function

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object                  ' LumasPdf.PDF (late-bound)
    Dim outFile As String, txt As String

    txt = ReadUnicodeFile("E:\LUMASPDFSDK\examples\test_files\multi_lang.txt")

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True         ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""

    pdf.SetPageCoords pcTopDown
    ' Enable complex text layout
    pdf.SetGStateFlags gfComplexText, False

    pdf.Append
    ' The font must be loaded with cpUnicode.
    pdf.SetFontW "Arial", fsRegular, 10, True, cpUnicode
    pdf.SetLeading pdf.GetTypoLeading
    pdf.WriteFTextExW 50, 50, pdf.GetPageWidth - 100, pdf.GetPageHeight - 100, taJustify, txt
    pdf.EndPage

    If pdf.HaveOpenDoc <> 0 Then
        outFile = App.path & "\out.pdf"
        pdf.OpenOutputFileW outFile
    End If
    pdf.CloseFile
    Debug.Print "OK: " & outFile
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "font_substitution (ActiveX)"
End Sub

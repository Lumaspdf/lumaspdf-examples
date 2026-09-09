Attribute VB_Name = "modAlternateFonts"
Option Explicit
' ============================================================================
'  alternate_fonts (ActiveX) -- LumasPdf ActiveX/COM component (LumasPdf.PDF),
'  late-bound, no project reference required.
'
'  Same feature as the flat-DLL "alternate_font_lists" example (examples\Vb6\
'  complex_text\alternate_font_lists\alternate_fonts.bas, read-only reference):
'  complex text layout of a multi-language text with an explicit alternate
'  font list. The COM object's SetAltFontsA takes the font-name list as a
'  plain VB6 string array (Array("Malgun Gothic", ...)) directly -- the AX
'  server marshals it into the native char** itself, same as the flat
'  wrapper's own SetAltFonts/SetAltFontsA. (SetAltFontsW in the typelib has an
'  extra leading IPDF parameter left over from the raw export signature and
'  is NOT the one to use from a COM client -- SetAltFontsA is the clean OO
'  entry point, matching the flat CPDF.cls SetAltFonts call shape.)
'
'  Mapping from the flat CPDF.cls calls:
'    pdf.CreateNewPDF ""                      -> pdf.CreateNewPDFW("")
'    pdf.SetFont Name,Style,Size,Embed,CP     -> pdf.SetFontW Name,Style,Size,Embed,CP
'    pdf.SetAltFonts altFonts, fonts, count   -> pdf.SetAltFontsA altFonts, fonts, count
'    everything else (SetPageCoords, SetGStateFlags, CreateAltFontList,
'    ActivateAltFontList, Append, SetLeading, GetTypoLeading, WriteFTextExW,
'    GetPageWidth, GetPageHeight, EndPage, HaveOpenDoc, CloseFile) -> unchanged
'    (already bare ActiveX names)
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
    Dim outFile As String, txt As String, altFonts As Long
    Dim fonts As Variant

    txt = ReadUnicodeFile("E:\LUMASPDFSDK\examples\test_files\multi_lang.txt")

    ' Alternate fonts, sorted alphabetically. It is not guaranteed that any of
    ' these fonts is available on the system.
    fonts = Array("Malgun Gothic", "Mangal", "Nyala", "Shonar Bangla", "Shruti")

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True         ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""

    pdf.SetPageCoords pcTopDown
    ' Enable complex text layout
    pdf.SetGStateFlags gfComplexText, False

    ' Same as font_substitution but we provide an alternate font list.
    altFonts = pdf.CreateAltFontList
    pdf.SetAltFontsA altFonts, fonts, UBound(fonts) - LBound(fonts) + 1

    pdf.Append
    ' The font must be loaded with cpUnicode.
    pdf.SetFontW "Arial", fsRegular, 10, True, cpUnicode
    ' Activate the alternate font list.
    pdf.ActivateAltFontList altFonts, True

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
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "alternate_fonts (ActiveX)"
End Sub

Attribute VB_Name = "modAlternateFonts"
Option Explicit
' ============================================================================
'  alternate_fonts -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Complex text layout of a multi-language text with an alternate font list.
'  The COM object's SetAltFontsA takes the font-name list as a string array
'  directly (the COM layer builds the native char** from it). Enums come from
'  the typelib.
' ============================================================================

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
    Dim pdf As New CPDF
    Dim outFile As String, txt As String, altFonts As Long
    Dim fonts As Variant

    txt = ReadUnicodeFile("E:\LUMASPDFSDK\examples\test_files\multi_lang.txt")

    ' Alternate fonts, sorted alphabetically. It is not guaranteed that any of
    ' these fonts is available on the system.
    fonts = Array("Malgun Gothic", "Mangal", "Nyala", "Shonar Bangla", "Shruti")

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown
    ' Enable complex text layout
    pdf.SetGStateFlags gfComplexText, False

    ' Same as font_substitution but we provide an alternate font list.
    altFonts = pdf.CreateAltFontList
    pdf.SetAltFonts altFonts, fonts, UBound(fonts) - LBound(fonts) + 1

    pdf.Append
    ' The font must be loaded with cpUnicode.
    pdf.SetFont "Arial", fsRegular, 10, True, cpUnicode
    ' Activate the alternate font list.
    pdf.ActivateAltFontList altFonts, True

    pdf.SetLeading pdf.GetTypoLeading
    pdf.WriteFTextExW 50, 50, pdf.GetPageWidth - 100, pdf.GetPageHeight - 100, taJustify, txt
    pdf.EndPage

    If pdf.HaveOpenDoc <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
    End If
    If pdf.CloseFile <> 0 Then Debug.Print "PDF file """ & outFile & """ successfully created!"
End Sub

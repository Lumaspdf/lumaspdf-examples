Attribute VB_Name = "modComplexText"
Option Explicit
' ============================================================================
'  complex_text -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Complex text layout of a right-to-left (Pashto) text. The UTF-16LE text is
'  read via ADODB.Stream and laid out with the wide WriteFTextExW. Enums come
'  from the typelib.
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
    Dim outFile As String, txt As String

    txt = ReadUnicodeFile("E:\LUMASPDFSDK\examples\test_files\pashto.txt")

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown
    ' Enable complex text layout
    pdf.SetGStateFlags gfComplexText, False
    pdf.SetBidiMode bmRightToLeft

    pdf.Append
    ' The font must be loaded with cpUnicode.
    pdf.SetFont "Arial", fsRegular, 10, True, cpUnicode
    pdf.SetLeading pdf.GetTypoLeading
    pdf.WriteFTextExW 50, 50, pdf.GetPageWidth - 100, pdf.GetPageHeight - 100, taJustify, txt
    pdf.EndPage

    If pdf.HaveOpenDoc <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
    End If
    If pdf.CloseFile <> 0 Then Debug.Print "PDF file """ & outFile & """ successfully created!"
End Sub

' font_substitution -- VB.NET port of examples\Vb6\complex_text\font_substitution\font_substitution.bas
Imports System
Imports System.IO
Imports System.Text
Imports LumasPdfSdk

Module FontSubstitution
    Private errDel As TErrorProc

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Private Function GetFileBuffer(ByVal FileName As String) As String
        Try
            Dim b() As Byte = File.ReadAllBytes(FileName)
            If b.Length = 0 Then Return ""
            Return Encoding.Unicode.GetString(b)
        Catch
            Return ""
        End Try
    End Function

    Sub Main()
        Dim outFile As String = ""
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        Dim txt As String = GetFileBuffer(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..\..\..\test_files\multi_lang.txt"))

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)
        LumasPdf.pdfSetGStateFlags(pdf, LumasPdfConsts.gfComplexText, False)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsRegular, 10.0, True, TCodepage.cpUnicode)
        LumasPdf.pdfSetLeading(pdf, LumasPdf.pdfGetTypoLeading(pdf))
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 50.0, LumasPdf.pdfGetPageWidth(pdf) - 100.0, LumasPdf.pdfGetPageHeight(pdf) - 100.0, LumasPdfConsts.taJustify, txt)

        LumasPdf.pdfEndPage(pdf)

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf")
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
        End If
        If LumasPdf.pdfCloseFile(pdf) <> 0 Then
            Console.WriteLine("PDF file """ & outFile & """ successfully created!")
        End If
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

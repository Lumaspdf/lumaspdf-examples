' alternate_fonts -- VB.NET port of examples\Vb6\complex_text\alternate_font_lists\alternate_fonts.bas
Imports System
Imports System.IO
Imports System.Text
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module AlternateFonts
    Private errDel As TErrorProc
    Private Const ALT_FONT_COUNT As Integer = 5

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
        Dim fonts() As String = {"Malgun Gothic", "Mangal", "Nyala", "Shonar Bangla", "Shruti"}

        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        Dim txt As String = GetFileBuffer(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..\..\..\test_files\multi_lang.txt"))

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)
        LumasPdf.pdfSetGStateFlags(pdf, LumasPdfConsts.gfComplexText, False)

        Dim altFonts As Integer = LumasPdf.pdfCreateAltFontList(pdf)

        ' Build an array of PWideChar pointers (LPWStr) for pdfSetAltFontsW.
        Dim strPtrs(ALT_FONT_COUNT - 1) As IntPtr
        Dim arr As IntPtr = Marshal.AllocHGlobal(IntPtr.Size * ALT_FONT_COUNT)
        For i As Integer = 0 To ALT_FONT_COUNT - 1
            strPtrs(i) = Marshal.StringToHGlobalUni(fonts(i))
            Marshal.WriteIntPtr(arr, i * IntPtr.Size, strPtrs(i))
        Next
        LumasPdf.pdfSetAltFontsW(pdf, CUInt(altFonts), arr, CUInt(ALT_FONT_COUNT))

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsRegular, 10.0, True, TCodepage.cpUnicode)
        LumasPdf.pdfActivateAltFontList(pdf, altFonts, True)

        LumasPdf.pdfSetLeading(pdf, LumasPdf.pdfGetTypoLeading(pdf))
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 50.0, LumasPdf.pdfGetPageWidth(pdf) - 100.0, LumasPdf.pdfGetPageHeight(pdf) - 100.0, LumasPdfConsts.taJustify, txt)

        LumasPdf.pdfEndPage(pdf)

        ' Free marshalled memory (after the layout call).
        For i As Integer = 0 To ALT_FONT_COUNT - 1
            Marshal.FreeHGlobal(strPtrs(i))
        Next
        Marshal.FreeHGlobal(arr)

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

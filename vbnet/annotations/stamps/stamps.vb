' stamps -- VB.NET port of examples\Vb6\annotations\stamps
Imports System
Imports System.IO
Imports LumasPdfSdk

Module Stamps
    Private errDel As TErrorProc

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Return 0
    End Function

    Private Function RGB(ByVal r As Integer, ByVal g As Integer, ByVal b As Integer) As UInteger
        Return CUInt(r Or (g << 8) Or (b << 16))
    End Function

    Sub Main()
        Dim a As Integer
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        LumasPdf.pdfAppend(pdf)

        a = LumasPdf.pdfStampAnnotW(pdf, TRubberStamp.rsApproved, 135.0, 50.0, 300.0, 10.0, "Test app", "Stamp Annotations", "The default language is English!")
        LumasPdf.pdfSetAnnotColor(pdf, a, TFieldColor.fcBorderColor, TPDFColorSpace.csDeviceRGB, RGB(120, 190, 92))

        LumasPdf.pdfSetLanguage(pdf, "DE")
        a = LumasPdf.pdfStampAnnotW(pdf, TRubberStamp.rsApproved, 135.0, 150.0, 300.0, 10.0, "Test app", "Stamp Annotations", "The same stamp in German!")
        LumasPdf.pdfSetAnnotColor(pdf, a, TFieldColor.fcBorderColor, TPDFColorSpace.csDeviceRGB, RGB(230, 65, 132))

        LumasPdf.pdfSetLanguage(pdf, "FR")
        a = LumasPdf.pdfStampAnnotW(pdf, TRubberStamp.rsApproved, 135.0, 250.0, 300.0, 10.0, "Test app", "Stamp Annotations", "The same stamp in French!")
        LumasPdf.pdfSetAnnotColor(pdf, a, TFieldColor.fcBorderColor, TPDFColorSpace.csDeviceRGB, RGB(78, 157, 232))
        LumasPdf.pdfEndPage(pdf)

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            Dim outFile As String = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf")
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
            If LumasPdf.pdfCloseFile(pdf) <> 0 Then
                Console.WriteLine("PDF file """ & outFile & """ successfully created!")
            End If
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

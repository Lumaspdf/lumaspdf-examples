' highlight_annotations -- VB.NET port of examples\Vb6\annotations\highlight_annotations
Imports System
Imports System.IO
Imports LumasPdfSdk

Module HighlightAnnotations
    Private Const clYellow As UInteger = 65535UI
    Private Const clRed As UInteger = 255UI
    Private errDel As TErrorProc

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Return 0
    End Function

    Sub Main()
        Dim d As Double, w As Double
        Dim text As String
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        LumasPdf.pdfAppend(pdf)
        text = "Some text on a page..."
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 20.0, False, TCodepage.cp1252)

        d = LumasPdf.pdfGetDescent(pdf)
        w = LumasPdf.pdfGetTextWidthW(pdf, text)

        LumasPdf.pdfWriteTextW(pdf, 50.0, 50.0, text)
        LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, "Test app", "Highligh Annotations", "This is a highlight annotation")

        LumasPdf.pdfWriteTextW(pdf, 50.0, 80.0, text)
        LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atSquiggly, 50.0, 80.0 + d, w, 20.0, clRed, "Test app", "Squiggly Annotations", "This is a squiggly annotation")

        LumasPdf.pdfWriteTextW(pdf, 50.0, 110.0, text)
        LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atStrikeOut, 50.0, 110.0 + d, w, 20.0, clRed, "Test app", "Strikeout Annotations", "This is a strikeout annotation")

        LumasPdf.pdfWriteTextW(pdf, 50.0, 140.0, text)
        LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atUnderline, 50.0, 140.0 + d, w, 20.0, clRed, "Test app", "Underline Annotations", "This is a underline annotation")
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

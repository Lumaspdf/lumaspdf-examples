' smoke_test -- VB.NET port of examples\Vb6\smoke_test\smoke_test.bas
Imports System
Imports System.IO
Imports LumasPdfSdk

Module modSmoke
    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        Dim outFile As String = AppPath() & "\smoke_out.pdf"

        If Not LumasPdf.pdfCreateNewPDFW(pdf, outFile) Then
            Console.WriteLine("CreateNewPDF failed")
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If

        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diTitle, "LumasPdf example-mirror smoke test")
        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsRegular, 24.0, 1, TCodepage.cp1252)
        LumasPdf.pdfWriteTextW(pdf, 50, 700, "Examples run on LumasPdf.dll")
        LumasPdf.pdfSetFillColor(pdf, 255)
        LumasPdf.pdfRectangle(pdf, 50, 500, 200, 100, TPathFillMode.fmFill)
        LumasPdf.pdfAddBookmarkW(pdf, "First page", -1, 1, 0)
        LumasPdf.pdfEndPage(pdf)

        If Not LumasPdf.pdfCloseFile(pdf) Then
            Console.WriteLine("CloseFile failed")
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If

        Console.WriteLine("OK: " & outFile)
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

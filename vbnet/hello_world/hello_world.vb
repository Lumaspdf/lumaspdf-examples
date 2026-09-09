' hello_world -- VB.NET port of examples\Vb6\hello_world
Imports System
Imports System.IO
Imports LumasPdfSdk

Module HelloWorld
    ' Keep a reference so the delegate is not GC'd during native calls.
    Private errDel As TErrorProc

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return -1 ' break processing on error
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)

        If LumasPdf.pdfCreateNewPDFW(pdf, "") = 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diCreator, "Delphi Example project")
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diTitle, "My first PDF output")

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsItalic, 30.0, True, TCodepage.cp1252)
        LumasPdf.pdfWriteFTextW(pdf, LumasPdfConsts.taCenter, "My first PDF output..." & vbCr & vbCr & Now().ToString())
        LumasPdf.pdfEndPage(pdf)

        Dim outFile As String = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf")
        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, Nothing)
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
            LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        End If
        If LumasPdf.pdfCloseFile(pdf) <> 0 Then
            Console.WriteLine("OK: " & outFile)
        End If
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

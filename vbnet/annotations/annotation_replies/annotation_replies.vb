' annotation_replies -- VB.NET port of examples\Vb6\annotations\annotation_replies
Imports System
Imports System.IO
Imports LumasPdfSdk

Module AnnotationReplies
    Private Const NO_COLOR As UInteger = &HFFFFFFF1UI
    Private errDel As TErrorProc

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Return 0
    End Function

    Sub Main()
        Dim annot As Integer, reply As Integer
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        LumasPdf.pdfAppend(pdf)
        annot = LumasPdf.pdfSquareAnnotW(pdf, 50.0, 50.0, 200.0, 100.0, 3.0, NO_COLOR, 255, TPDFColorSpace.csDeviceRGB, "Jim", "Test", "Just test...")
        reply = LumasPdf.pdfSetAnnotMigrationStateW(pdf, annot, TAnnotState.asCreateReply, "Harry")
        LumasPdf.pdfSetAnnotStringW(pdf, reply, TAnnotString.asContent, "This is a reply!")

        reply = LumasPdf.pdfSetAnnotMigrationStateW(pdf, reply, TAnnotState.asCreateReply, "Jim")
        LumasPdf.pdfSetAnnotStringW(pdf, reply, TAnnotString.asContent, "This is a reply to a reply!")
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

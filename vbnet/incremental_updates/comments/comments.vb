' comments -- VB.NET port of examples\Vb6\incremental_updates\comments
Imports System
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modComments
    Private ErrDel As TErrorProc

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Private Function CopyBuffer(ByVal pdf As IntPtr, ByRef buf() As Byte) As Boolean
        Dim bufSize As UInteger = 0
        Dim p As IntPtr = LumasPdf.pdfGetBuffer(pdf, bufSize)
        If p = IntPtr.Zero OrElse bufSize <= 0 Then Return False
        ReDim buf(CInt(bufSize) - 1)
        Marshal.Copy(p, buf, 0, CInt(bufSize))
        LumasPdf.pdfFreePDF(pdf)
        Return True
    End Function

    Private Function CreateTestFile(ByVal pdf As IntPtr, ByRef buf() As Byte) As Boolean
        LumasPdf.pdfCreateNewPDFW(pdf, "")
        LumasPdf.pdfSetPageCoords(pdf, CInt(TPageCoord.pcTopDown))
        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSquareAnnotW(pdf, 50.0, 50.0, 200.0, 100.0, 3.0, LumasPdfConsts.NO_COLOR, 255, TPDFColorSpace.csDeviceRGB, "Jim", "Test", "Just a test...")
        LumasPdf.pdfEndPage(pdf)
        If Not LumasPdf.pdfCloseFile(pdf) Then Return False
        Return CopyBuffer(pdf, buf)
    End Function

    Private Function LoadTestFile(ByVal pdf As IntPtr, ByRef buf() As Byte) As Boolean
        LumasPdf.pdfCreateNewPDFW(pdf, "")
        LumasPdf.pdfSetImportFlags2(pdf, CUInt(LumasPdfConsts.if2IncrementalUpd))
        Dim h As GCHandle = GCHandle.Alloc(buf, GCHandleType.Pinned)
        Try
            If LumasPdf.pdfOpenImportBuffer(pdf, h.AddrOfPinnedObject(), CUInt(buf.Length), LumasPdfConsts.ptOpen, "") < 0 Then Return False
            Return LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0) > 0
        Finally
            h.Free()
        End Try
    End Function

    Private Function SaveFile(ByVal pdf As IntPtr, ByRef buf() As Byte) As Boolean
        If Not LumasPdf.pdfCloseFile(pdf) Then Return False
        Return CopyBuffer(pdf, buf)
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        ErrDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDel)

        Dim buf() As Byte = Nothing

        If Not CreateTestFile(pdf, buf) Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If

        If LoadTestFile(pdf, buf) Then
            Dim reply As Integer = LumasPdf.pdfSetAnnotMigrationStateW(pdf, 0, TAnnotState.asCreateReply, "Harry")
            LumasPdf.pdfSetAnnotStringW(pdf, CUInt(reply), CInt(TAnnotString.asContent), "Hi Jim, your test annotation looks fine!")
            If SaveFile(pdf, buf) Then
                If LoadTestFile(pdf, buf) Then
                    reply = LumasPdf.pdfSetAnnotMigrationStateW(pdf, CUInt(reply), TAnnotState.asCreateReply, "Tommy")
                    LumasPdf.pdfSetAnnotStringW(pdf, CUInt(reply), CInt(TAnnotString.asContent), "Just a test whether I can reply to a reply...")
                    If SaveFile(pdf, buf) Then
                        If LoadTestFile(pdf, buf) Then
                            reply = LumasPdf.pdfSetAnnotMigrationStateW(pdf, CUInt(reply), TAnnotState.asCreateReply, "Jim")
                            LumasPdf.pdfSetAnnotStringW(pdf, CUInt(reply), CInt(TAnnotString.asContent), "Seems to work very well!")
                            If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
                                Dim filePath As String = AppPath() & "\out.pdf"
                                If LumasPdf.pdfOpenOutputFileW(pdf, filePath) <> 0 Then
                                    If LumasPdf.pdfCloseFile(pdf) Then
                                        Console.WriteLine("PDF file """ & filePath & """ successfully created!")
                                    End If
                                End If
                            End If
                        End If
                    End If
                End If
            End If
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

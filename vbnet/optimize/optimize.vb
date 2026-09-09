' optimize -- VB.NET port of examples\Vb6\optimize
Imports System
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modOptimize
    Private errDel As TErrorProc

    Private Function U(ByVal v As Long) As UInteger
        Return CUInt(v And &HFFFFFFFFL)
    End Function

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Private Function Optimize(ByVal pdf As IntPtr, ByVal InFile As String, ByVal OutFile As String) As Boolean
        Optimize = False
        LumasPdf.pdfCreateNewPDFW(pdf, "")
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diProducer, "")

        LumasPdf.pdfSetImportFlags(pdf, U((LumasPdfConsts.ifImportAll Or LumasPdfConsts.ifImportAsPage) And Not LumasPdfConsts.ifPieceInfo))
        LumasPdf.pdfSetImportFlags2(pdf, U(LumasPdfConsts.if2UseProxy Or LumasPdfConsts.if2DuplicateCheck Or LumasPdfConsts.if2Normalize Or LumasPdfConsts.if2NoResNameCheck))
        If LumasPdf.pdfOpenImportFileW(pdf, InFile, LumasPdfConsts.ptOpen, "") < 0 Then
            LumasPdf.pdfFreePDF(pdf)
            Return False
        End If
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
        LumasPdf.pdfCloseImportFile(pdf)

        LumasPdf.pdfOptimize(pdf, U(LumasPdfConsts.ofInMemory Or LumasPdfConsts.ofNewLinkNames Or LumasPdfConsts.ofDeleteInvPaths), IntPtr.Zero)

        Dim e As TPDFError
        e.StructSize = CUInt(Marshal.SizeOf(GetType(TPDFError)))
        For i As Integer = 0 To LumasPdf.pdfGetErrLogMessageCount(pdf) - 1
            LumasPdf.pdfGetErrLogMessage(pdf, CUInt(i), e)
            Console.WriteLine(Marshal.PtrToStringAnsi(e.Msg))
        Next

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            If LumasPdf.pdfOpenOutputFileW(pdf, OutFile) = 0 Then
                LumasPdf.pdfFreePDF(pdf)
                Return False
            End If
            Optimize = (LumasPdf.pdfCloseFile(pdf) <> 0)
        End If
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)

        LumasPdf.pdfSetCMapDirW(pdf, AppPath() & "\CMap", U(LumasPdfConsts.lcmDelayed Or LumasPdfConsts.lcmRecursive))

        Dim filePath As String = AppPath() & "\out.pdf"
        Dim inFile As String = AppPath() & "\dynapdf_help.pdf"
        If Optimize(pdf, inFile, filePath) Then
            Console.WriteLine("PDF file """ & filePath & """ successfully created!")
        End If
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

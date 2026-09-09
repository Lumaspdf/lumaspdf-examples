' metafiles_gui -- VB.NET port of examples\Vb6\metafiles_gui (headless Sub Main)
Imports System
Imports LumasPdfSdk

Module modMetafilesGui
    Private errDel As TErrorProc
    Private Const MARGIN As Double = 10.0

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Private Sub PlaceEMFCentered(ByVal pdf As IntPtr, ByVal mFile As String, ByVal Width_ As Double, ByVal Height_ As Double)
        Dim x, y, w, h, sx As Double
        Dim r As TRectL
        LumasPdf.pdfGetLogMetafileSize(pdf, mFile, r)
        w = r.Right - r.Left
        h = r.Bottom - r.Top
        Width_ = Width_ - 2.0 * MARGIN
        Height_ = Height_ - 2.0 * MARGIN
        sx = Width_ / w
        If (h * sx <= Height_) Then
            x = MARGIN
            y = MARGIN
            LumasPdf.pdfInsertMetafile(pdf, mFile, x, y, Width_, 0.0)
        Else
            sx = Height_ / h
            w = w * sx
            x = MARGIN + (Width_ - w) / 2.0
            y = MARGIN
            LumasPdf.pdfInsertMetafile(pdf, mFile, x, y, 0.0, Height_)
        End If
    End Sub

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfSetCompressionFilter(pdf, LumasPdfConsts.cfFlate)
        LumasPdf.pdfSetJPEGQuality(pdf, 70)

        Dim inFile As String = AppPath() & "\in.emf"
        Dim outFile As String = AppPath() & "\out.pdf"

        If LumasPdf.pdfCreateNewPDFW(pdf, "") = 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If

        LumasPdf.pdfSetCompressionLevel(pdf, TCompressionLevel.clNone)
        LumasPdf.pdfSetCompressionFilter(pdf, LumasPdfConsts.cfFlate)
        LumasPdf.pdfSetColorSpace(pdf, TPDFColorSpace.csDeviceRGB)
        LumasPdf.pdfSetMetaConvFlags(pdf, LumasPdfConsts.mfDefault)
        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)
        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetResolution(pdf, 300)
        LumasPdf.pdfSetJPEGQuality(pdf, 70)
        PlaceEMFCentered(pdf, inFile, LumasPdf.pdfGetPageWidth(pdf), LumasPdf.pdfGetPageHeight(pdf))
        LumasPdf.pdfEndPage(pdf)

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfFreePDF(pdf)
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
            If LumasPdf.pdfCloseFile(pdf) <> 0 Then
                Console.WriteLine("OK: " & outFile)
            End If
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

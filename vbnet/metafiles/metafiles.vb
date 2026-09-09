' metafiles -- VB.NET port of examples\Vb6\metafiles
Imports System
Imports LumasPdfSdk

Module modMetafiles
    Private errDel As TErrorProc
    Private Const CLR_RED As UInteger = 255UI
    Private Const MARGIN As Double = 10.0

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Private Sub PlaceEMFCentered(ByVal pdf As IntPtr, ByVal MFile As String, ByVal Width As Double, ByVal Height As Double)
        Dim x, y, w, h, sx As Double
        Dim r As TRectL
        LumasPdf.pdfGetLogMetafileSizeW(pdf, MFile, r)
        w = r.Right - r.Left
        h = r.Bottom - r.Top
        Width = Width - 2.0 * MARGIN
        Height = Height - 2.0 * MARGIN
        sx = Width / w
        If (h * sx <= Height) Then
            x = MARGIN
            h = h * sx
            y = (Height - h) / 2.0
            LumasPdf.pdfInsertMetafileW(pdf, MFile, x, y, Width, 0.0)
            LumasPdf.pdfSetStrokeColor(pdf, CLR_RED)
            LumasPdf.pdfRectangle(pdf, x, y, Width, h, TPathFillMode.fmStroke)
        Else
            sx = Height / h
            w = w * sx
            x = (Width - w) / 2.0
            y = MARGIN
            LumasPdf.pdfInsertMetafileW(pdf, MFile, x, y, 0.0, Height)
            LumasPdf.pdfSetStrokeColor(pdf, CLR_RED)
            LumasPdf.pdfRectangle(pdf, x, y, w, Height, TPathFillMode.fmStroke)
        End If
    End Sub

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        If LumasPdf.pdfCreateNewPDFW(pdf, "") = 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetOrientationEx(pdf, 90)
        PlaceEMFCentered(pdf, AppPath() & "\coords.emf", LumasPdf.pdfGetPageWidth(pdf), LumasPdf.pdfGetPageHeight(pdf))
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetOrientationEx(pdf, 90)
        PlaceEMFCentered(pdf, AppPath() & "\fulltest.emf", LumasPdf.pdfGetPageWidth(pdf), LumasPdf.pdfGetPageHeight(pdf))
        LumasPdf.pdfEndPage(pdf)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetOrientationEx(pdf, 90)
        PlaceEMFCentered(pdf, AppPath() & "\gdi.emf", LumasPdf.pdfGetPageWidth(pdf), LumasPdf.pdfGetPageHeight(pdf))
        LumasPdf.pdfEndPage(pdf)

        Dim outFile As String = AppPath() & "\out.pdf"
        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
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

' measure_lines -- VB.NET port of examples\Vb6\annotations\measure_lines
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module MeasureLines
    Private Const clCream As UInteger = 15793151UI
    Private Const clBlack As UInteger = 0UI
    Private errDel As TErrorProc

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Return 0
    End Function

    Sub Main()
        Dim a As Integer
        Dim x As Double, y As Double, w As Double, h As Double
        Dim txt As String
        Dim p As New TLineAnnotParms()

        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        LumasPdf.pdfAppend(pdf)

        w = 300.0
        h = 100.0
        x = LumasPdf.pdfGetPageWidth(pdf) / 2
        y = LumasPdf.pdfGetPageHeight(pdf) / 2

        LumasPdf.pdfSaveGraphicState(pdf)

        LumasPdf.pdfSetGStateFlags(pdf, LumasPdfConsts.gfRealTopDownCoords, False)
        LumasPdf.pdfRotateCoords(pdf, -30.0, x, y)

        x = -w / 2
        y = -h / 2

        LumasPdf.pdfSetFillColor(pdf, clCream)
        LumasPdf.pdfRectangle(pdf, x, y, w, h, TPathFillMode.fmFillStroke)

        ' Marshal the parameter record to unmanaged memory.
        p.Caption = True
        p.LeaderLineLen = 10.0F
        p.LeaderLineExtend = 4.0F
        p.LeaderLineOffset = 2.0F
        p.StructSize = CUInt(Marshal.SizeOf(GetType(TLineAnnotParms)))
        Dim pParms As IntPtr = Marshal.AllocHGlobal(CInt(p.StructSize))
        Marshal.StructureToPtr(p, pParms, False)

        txt = w.ToString("0.0")
        a = LumasPdf.pdfLineAnnotW(pdf, x, y, x + w, y, 1.0, TLineEndStyle.leClosedArrow, TLineEndStyle.leClosedArrow, clBlack, clBlack, TPDFColorSpace.csDeviceRGB, "This is a measure line", "Measure Line", txt)
        LumasPdf.pdfSetLineAnnotParms(pdf, a, -1, 0.0, pParms)

        txt = h.ToString("0.0")
        a = LumasPdf.pdfLineAnnotW(pdf, x, y + h, x, y, 1.0, TLineEndStyle.leClosedArrow, TLineEndStyle.leClosedArrow, clBlack, clBlack, TPDFColorSpace.csDeviceRGB, "This is a measure line", "Measure Line", txt)
        LumasPdf.pdfSetLineAnnotParms(pdf, a, -1, 0.0, pParms)

        Marshal.FreeHGlobal(pParms)

        LumasPdf.pdfRestoreGraphicState(pdf)

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

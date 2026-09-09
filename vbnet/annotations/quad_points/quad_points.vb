' quad_points -- VB.NET port of examples\Vb6\annotations\quad_points
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module QuadPoints
    Private Const clYellow As UInteger = 65535UI
    Private Const clRed As UInteger = 255UI
    Private Const clBlue As UInteger = 16711680UI
    Private errDel As TErrorProc

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Return 0
    End Function

    Private Sub IncY(ByVal points() As TFltPoint, ByVal Value As Single)
        Dim i As Integer
        For i = 0 To points.Length - 1
            points(i).y = points(i).y + Value
        Next i
    End Sub

    ' Push the managed array into unmanaged memory, call SetAnnotQuadPoints, free.
    Private Sub SetQuads(ByVal pdf As IntPtr, ByVal a As Integer, ByVal points() As TFltPoint)
        Dim elemSize As Integer = Marshal.SizeOf(GetType(TFltPoint))
        Dim buf As IntPtr = Marshal.AllocHGlobal(elemSize * points.Length)
        Dim i As Integer
        For i = 0 To points.Length - 1
            Marshal.StructureToPtr(points(i), CType(buf.ToInt64() + i * elemSize, IntPtr), False)
        Next i
        LumasPdf.pdfSetAnnotQuadPoints(pdf, a, buf, CUInt(points.Length))
        Marshal.FreeHGlobal(buf)
    End Sub

    Sub Main()
        Dim a As Integer
        Dim d As Single, w As Single
        Dim text As String
        Dim points(3) As TFltPoint

        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        LumasPdf.pdfAppend(pdf)

        LumasPdf.pdfSaveGraphicState(pdf)

        LumasPdf.pdfSetGStateFlags(pdf, LumasPdfConsts.gfRealTopDownCoords, False)
        LumasPdf.pdfRotateCoords(pdf, -30.0, 50.0, 200.0)

        text = "Some rotated text on a page..."
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 20.0, False, TCodepage.cp1252)

        d = CSng(LumasPdf.pdfGetDescent(pdf))
        w = CSng(LumasPdf.pdfGetTextWidthW(pdf, text))

        LumasPdf.pdfWriteTextW(pdf, 0.0, 0.0, text)
        a = LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, "Test app", "Highligh Annotations", "This is a highlight annotation")
        points(0).x = 0.0F : points(0).y = d
        points(1).x = w : points(1).y = d
        points(2).x = 0.0F : points(2).y = 20.0F + d
        points(3).x = w : points(3).y = 20.0F + d
        SetQuads(pdf, a, points)

        LumasPdf.pdfWriteTextW(pdf, 0.0, 30.0, text)
        a = LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atSquiggly, 50.0, 80.0, w, 20.0, clRed, "Test app", "Squiggly Annotations", "This is a squiggly annotation")
        IncY(points, 30.0F)
        SetQuads(pdf, a, points)

        LumasPdf.pdfWriteTextW(pdf, 0.0, 60.0, text)
        a = LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atStrikeOut, 50.0, 110.0, w, 20.0, clRed, "Test app", "Strikeout Annotations", "This is a strikeout annotation")
        IncY(points, 30.0F)
        SetQuads(pdf, a, points)

        LumasPdf.pdfWriteTextW(pdf, 0.0, 90.0, text)
        a = LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atUnderline, 50.0, 140.0, w, 20.0, clRed, "Test app", "Underline Annotations", "This is a underline annotation")
        IncY(points, 30.0F)
        SetQuads(pdf, a, points)

        text = "Link annotations support quad points too"
        w = CSng(LumasPdf.pdfGetTextWidthW(pdf, text))
        LumasPdf.pdfWriteTextW(pdf, 0.0, 120.0, text)
        a = LumasPdf.pdfWebLinkW(pdf, 0.0, 120.0, w, 20.0, "www.dynaforms.com")
        LumasPdf.pdfSetAnnotBorderWidth(pdf, a, 1.0)
        LumasPdf.pdfSetAnnotColor(pdf, a, TFieldColor.fcBorderColor, TPDFColorSpace.csDeviceRGB, clBlue)
        points(0).x = 0.0F : points(0).y = 120.0F + d
        points(1).x = w : points(1).y = 120.0F + d
        points(2).x = 0.0F : points(2).y = 140.0F + d
        points(3).x = w : points(3).y = 140.0F + d
        SetQuads(pdf, a, points)

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

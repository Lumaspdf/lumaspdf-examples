' alpha_transparency -- VB.NET port of examples\Vb6\transparency\alpha_transparency\alpha_transparency.bas
' Draws an image at fill alpha 0.5 and a second at the default alpha 1.0 using
' extended graphics states.
Imports System
Imports LumasPdfSdk

Module modAlphaTransparency
    Private Const clWhite As Integer = &HFFFFFF
    Private Const clBlack As Integer = &H0
    Private ErrDelegate As TErrorProc

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim pdf As IntPtr, gs As Integer, img As Integer
        Dim outFile As String
        Dim g As TPDFExtGState

        pdf = LumasPdf.pdfNewPDF()
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)
        LumasPdf.pdfCreateNewPDFW(pdf, "")   ' The output file is opened later

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        ' Disable color key masking for images
        LumasPdf.pdfSetUseTransparency(pdf, False)

        LumasPdf.pdfAppend(pdf)

        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 12.0, 0, TCodepage.cp1252)
        LumasPdf.pdfWriteTextW(pdf, 50.0, 50.0, "Fill Alpha = 0.5")

        LumasPdf.pdfRectangle(pdf, 50.0, 70.0, 110.0, 160.0, TPathFillMode.fmFill)
        LumasPdf.pdfSetFillColor(pdf, clWhite)
        LumasPdf.pdfWriteTextW(pdf, 55.0, 75.0, "Background")

        LumasPdf.pdfInitExtGState(g)
        g.FillAlpha = 0.5
        gs = LumasPdf.pdfCreateExtGState(pdf, g)
        LumasPdf.pdfSetExtGState(pdf, CUInt(gs))

        img = LumasPdf.pdfInsertImageExW(pdf, 60.0, 84.0, 200.0, 0.0, "../../../test_files/images/tree-frog-69813_640.jpg", 0)

        ' To restore an extended graphics state, create a second one that restores the changes and activate it.
        g.FillAlpha = 1.0
        gs = LumasPdf.pdfCreateExtGState(pdf, g)
        LumasPdf.pdfSetExtGState(pdf, CUInt(gs))

        LumasPdf.pdfSetFillColor(pdf, clBlack)
        LumasPdf.pdfWriteTextW(pdf, 340.0, 50.0, "Fill Alpha = 1.0 (default)")
        LumasPdf.pdfRectangle(pdf, 340.0, 70.0, 110.0, 160.0, TPathFillMode.fmFill)
        LumasPdf.pdfSetFillColor(pdf, clWhite)
        LumasPdf.pdfWriteTextW(pdf, 345.0, 75.0, "Background")
        LumasPdf.pdfPlaceImage(pdf, img, 350.0, 84.0, 200.0, 0.0)

        LumasPdf.pdfEndPage(pdf)

        ' No fatal error occurred?
        If LumasPdf.pdfHaveOpenDoc(pdf) Then
            outFile = AppPath() & "\out.pdf"
            If Not LumasPdf.pdfOpenOutputFileW(pdf, outFile) Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
            If LumasPdf.pdfCloseFile(pdf) Then
                Console.WriteLine("PDF file """ & outFile & """ successfully created!")
            End If
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

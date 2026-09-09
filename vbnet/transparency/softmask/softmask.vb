' softmask -- VB.NET port of examples\Vb6\transparency\softmask\softmask.bas
' Creates a transparency group used as a luminosity soft mask (radial shading)
' and applies it to an image.
Imports System
Imports LumasPdfSdk

Module modSoftmask
    Private ErrDelegate As TErrorProc

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim pdf As IntPtr, gs As Integer, grp As Integer, sh As Integer
        Dim outFile As String
        Dim g As TPDFExtGState
        Dim bbox As TPDFRect

        pdf = LumasPdf.pdfNewPDF()
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)
        LumasPdf.pdfCreateNewPDFW(pdf, "")   ' The output file is opened later

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        ' Disable color key masking for images
        LumasPdf.pdfSetUseTransparency(pdf, False)

        LumasPdf.pdfAppend(pdf)

        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 12.0, 0, TCodepage.cp1252)
        LumasPdf.pdfWriteTextW(pdf, 50.0, 50.0, "Transparency effect with a soft mask.")

        LumasPdf.pdfInsertImageExW(pdf, 50.0, 80.0, LumasPdf.pdfGetPageWidth(pdf) - 100.0, 0.0, "../../../test_files/images/meadow-110719_640.jpg", 1)

        ' A transparency group used as a soft mask has no own coordinate system. Creating it in the full
        ' page size avoids coordinate issues; the real bounding box is computed after it is fully defined.
        grp = LumasPdf.pdfBeginTransparencyGroup(pdf, 0.0, 0.0, LumasPdf.pdfGetPageWidth(pdf), LumasPdf.pdfGetPageHeight(pdf), True, False, TExtColorSpace.esDeviceGray, -1)
        LumasPdf.pdfSetColorSpace(pdf, CInt(TPDFColorSpace.csDeviceGray))
        sh = LumasPdf.pdfCreateRadialShading(pdf, 400.0, 230.0, 20.0, 400.0, 230.0, 150.0, 1.0, 255, 0, 1, 0)
        LumasPdf.pdfApplyShading(pdf, sh)
        ' Optional but recommended: compute the real bounding box of the group used as soft mask.
        LumasPdf.pdfComputeBBox(pdf, bbox, CUInt(LumasPdfConsts.cbfNone))
        LumasPdf.pdfSetBBox(pdf, TPageBoundary.pbMediaBox, bbox.Left, bbox.Bottom, bbox.Right, bbox.Top)
        LumasPdf.pdfEndTemplate(pdf)

        LumasPdf.pdfInitExtGState(g)
        g.SoftMask = LumasPdf.pdfCreateSoftMask(pdf, CUInt(grp), TSoftMaskType.smtLuminosity, 0)
        gs = LumasPdf.pdfCreateExtGState(pdf, g)

        ' Activate the mask and draw an image
        LumasPdf.pdfSetExtGState(pdf, CUInt(gs))
        LumasPdf.pdfInsertImageExW(pdf, 220.0, 80.0, 500.0, 0.0, "../../../test_files/images/tree-frog-69813_640.jpg", 1)

        ' The soft mask can be deactivated as follows:
        LumasPdf.pdfInitExtGState(g)
        g.SoftMaskNone = True
        gs = LumasPdf.pdfCreateExtGState(pdf, g)
        LumasPdf.pdfSetExtGState(pdf, CUInt(gs))

        LumasPdf.pdfWriteTextW(pdf, 50.0, 400.0, "The soft mask is now deactivated.")
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

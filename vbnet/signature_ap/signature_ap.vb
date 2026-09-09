' signature_ap -- VB.NET port of examples\Vb6\signature_ap\signature_ap.bas
' Builds a page with a digitally-signed signature field whose appearance
' template is drawn with normal PDF functions (shadings, ellipse, text), then
' signs the file with a self-signed certificate.
Imports System
Imports System.IO
Imports LumasPdfSdk

Module modSignatureAP
    Private ErrDelegate As TErrorProc

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Function RGB(ByVal r As Integer, ByVal g As Integer, ByVal b As Integer) As UInteger
        Return CUInt(r Or (g << 8) Or (b << 16))
    End Function

    Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        Dim sigField As Integer, sh As Integer
        Dim outFile As String, body As String

        LumasPdf.pdfCreateNewPDFW(pdf, "")
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsNone, 14.0, 1, TCodepage.cp1252)
        body = "This file is digitally signed with a self sign certificate. " &
            "The appearance of the signature field is created with normal classic-API functions. However, it " &
            "would also be possible to import a PDF page, an EMF file, or an image into the " &
            "appearance template." & ChrW(10) & ChrW(10) &
            "When creating an individual signature appearance make sure to place the validation icon " &
            "properly with PlaceSigFieldValidateIcon(). The appearance of the validation icon " &
            "depends on the Acrobat version with which the file is opened. However, the unscaled size " &
            "of that icon is always 100.0 x 100.0 Units. It can be scaled to every size you want " &
            "but it is usually best to preserve the aspect ratio and the icon must be placed fully " &
            "inside the appearance template."
        LumasPdf.pdfWriteFTextW(pdf, LumasPdfConsts.taLeft, body)

        ' ---------------------- Signature field appearance ----------------------
        sigField = LumasPdf.pdfCreateSigField(pdf, "Signature", -1, 200.0, 500.0, 200.0, 80.0)
        LumasPdf.pdfSetFieldColor(pdf, CUInt(sigField), CInt(TFieldColor.fcBorderColor), CInt(TPDFColorSpace.csDeviceRGB), LumasPdfConsts.NO_COLOR)
        ' Place the validation icon on the left side of the signature field.
        LumasPdf.pdfPlaceSigFieldValidateIcon(pdf, CUInt(sigField), 0.0, 15.0, 50.0, 50.0)
        ' Creates a template that is already opened; must be closed with EndTemplate().
        LumasPdf.pdfCreateSigFieldAP(pdf, CUInt(sigField))

        LumasPdf.pdfSaveGraphicState(pdf)
        LumasPdf.pdfRectangle(pdf, 0.0, 0.0, 200.0, 80.0, TPathFillMode.fmNoFill)
        LumasPdf.pdfClipPath(pdf, TClippingMode.cmWinding, TPathFillMode.fmNoFill)
        sh = LumasPdf.pdfCreateAxialShading(pdf, 0.0, 0.0, 200.0, 0.0, 0.5, RGB(120, 120, 220), RGB(255, 255, 255), 1, 1)
        LumasPdf.pdfApplyShading(pdf, sh)
        LumasPdf.pdfRestoreGraphicState(pdf)

        LumasPdf.pdfSaveGraphicState(pdf)
        LumasPdf.pdfEllipse(pdf, 50.5, 1.0, 148.5, 78.0, TPathFillMode.fmNoFill)
        LumasPdf.pdfClipPath(pdf, TClippingMode.cmWinding, TPathFillMode.fmNoFill)
        sh = LumasPdf.pdfCreateAxialShading(pdf, 0.0, 0.0, 0.0, 78.0, 2.0, RGB(255, 255, 255), RGB(120, 120, 220), 1, 1)
        LumasPdf.pdfApplyShading(pdf, sh)
        LumasPdf.pdfRestoreGraphicState(pdf)

        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsBold Or LumasPdfConsts.fsUnderlined, 11.0, 1, TCodepage.cp1252)
        LumasPdf.pdfSetFillColor(pdf, RGB(120, 120, 220))
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 60.0, 150.0, -1.0, LumasPdfConsts.taCenter, "Digitally signed by:")
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsBold Or LumasPdfConsts.fsItalic, 18.0, 1, TCodepage.cp1252)
        LumasPdf.pdfSetFillColor(pdf, RGB(100, 100, 200))
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 45.0, 150.0, -1.0, LumasPdfConsts.taCenter, "LumasPDF")

        LumasPdf.pdfEndTemplate(pdf)                 ' Close the appearance template.
        ' ------------------------------------------------------------------------

        LumasPdf.pdfEndPage(pdf)

        ' No fatal error occurred?
        outFile = AppPath() & "\out.pdf"
        If LumasPdf.pdfHaveOpenDoc(pdf) Then
            If Not LumasPdf.pdfOpenOutputFileW(pdf, outFile) Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
        End If
        ' Original certificate ..\..\test_files\test_cert.pfx
        Dim certFile As String = "E:\LUMASPDFSDK\examples\test_files\test_cert.pfx"
        If LumasPdf.pdfCloseAndSignFile(pdf, certFile, "123456", "Test", "") Then
            Console.WriteLine("PDF file """ & outFile & """ successfully created!")
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

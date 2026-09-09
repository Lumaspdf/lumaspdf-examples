' signed_pdfa -- VB.NET port of examples\Vb6\signed_pdfa\signed_pdfa.bas
' Creates a PDF/A-1b compatible file with a digitally-signed signature field,
' checks conformance, adds the matching output intent, then signs the file
' with a self-signed certificate.
Imports System
Imports System.IO
Imports LumasPdfSdk

Module modSignedPDFA
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
        Dim cr As String = ChrW(13)
        ' Shared inputs, same files the Delphi original uses via ..\..\test_files\
        Dim tf As String = "E:\LUMASPDFSDK\examples\test_files\"

        LumasPdf.pdfCreateNewPDFW(pdf, "")
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsNone, 10.0, 1, TCodepage.cp1252)
        body = "This is a PDF/A 1b compatible PDF file that was digitally signed with " &
            "a self sign certificate. Because PDF/A requires that all fonts are embedded it is important " &
            "to avoid the usage of the 14 Standard fonts." & cr & cr &
            "When signing a PDF/A compliant PDF file with the default settings (without creation of a user " &
            "defined appearance) the font Arial must be available on the system because it is used to print " &
            "the certificate properties into the signature field." & cr & cr &
            "The font Arial must also be available if an empty signature field was added to the file " &
            "without signing it when closing the PDF file. Yes, it is still possible to sign a PDF/A " &
            "compliant PDF file later with Adobe's Acrobat. The signed PDF file is still compatible " &
            "to PDF/A. If you use a third party solution to digitally sign the PDF file then test " &
            "whether the signed file is still valid with the PDF/A 1b preflight tool included in Acrobat 8 " &
            "Professional." & cr & cr &
            "Signature fields must be visible and the print flag must be set (default). CheckConformance() " &
            "adjusts these flags if necessary and produces a warning if changes were applied. If no changes " &
            "should be allowed, just return -1 in the error callback function. If the error callback function " &
            "returns 0, DynaPDF assumes that the prior changes were accepted and processing continues." & cr & cr &
            "\FC[255]Notice:\FC[0]" & cr &
            "It makes no sense to execute CheckConformance() without an error callback function or error event " &
            "in VB. If you cannot see what happens during the execution of CheckConformance(), it is " &
            "completely useless to use this function!" & cr & cr &
            "CheckConformance() should be used to find the right settings to create PDF/A compatible PDF files. " &
            "Once the the settings were found it is usually not longer recommended to execute this function. " &
            "However, it is of course possible to use CheckConformance() as a general approach to make sure " &
            "that files created with DynaPDF are PDF/A compatible."
        LumasPdf.pdfWriteFTextW(pdf, LumasPdfConsts.taLeft, body)

        ' ---------------------- Signature field appearance ----------------------
        sigField = LumasPdf.pdfCreateSigField(pdf, "Signature", -1, 200.0, 400.0, 200.0, 80.0)
        LumasPdf.pdfSetFieldColor(pdf, CUInt(sigField), CInt(TFieldColor.fcBorderColor), CInt(TPDFColorSpace.csDeviceRGB), LumasPdfConsts.NO_COLOR)
        LumasPdf.pdfPlaceSigFieldValidateIcon(pdf, CUInt(sigField), 0.0, 15.0, 50.0, 50.0)
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
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 45.0, 150.0, -1.0, LumasPdfConsts.taCenter, "DynaPDF")

        LumasPdf.pdfEndTemplate(pdf)                 ' Close the appearance template.
        ' ------------------------------------------------------------------------

        LumasPdf.pdfEndPage(pdf)
        ' Check whether the file is compatible to PDF/A 1b. The CMYK profile is
        ' just an example profile that can be delivered with DynaPDF.
        Select Case LumasPdf.pdfCheckConformance(pdf, CInt(TConformanceType.ctPDFA_1b_2005), 0, IntPtr.Zero, Nothing, Nothing)
            Case 1, 3 : LumasPdf.pdfAddOutputIntentW(pdf, tf & "sRGB.icc")             ' Gray, RGB
            Case 2 : LumasPdf.pdfAddOutputIntentW(pdf, tf & "ISOcoated_v2_bas.ICC") ' CMYK
        End Select

        ' No fatal error occurred?
        outFile = AppPath() & "\out.pdf"
        If LumasPdf.pdfHaveOpenDoc(pdf) Then
            If Not LumasPdf.pdfOpenOutputFileW(pdf, outFile) Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
        End If
        If LumasPdf.pdfCloseAndSignFile(pdf, tf & "test_cert.pfx", "123456", "Test", "") Then
            Console.WriteLine("PDF file """ & outFile & """ successfully created!")
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

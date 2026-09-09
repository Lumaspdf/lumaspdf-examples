//  signed_pdfa -- C# port of examples\Vb6\signed_pdfa\signed_pdfa.bas
//  Creates a PDF/A-1b compatible file with a digitally-signed signature field,
//  checks conformance, adds the matching output intent, then signs the file
//  with a self-signed certificate.
using System;
using System.IO;
using LumasPdfSdk;

class SignedPDFA
{
    static uint RGB(int r, int g, int b)
    {
        return (uint)(r | (g << 8) | (b << 16));
    }

    // We try to continue if an error occurs
    static int ErrProc(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;
    }

    static TErrorProc _errCb = ErrProc;

    static void Main()
    {
        string cr = "\r";
        string tf = System.IO.Path.Combine(System.AppContext.BaseDirectory, "..", "..", "..", "..", "test_files");

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfCreateNewPDFW(pdf, "");        // The output file is opened later
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _errCb);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsNone, 10.0, true, TCodepage.cp1252);
        string body = "This is a PDF/A 1b compatible PDF file that was digitally signed with " +
            "a self sign certificate. Because PDF/A requires that all fonts are embedded it is important " +
            "to avoid the usage of the 14 Standard fonts." + cr + cr +
            "When signing a PDF/A compliant PDF file with the default settings (without creation of a user " +
            "defined appearance) the font Arial must be available on the system because it is used to print " +
            "the certificate properties into the signature field." + cr + cr +
            "The font Arial must also be available if an empty signature field was added to the file " +
            "without signing it when closing the PDF file. Yes, it is still possible to sign a PDF/A " +
            "compliant PDF file later with Adobe's Acrobat. The signed PDF file is still compatible " +
            "to PDF/A. If you use a third party solution to digitally sign the PDF file then test " +
            "whether the signed file is still valid with the PDF/A 1b preflight tool included in Acrobat 8 " +
            "Professional." + cr + cr +
            "Signature fields must be visible and the print flag must be set (default). CheckConformance() " +
            "adjusts these flags if necessary and produces a warning if changes were applied. If no changes " +
            "should be allowed, just return -1 in the error callback function. If the error callback function " +
            "returns 0, LumasPDF assumes that the prior changes were accepted and processing continues." + cr + cr +
            "\\FC[255]Notice:\\FC[0]" + cr +
            "It makes no sense to execute CheckConformance() without an error callback function or error event " +
            "in VB. If you cannot see what happens during the execution of CheckConformance(), it is " +
            "completely useless to use this function!" + cr + cr +
            "CheckConformance() should be used to find the right settings to create PDF/A compatible PDF files. " +
            "Once the the settings were found it is usually not longer recommended to execute this function. " +
            "However, it is of course possible to use CheckConformance() as a general approach to make sure " +
            "that files created with the classic API are PDF/A compatible.";
        LumasPdf.pdfWriteFTextW(pdf, LumasPdfConsts.taLeft, body);

        // ---------------------- Signature field appearance ----------------------
        int sigField = LumasPdf.pdfCreateSigField(pdf, "Signature", -1, 200.0, 400.0, 200.0, 80.0);
        LumasPdf.pdfSetFieldColor(pdf, (uint)sigField, (int)TFieldColor.fcBorderColor, (int)TPDFColorSpace.csDeviceRGB, LumasPdfConsts.NO_COLOR);
        LumasPdf.pdfPlaceSigFieldValidateIcon(pdf, (uint)sigField, 0.0, 15.0, 50.0, 50.0);
        LumasPdf.pdfCreateSigFieldAP(pdf, (uint)sigField);

        LumasPdf.pdfSaveGraphicState(pdf);
        LumasPdf.pdfRectangle(pdf, 0.0, 0.0, 200.0, 80.0, (int)TPathFillMode.fmNoFill);
        LumasPdf.pdfClipPath(pdf, TClippingMode.cmWinding, TPathFillMode.fmNoFill);
        int sh = LumasPdf.pdfCreateAxialShading(pdf, 0.0, 0.0, 200.0, 0.0, 0.5, RGB(120, 120, 220), RGB(255, 255, 255), 1, 1);
        LumasPdf.pdfApplyShading(pdf, sh);
        LumasPdf.pdfRestoreGraphicState(pdf);

        LumasPdf.pdfSaveGraphicState(pdf);
        LumasPdf.pdfEllipse(pdf, 50.5, 1.0, 148.5, 78.0, (int)TPathFillMode.fmNoFill);
        LumasPdf.pdfClipPath(pdf, TClippingMode.cmWinding, TPathFillMode.fmNoFill);
        sh = LumasPdf.pdfCreateAxialShading(pdf, 0.0, 0.0, 0.0, 78.0, 2.0, RGB(255, 255, 255), RGB(120, 120, 220), 1, 1);
        LumasPdf.pdfApplyShading(pdf, sh);
        LumasPdf.pdfRestoreGraphicState(pdf);

        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsBold | LumasPdfConsts.fsUnderlined, 11.0, true, TCodepage.cp1252);
        LumasPdf.pdfSetFillColor(pdf, RGB(120, 120, 220));
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 60.0, 150.0, -1.0, (int)LumasPdfConsts.taCenter, "Digitally signed by:");
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsBold | LumasPdfConsts.fsItalic, 18.0, true, TCodepage.cp1252);
        LumasPdf.pdfSetFillColor(pdf, RGB(100, 100, 200));
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 45.0, 150.0, -1.0, (int)LumasPdfConsts.taCenter, "LumasPDF");

        LumasPdf.pdfEndTemplate(pdf);              // Close the appearance template.
        // ------------------------------------------------------------------------

        LumasPdf.pdfEndPage(pdf);
        // Check whether the file is compatible to PDF/A 1b.
        switch (LumasPdf.pdfCheckConformance(pdf, (int)TConformanceType.ctPDFA_1b_2005, 0, IntPtr.Zero, null, null))
        {
            case 1:
            case 3:
                LumasPdf.pdfAddOutputIntentW(pdf, tf + "sRGB.icc");             // Gray, RGB
                break;
            case 2:
                LumasPdf.pdfAddOutputIntentW(pdf, tf + "ISOcoated_v2_bas.ICC"); // CMYK
                break;
        }

        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
        // No fatal error occurred?
        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
        }
        // Original certificate ..\..\test_files\test_cert.pfx
        string certFile = System.IO.Path.Combine(System.AppContext.BaseDirectory, "..", "..", "..", "..", "test_files") + "\\test_cert.pfx";
        if (LumasPdf.pdfCloseAndSignFile(pdf, certFile, "123456", "Test", ""))
            Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");

        LumasPdf.pdfDeletePDF(pdf);
    }
}

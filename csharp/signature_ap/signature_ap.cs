//  signature_ap -- C# port of examples\Vb6\signature_ap\signature_ap.bas
//  Builds a page with a digitally-signed signature field whose appearance
//  template is drawn with normal PDF functions (shadings, ellipse, text),
//  then signs the file with a self-signed certificate.
using System;
using System.IO;
using LumasPdfSdk;

class SignatureAP
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
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfCreateNewPDFW(pdf, "");        // The output file is opened later
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _errCb);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsNone, 14.0, true, TCodepage.cp1252);
        string body = "This file is digitally signed with a self sign certificate. " +
            "The appearance of the signature field is created with normal classic-API functions. However, it " +
            "would also be possible to import a PDF page, an EMF file, or an image into the " +
            "appearance template.\n\n" +
            "When creating an individual signature appearance make sure to place the validation icon " +
            "properly with PlaceSigFieldValidateIcon(). The appearance of the validation icon " +
            "depends on the Acrobat version with which the file is opened. However, the unscaled size " +
            "of that icon is always 100.0 x 100.0 Units. It can be scaled to every size you want " +
            "but it is usually best to preserve the aspect ratio and the icon must be placed fully " +
            "inside the appearance template.";
        LumasPdf.pdfWriteFTextW(pdf, LumasPdfConsts.taLeft, body);

        // ---------------------- Signature field appearance ----------------------
        int sigField = LumasPdf.pdfCreateSigField(pdf, "Signature", -1, 200.0, 500.0, 200.0, 80.0);
        LumasPdf.pdfSetFieldColor(pdf, (uint)sigField, (int)TFieldColor.fcBorderColor, (int)TPDFColorSpace.csDeviceRGB, LumasPdfConsts.NO_COLOR);
        // Place the validation icon on the left side of the signature field.
        LumasPdf.pdfPlaceSigFieldValidateIcon(pdf, (uint)sigField, 0.0, 15.0, 50.0, 50.0);
        // Creates a template that is already opened; must be closed with EndTemplate().
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

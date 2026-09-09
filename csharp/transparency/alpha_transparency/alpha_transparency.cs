//  alpha_transparency -- C# port of examples\Vb6\transparency\alpha_transparency\alpha_transparency.bas
//  Draws an image at fill alpha 0.5 and a second at the default alpha 1.0 using
//  extended graphics states.
using System;
using System.IO;
using LumasPdfSdk;

class AlphaTransparency
{
    const uint clWhite = 0xFFFFFF;
    const uint clBlack = 0x0;

    // Error callback. We try to continue if an error occurs.
    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;
    }
    static TErrorProc _errCb = PDFError;

    static void Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _errCb);
        LumasPdf.pdfCreateNewPDFW(pdf, "");   // The output file is opened later

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        // Disable color key masking for images
        LumasPdf.pdfSetUseTransparency(pdf, false);

        LumasPdf.pdfAppend(pdf);

        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 12.0, false, TCodepage.cp1252);
        LumasPdf.pdfWriteTextW(pdf, 50.0, 50.0, "Fill Alpha = 0.5");

        LumasPdf.pdfRectangle(pdf, 50.0, 70.0, 110.0, 160.0, (int)TPathFillMode.fmFill);
        LumasPdf.pdfSetFillColor(pdf, clWhite);
        LumasPdf.pdfWriteTextW(pdf, 55.0, 75.0, "Background");

        TPDFExtGState g = new TPDFExtGState();
        LumasPdf.pdfInitExtGState(ref g);
        g.FillAlpha = 0.5f;
        int gs = LumasPdf.pdfCreateExtGState(pdf, ref g);
        LumasPdf.pdfSetExtGState(pdf, (uint)gs);

        int img = LumasPdf.pdfInsertImageExW(pdf, 60.0, 84.0, 200.0, 0.0,
            "../../../test_files/images/tree-frog-69813_640.jpg", 0);

        // To restore an extended graphics state, create a second one that restores the changes and activate it.
        g.FillAlpha = 1.0f;
        gs = LumasPdf.pdfCreateExtGState(pdf, ref g);
        LumasPdf.pdfSetExtGState(pdf, (uint)gs);

        LumasPdf.pdfSetFillColor(pdf, clBlack);
        LumasPdf.pdfWriteTextW(pdf, 340.0, 50.0, "Fill Alpha = 1.0 (default)");
        LumasPdf.pdfRectangle(pdf, 340.0, 70.0, 110.0, 160.0, (int)TPathFillMode.fmFill);
        LumasPdf.pdfSetFillColor(pdf, clWhite);
        LumasPdf.pdfWriteTextW(pdf, 345.0, 75.0, "Background");
        LumasPdf.pdfPlaceImage(pdf, img, 350.0, 84.0, 200.0, 0.0);

        LumasPdf.pdfEndPage(pdf);

        // No fatal error occurred?
        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
            if (LumasPdf.pdfCloseFile(pdf))
            {
                Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
            }
        }

        LumasPdf.pdfDeletePDF(pdf);
    }
}

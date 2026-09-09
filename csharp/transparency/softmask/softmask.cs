//  softmask -- C# port of examples\Vb6\transparency\softmask\softmask.bas
//  Creates a transparency group used as a luminosity soft mask (radial shading)
//  and applies it to an image.
using System;
using System.IO;
using LumasPdfSdk;

class Softmask
{
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
        LumasPdf.pdfWriteTextW(pdf, 50.0, 50.0, "Transparency effect with a soft mask.");

        LumasPdf.pdfInsertImageExW(pdf, 50.0, 80.0, LumasPdf.pdfGetPageWidth(pdf) - 100.0, 0.0,
            "../../../test_files/images/meadow-110719_640.jpg", 1);

        // A transparency group used as a soft mask has no own coordinate system. Creating it in the full
        // page size avoids coordinate issues; the real bounding box is computed after it is fully defined.
        int grp = LumasPdf.pdfBeginTransparencyGroup(pdf, 0.0, 0.0,
            LumasPdf.pdfGetPageWidth(pdf), LumasPdf.pdfGetPageHeight(pdf),
            true, false, TExtColorSpace.esDeviceGray, -1);
        LumasPdf.pdfSetColorSpace(pdf, (int)TPDFColorSpace.csDeviceGray);
        int sh = LumasPdf.pdfCreateRadialShading(pdf, 400.0, 230.0, 20.0, 400.0, 230.0, 150.0, 1.0, 255, 0, 1, 0);
        LumasPdf.pdfApplyShading(pdf, sh);
        // Optional but recommended: compute the real bounding box of the group used as soft mask.
        TPDFRect bbox = new TPDFRect();
        LumasPdf.pdfComputeBBox(pdf, ref bbox, LumasPdfConsts.cbfNone);
        LumasPdf.pdfSetBBox(pdf, TPageBoundary.pbMediaBox, bbox.Left, bbox.Bottom, bbox.Right, bbox.Top);
        LumasPdf.pdfEndTemplate(pdf);

        TPDFExtGState g = new TPDFExtGState();
        LumasPdf.pdfInitExtGState(ref g);
        g.SoftMask = LumasPdf.pdfCreateSoftMask(pdf, (uint)grp, TSoftMaskType.smtLuminosity, 0);
        int gs = LumasPdf.pdfCreateExtGState(pdf, ref g);

        // Activate the mask and draw an image
        LumasPdf.pdfSetExtGState(pdf, (uint)gs);
        LumasPdf.pdfInsertImageExW(pdf, 220.0, 80.0, 500.0, 0.0,
            "../../../test_files/images/tree-frog-69813_640.jpg", 1);

        // The soft mask can be deactivated as follows:
        LumasPdf.pdfInitExtGState(ref g);
        g.SoftMaskNone = true;
        gs = LumasPdf.pdfCreateExtGState(pdf, ref g);
        LumasPdf.pdfSetExtGState(pdf, (uint)gs);

        LumasPdf.pdfWriteTextW(pdf, 50.0, 400.0, "The soft mask is now deactivated.");
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

// ============================================================================
//  metafiles_gui -- C# port of examples\Vb6\metafiles_gui\metafiles_gui.bas
//  The Delphi/VB6 original was a GUI metafile viewer/converter; the interactive
//  tree/paintbox/zoom UI is dropped. This console port loads a fixed EMF/WMF
//  file, places it centered on a page and writes out.pdf. Conversion flags
//  default to mfDefault.
// ============================================================================
using System;
using System.IO;
using LumasPdfSdk;

class MetafilesGui
{
    const double MARGIN = 10.0;

    static TErrorProc _err = ErrProc;

    static int ErrProc(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return 0;
    }

    // Places a metafile centered on the page, preserving the aspect ratio.
    static void PlaceEMFCentered(IntPtr pdf, string mFile, double width, double height)
    {
        TRectL r = new TRectL();
        LumasPdf.pdfGetLogMetafileSize(pdf, mFile, ref r);
        double w = r.Right - r.Left;
        double h = r.Bottom - r.Top;
        width = width - 2.0 * MARGIN;
        height = height - 2.0 * MARGIN;
        double sx = width / w;
        double x, y;
        if (h * sx <= height)
        {
            x = MARGIN;
            y = MARGIN;
            LumasPdf.pdfInsertMetafile(pdf, mFile, x, y, width, 0.0);
        }
        else
        {
            sx = height / h;
            w = w * sx;
            x = MARGIN + (width - w) / 2.0;
            y = MARGIN;
            LumasPdf.pdfInsertMetafile(pdf, mFile, x, y, 0.0, height);
        }
    }

    static void Main()
    {
        string exeDir = AppDomain.CurrentDomain.BaseDirectory;

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        // We use flate compression for better transparency support.
        LumasPdf.pdfSetCompressionFilter(pdf, LumasPdfConsts.cfFlate);
        LumasPdf.pdfSetJPEGQuality(pdf, 70);

        string inFile = Path.Combine(exeDir, "in.emf");
        string outFile = Path.Combine(exeDir, "out.pdf");

        if (!LumasPdf.pdfCreateNewPDFW(pdf, ""))
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        LumasPdf.pdfSetCompressionLevel(pdf, (int)TCompressionLevel.clNone);   // "compress" off
        LumasPdf.pdfSetCompressionFilter(pdf, LumasPdfConsts.cfFlate);         // "JPEG" off
        LumasPdf.pdfSetColorSpace(pdf, (int)TPDFColorSpace.csDeviceRGB);       // "CMYK" off
        LumasPdf.pdfSetMetaConvFlags(pdf, (int)LumasPdfConsts.mfDefault);      // no preview flags
        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);
        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfSetResolution(pdf, 300);
        LumasPdf.pdfSetJPEGQuality(pdf, 70);
        PlaceEMFCentered(pdf, inFile, LumasPdf.pdfGetPageWidth(pdf), LumasPdf.pdfGetPageHeight(pdf));
        LumasPdf.pdfEndPage(pdf);

        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfFreePDF(pdf);
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
            if (LumasPdf.pdfCloseFile(pdf))
                Console.WriteLine("OK: " + outFile);
        }

        LumasPdf.pdfDeletePDF(pdf);
    }
}

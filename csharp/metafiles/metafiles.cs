// ============================================================================
//  metafiles -- C# port of examples\Vb6\metafiles\metafiles.bas
//  Places three EMF metafiles, each centered and scaled to a landscape page,
//  with a red frame around them.
// ============================================================================
using System;
using System.IO;
using LumasPdfSdk;

class Metafiles
{
    const uint CLR_RED = 255;
    const double MARGIN = 10.0;

    static TErrorProc _err = ErrProc;

    static int ErrProc(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return 0;
    }

    static void PlaceEMFCentered(IntPtr pdf, string mFile, double width, double height)
    {
        TRectL r = new TRectL();
        LumasPdf.pdfGetLogMetafileSizeW(pdf, mFile, ref r);
        double w = r.Right - r.Left;
        double h = r.Bottom - r.Top;
        width = width - 2.0 * MARGIN;
        height = height - 2.0 * MARGIN;
        double sx = width / w;

        double x, y;
        if (h * sx <= height)
        {
            x = MARGIN;
            h = h * sx;
            y = (height - h) / 2.0;
            LumasPdf.pdfInsertMetafileW(pdf, mFile, x, y, width, 0.0);
            LumasPdf.pdfSetStrokeColor(pdf, CLR_RED);
            LumasPdf.pdfRectangle(pdf, x, y, width, h, (int)TPathFillMode.fmStroke);
        }
        else
        {
            sx = height / h;
            w = w * sx;
            x = (width - w) / 2.0;
            y = MARGIN;
            LumasPdf.pdfInsertMetafileW(pdf, mFile, x, y, 0.0, height);
            LumasPdf.pdfSetStrokeColor(pdf, CLR_RED);
            LumasPdf.pdfRectangle(pdf, x, y, w, height, (int)TPathFillMode.fmStroke);
        }
    }

    static void Main()
    {
        string exeDir = AppDomain.CurrentDomain.BaseDirectory;

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        if (!LumasPdf.pdfCreateNewPDFW(pdf, ""))       // output file opened later
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        string[] emfs = { "coords.emf", "fulltest.emf", "gdi.emf" };
        foreach (string emf in emfs)
        {
            LumasPdf.pdfAppend(pdf);
            LumasPdf.pdfSetOrientationEx(pdf, 90);
            PlaceEMFCentered(pdf, Path.Combine(exeDir, emf),
                LumasPdf.pdfGetPageWidth(pdf), LumasPdf.pdfGetPageHeight(pdf));
            LumasPdf.pdfEndPage(pdf);
        }

        string outFile = Path.Combine(exeDir, "out.pdf");
        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
        }
        if (LumasPdf.pdfCloseFile(pdf))
            Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
        LumasPdf.pdfDeletePDF(pdf);
    }
}

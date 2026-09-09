//  measure_lines -- C# port of examples\Vb6\annotations\measure_lines\measure_lines.bas
//  Two dimension/measure line annotations on a rotated rectangle, configured
//  through a TLineAnnotParms record.
using System;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class MeasureLines
{
    const uint clCream = 15793151;
    const uint clBlack = 0;

    static readonly TErrorProc _err = PDFError;
    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType) { return 0; }

    static void Main()
    {
        double x, y, w, h;
        IntPtr pdf = LumasPdf.pdfNewPDF();

        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfAppend(pdf);

        w = 300.0;
        h = 100.0;
        x = LumasPdf.pdfGetPageWidth(pdf) / 2;
        y = LumasPdf.pdfGetPageHeight(pdf) / 2;

        // Save the graphics state because the coordinate system will be rotated.
        LumasPdf.pdfSaveGraphicState(pdf);

        LumasPdf.pdfSetGStateFlags(pdf, LumasPdfConsts.gfRealTopDownCoords, false);
        LumasPdf.pdfRotateCoords(pdf, -30.0, x, y);

        x = -w / 2;
        y = -h / 2;

        LumasPdf.pdfSetFillColor(pdf, clCream);
        LumasPdf.pdfRectangle(pdf, x, y, w, h, (int)TPathFillMode.fmFillStroke);

        var p = new TLineAnnotParms();
        p.StructSize = (uint)Marshal.SizeOf(typeof(TLineAnnotParms));
        p.Caption = true;              // Content of LineAnnot() is used as caption.
        p.LeaderLineLen = 10f;
        p.LeaderLineExtend = 4f;
        p.LeaderLineOffset = 2f;

        IntPtr parms = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(TLineAnnotParms)));
        try
        {
            Marshal.StructureToPtr(p, parms, false);

            string txt = w.ToString("0.0", CultureInfo.InvariantCulture);
            int a = LumasPdf.pdfLineAnnotW(pdf, x, y, x + w, y, 1, TLineEndStyle.leClosedArrow, TLineEndStyle.leClosedArrow, clBlack, clBlack, TPDFColorSpace.csDeviceRGB, "This is a measure line", "Measure Line", txt);
            LumasPdf.pdfSetLineAnnotParms(pdf, (uint)a, -1, 0, parms);

            txt = h.ToString("0.0", CultureInfo.InvariantCulture);
            a = LumasPdf.pdfLineAnnotW(pdf, x, y + h, x, y, 1, TLineEndStyle.leClosedArrow, TLineEndStyle.leClosedArrow, clBlack, clBlack, TPDFColorSpace.csDeviceRGB, "This is a measure line", "Measure Line", txt);
            // The parameters are exactly the same as above.
            LumasPdf.pdfSetLineAnnotParms(pdf, (uint)a, -1, 0, parms);
        }
        finally
        {
            Marshal.FreeHGlobal(parms);
        }

        LumasPdf.pdfRestoreGraphicState(pdf);

        LumasPdf.pdfEndPage(pdf);

        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile)) { LumasPdf.pdfDeletePDF(pdf); return; }
            if (LumasPdf.pdfCloseFile(pdf))
                Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
        }

        LumasPdf.pdfDeletePDF(pdf);
    }
}

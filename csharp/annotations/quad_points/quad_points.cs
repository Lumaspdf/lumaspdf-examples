//  quad_points -- C# port of examples\Vb6\annotations\quad_points\quad_points.bas
//  Highlight and link annotations rotated with the coordinate system by setting
//  their quad points explicitly.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class QuadPoints
{
    const uint clYellow = 65535;
    const uint clRed = 255;
    const uint clBlue = 16711680;

    static readonly TErrorProc _err = PDFError;
    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType) { return 0; }

    // Increment the y-coordinate of every point (Delphi IncY helper).
    static void IncY(TFltPoint[] points, float value)
    {
        for (int i = 0; i < points.Length; i++)
            points[i].y += value;
    }

    static void SetQuad(IntPtr pdf, int handle, TFltPoint[] points)
    {
        GCHandle gch = GCHandle.Alloc(points, GCHandleType.Pinned);
        try
        {
            LumasPdf.pdfSetAnnotQuadPoints(pdf, (uint)handle, gch.AddrOfPinnedObject(), (uint)points.Length);
        }
        finally
        {
            gch.Free();
        }
    }

    static void Main()
    {
        float d, w;
        IntPtr pdf = LumasPdf.pdfNewPDF();
        var points = new TFltPoint[4];

        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfAppend(pdf);

        LumasPdf.pdfSaveGraphicState(pdf);

        LumasPdf.pdfSetGStateFlags(pdf, LumasPdfConsts.gfRealTopDownCoords, false);
        LumasPdf.pdfRotateCoords(pdf, -30.0, 50, 200);

        string text = "Some rotated text on a page...";
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 20.0, false, TCodepage.cp1252);

        d = (float)LumasPdf.pdfGetDescent(pdf);
        w = (float)LumasPdf.pdfGetTextWidthW(pdf, text);

        // Highlight annotations do not consider coordinate transformations made on a page.
        // To get such annotations rotated we must set the annotation's quad points.
        LumasPdf.pdfWriteTextW(pdf, 0, 0, text);
        int a = LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atHighlight, 50, 50 + d, w, 20, clYellow, "Test app", "Highligh Annotations", "This is a highlight annotation");
        // Consider the unusual order of the points!
        points[0].x = 0; points[0].y = d;          // Top left corner
        points[1].x = w; points[1].y = d;          // Top right corner
        points[2].x = 0; points[2].y = 20 + d;     // Bottom left corner
        points[3].x = w; points[3].y = 20 + d;     // Bottom right corner
        SetQuad(pdf, a, points);

        LumasPdf.pdfWriteTextW(pdf, 0, 30, text);
        a = LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atSquiggly, 50, 80, w, 20, clRed, "Test app", "Squiggly Annotations", "This is a squiggly annotation");
        IncY(points, 30);
        SetQuad(pdf, a, points);

        LumasPdf.pdfWriteTextW(pdf, 0, 60, text);
        a = LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atStrikeOut, 50, 110, w, 20, clRed, "Test app", "Strikeout Annotations", "This is a strikeout annotation");
        IncY(points, 30);
        SetQuad(pdf, a, points);

        LumasPdf.pdfWriteTextW(pdf, 0, 90, text);
        a = LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atUnderline, 50, 140, w, 20, clRed, "Test app", "Underline Annotations", "This is a underline annotation");
        IncY(points, 30);
        SetQuad(pdf, a, points);

        text = "Link annotations support quad points too";
        w = (float)LumasPdf.pdfGetTextWidthW(pdf, text);
        LumasPdf.pdfWriteTextW(pdf, 0, 120, text);
        // Link annotations support quad points too.
        a = LumasPdf.pdfWebLinkW(pdf, 0, 120, w, 20, "www.lumaspdf.com");
        LumasPdf.pdfSetAnnotBorderWidth(pdf, (uint)a, 1);
        LumasPdf.pdfSetAnnotColor(pdf, (uint)a, TFieldColor.fcBorderColor, TPDFColorSpace.csDeviceRGB, clBlue);
        points[0].x = 0; points[0].y = 120 + d;   // Top left corner
        points[1].x = w; points[1].y = 120 + d;   // Top right corner
        points[2].x = 0; points[2].y = 140 + d;   // Bottom left corner
        points[3].x = w; points[3].y = 140 + d;   // Bottom right corner
        SetQuad(pdf, a, points);

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

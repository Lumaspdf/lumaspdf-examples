//  highlight_annotations -- C# port of examples\Vb6\annotations\highlight_annotations\highlight_annotations.bas
//  Highlight / squiggly / strikeout / underline annotations over text.
using System;
using System.IO;
using LumasPdfSdk;

class HighlightAnnotations
{
    const uint clYellow = 65535;
    const uint clRed = 255;

    static readonly TErrorProc _err = PDFError;
    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType) { return 0; }

    static void Main()
    {
        double d, w;
        IntPtr pdf = LumasPdf.pdfNewPDF();

        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfAppend(pdf);
        string text = "Some text on a page...";
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 20.0, false, TCodepage.cp1252);

        d = LumasPdf.pdfGetDescent(pdf);
        w = LumasPdf.pdfGetTextWidthW(pdf, text);

        LumasPdf.pdfWriteTextW(pdf, 50, 50, text);
        LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atHighlight, 50, 50 + d, w, 20, clYellow, "Test app", "Highligh Annotations", "This is a highlight annotation");

        LumasPdf.pdfWriteTextW(pdf, 50, 80, text);
        LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atSquiggly, 50, 80 + d, w, 20, clRed, "Test app", "Squiggly Annotations", "This is a squiggly annotation");

        LumasPdf.pdfWriteTextW(pdf, 50, 110, text);
        LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atStrikeOut, 50, 110 + d, w, 20, clRed, "Test app", "Strikeout Annotations", "This is a strikeout annotation");

        LumasPdf.pdfWriteTextW(pdf, 50, 140, text);
        LumasPdf.pdfHighlightAnnotW(pdf, TAnnotType.atUnderline, 50, 140 + d, w, 20, clRed, "Test app", "Underline Annotations", "This is a underline annotation");
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

//  stamps -- C# port of examples\Vb6\annotations\stamps\stamps.bas
//  A pre-defined "Approved" stamp rendered in English, German and French.
using System;
using System.IO;
using LumasPdfSdk;

class Stamps
{
    static uint RGB(int r, int g, int b) { return (uint)(r | (g << 8) | (b << 16)); }

    static readonly TErrorProc _err = PDFError;
    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType) { return 0; }

    static void Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();

        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfAppend(pdf);

        // A pre-defined stamp is scaled to the given width. The language can be set right before creating the stamp.
        int a = LumasPdf.pdfStampAnnotW(pdf, TRubberStamp.rsApproved, 135, 50, 300, 10, "Test app", "Stamp Annotations", "The default language is English!");
        LumasPdf.pdfSetAnnotColor(pdf, (uint)a, TFieldColor.fcBorderColor, TPDFColorSpace.csDeviceRGB, RGB(120, 190, 92));

        LumasPdf.pdfSetLanguage(pdf, "DE");
        a = LumasPdf.pdfStampAnnotW(pdf, TRubberStamp.rsApproved, 135, 150, 300, 10, "Test app", "Stamp Annotations", "The same stamp in German!");
        LumasPdf.pdfSetAnnotColor(pdf, (uint)a, TFieldColor.fcBorderColor, TPDFColorSpace.csDeviceRGB, RGB(230, 65, 132));

        LumasPdf.pdfSetLanguage(pdf, "FR");
        a = LumasPdf.pdfStampAnnotW(pdf, TRubberStamp.rsApproved, 135, 250, 300, 10, "Test app", "Stamp Annotations", "The same stamp in French!");
        LumasPdf.pdfSetAnnotColor(pdf, (uint)a, TFieldColor.fcBorderColor, TPDFColorSpace.csDeviceRGB, RGB(78, 157, 232));
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

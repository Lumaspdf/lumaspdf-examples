// personalize -- C# port of examples\Vb6\personalize\personalize.bas
// Imports a tax form, fills in the fields, adds a web link, writes out.pdf.
using System;
using System.IO;
using LumasPdfSdk;

class Personalize
{
    static TErrorProc _err = ErrProc;

    static int ErrProc(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return -1;                               // break processing on error
    }

    static uint RGB(int r, int g, int b) { return (uint)(r | (g << 8) | (b << 16)); }

    static void Main()
    {
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfCreateNewPDFW(pdf, "");            // output file opened later

        LumasPdf.pdfSetViewerPreferences(pdf, LumasPdfConsts.vpDisplayDocTitle, LumasPdfConsts.avNone);
        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);
        if (LumasPdf.pdfOpenImportFileW(pdf, Path.Combine(dir, "taxform.pdf"), (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0);

        LumasPdf.pdfEditPage(pdf, 1);
        LumasPdf.pdfSetFontW(pdf, "Courier", LumasPdfConsts.fsBold, 14.0, false, TCodepage.cp1252);
        LumasPdf.pdfWriteTextW(pdf, 72.5, 748.5, "X");
        LumasPdf.pdfWriteTextW(pdf, 74.0, 701.0, "Musterstadt");
        LumasPdf.pdfWriteTextW(pdf, 74.0, 677.0, "252/1062/3323");
        LumasPdf.pdfBeginContinueText(pdf, 74.0, 628.0);
        LumasPdf.pdfSetLeading(pdf, 24.0);
        LumasPdf.pdfSetCharacterSpacing(pdf, 5.8);
        LumasPdf.pdfAddContinueTextW(pdf, "Mustermann");
        LumasPdf.pdfAddContinueTextW(pdf, "Hermann");
        LumasPdf.pdfAddContinueTextW(pdf, "22021963keineKaufmann");
        LumasPdf.pdfAddContinueTextW(pdf, "Musterstra" + (char)223 + "e 145");  // 223 = sharp s in cp1252
        LumasPdf.pdfAddContinueTextW(pdf, "12345Musterstadt");
        LumasPdf.pdfSetCharacterSpacing(pdf, 0.0);
        LumasPdf.pdfSetFontW(pdf, "Courier", LumasPdfConsts.fsBold, 10.0, false, TCodepage.cp1252);
        LumasPdf.pdfSetLeading(pdf, 48.0);
        LumasPdf.pdfAddContinueTextW(pdf, "04.05.1994");
        LumasPdf.pdfSetFontW(pdf, "Courier", LumasPdfConsts.fsBold, 14.0, false, TCodepage.cp1252);
        LumasPdf.pdfSetCharacterSpacing(pdf, 5.8);
        LumasPdf.pdfAddContinueTextW(pdf, "Sabine");
        LumasPdf.pdfSetLeading(pdf, 47.5);
        LumasPdf.pdfAddContinueTextW(pdf, "18121966 ev  Hausfrau");
        LumasPdf.pdfEndContinueText(pdf);
        LumasPdf.pdfWriteTextW(pdf, 72.5, 365.0, "X");
        LumasPdf.pdfWriteTextW(pdf, 396.0, 365.0, "X");
        LumasPdf.pdfBeginContinueText(pdf, 74.0, 316.0);
        LumasPdf.pdfSetLeading(pdf, 24.0);
        LumasPdf.pdfAddContinueTextW(pdf, "2346256780     76834560");
        LumasPdf.pdfAddContinueTextW(pdf, "Sparkasse Musterstadt");
        LumasPdf.pdfEndContinueText(pdf);
        LumasPdf.pdfWriteTextW(pdf, 72.5, 269.0, "X");
        LumasPdf.pdfSetCharacterSpacing(pdf, 0.0);
        LumasPdf.pdfSetFontW(pdf, "Courier", LumasPdfConsts.fsNone, 10.0, false, TCodepage.cp1252);
        LumasPdf.pdfWriteTextW(pdf, 53.0, 48.0, DateTime.Now.ToString());
        LumasPdf.pdfSetFillColor(pdf, RGB(0xFF, 0x66, 0x66));
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsBold, 22.0, false, TCodepage.cp1252);
        LumasPdf.pdfWriteTextW(pdf, 340.0, 70.0, "www.lumaspdf.com");
        LumasPdf.pdfSetLineWidth(pdf, 0.0);
        LumasPdf.pdfSetLinkHighlightMode(pdf, (int)THighlightMode.hmPush);
        LumasPdf.pdfSetAnnotFlags(pdf, LumasPdfConsts.afReadOnly);
        LumasPdf.pdfWebLinkW(pdf, 340.0, 64.0, 204.0, 22.0, "https://www.lumaspdf.com");
        LumasPdf.pdfEndPage(pdf);

        string outFile = Path.Combine(dir, "out.pdf");
        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, null);   // silence errors while opening
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
            LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        }
        if (LumasPdf.pdfCloseFile(pdf))
            Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
        LumasPdf.pdfDeletePDF(pdf);
    }
}

//  complex_text -- C# port of examples\Vb6\complex_text\complex_text\complex_text.bas
//  Complex text layout of a right-to-left (Pashto) text loaded as UTF-16 and
//  laid out with the wide version of WriteFTextEx().
using System;
using System.IO;
using System.Text;
using LumasPdfSdk;

class ComplexText
{
    static TErrorProc _err = ErrProc;
    static int ErrProc(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;
    }

    static string GetFileBuffer(string fileName)
    {
        try { return Encoding.Unicode.GetString(File.ReadAllBytes(fileName)); }
        catch { return ""; }
    }

    static void Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");        // We create no PDF file in this example

        string txt = GetFileBuffer(Path.GetFullPath(Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory, "../../../test_files/pashto.txt")));

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);
        LumasPdf.pdfSetGStateFlags(pdf, LumasPdfConsts.gfComplexText, false);
        LumasPdf.pdfSetBidiMode(pdf, (int)TPDFBidiMode.bmRightToLeft);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsRegular, 10.0, true, TCodepage.cpUnicode);
        LumasPdf.pdfSetLeading(pdf, LumasPdf.pdfGetTypoLeading(pdf));
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 50.0,
            LumasPdf.pdfGetPageWidth(pdf) - 100.0, LumasPdf.pdfGetPageHeight(pdf) - 100.0,
            (int)LumasPdfConsts.taJustify, txt);
        LumasPdf.pdfEndPage(pdf);

        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
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

// pdf_to_text -- C# port of examples\Vb6\pdf_to_text\pdf_to_text.bas
// Imports a PDF and extracts each page's text to out.txt.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class PdfToText
{
    const int emNoFuncNames = 0x10000000;   // do not print function names in errors
    static TErrorProc _err = ErrProc;

    static int ErrProc(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return 0;                            // try to continue on error
    }

    static void Main()
    {
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetErrorMode(pdf, emNoFuncNames);
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfSetCMapDirW(pdf, Path.Combine(dir, "CMap"), LumasPdfConsts.lcmRecursive | LumasPdfConsts.lcmDelayed);

        if (!LumasPdf.pdfCreateNewPDFW(pdf, ""))     // We do not produce a PDF file here.
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        // Import the page contents only.
        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifContentOnly | LumasPdfConsts.ifImportAsPage);
        string inFile = Path.Combine(dir, "in.pdf");
        if (LumasPdf.pdfOpenImportFileW(pdf, inFile, (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            LumasPdf.pdfFreePDF(pdf);
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }
        if (LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0)
        {
            LumasPdf.pdfFreePDF(pdf);
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }
        LumasPdf.pdfCloseImportFile(pdf);

        string outFile = Path.Combine(dir, "out.txt");
        using (StreamWriter w = new StreamWriter(outFile, false))
        {
            int count = LumasPdf.pdfGetPageCount(pdf);
            for (int i = 1; i <= count; i++)
            {
                w.WriteLine("----- Page " + i + " -----");
                LumasPdf.pdfEditPage(pdf, i);
                w.WriteLine(Marshal.PtrToStringAnsi(LumasPdf.pdfSplitPageTextW(pdf, (uint)i)));
                LumasPdf.pdfEndPage(pdf);
            }
        }

        LumasPdf.pdfFreePDF(pdf);
        Console.WriteLine("Text written to: " + outFile);
        LumasPdf.pdfDeletePDF(pdf);
    }
}

//  split_pdf -- C# port of examples\Vb6\split_pdf\split_pdf.bas
//  Opens one import file, keeps it open across CloseFile() via
//  SetUseGlobalImpFiles, and writes each page into its own PDF.
using System;
using System.IO;
using LumasPdfSdk;

class SplitPdf
{
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

        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage); // avoid conversion of pages to templates
        LumasPdf.pdfSetImportFlags2(pdf, LumasPdfConsts.if2UseProxy);                                // reduces the memory usage

        // Original: '../../../license.pdf' -> resolved to the bundled import fixture.
        string inFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "license.pdf");
        if (LumasPdf.pdfOpenImportFileW(pdf, inFile, (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        // Keeps the open import file from being closed when CloseFile() is called.
        LumasPdf.pdfSetUseGlobalImpFiles(pdf, true);

        string outDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out");
        Directory.CreateDirectory(outDir);

        int count = LumasPdf.pdfGetInPageCount(pdf);
        for (int i = 1; i <= count; i++)
        {
            string outPath = Path.Combine(outDir, "page" + i.ToString("0000") + ".pdf");
            LumasPdf.pdfCreateNewPDFW(pdf, outPath);
            LumasPdf.pdfAppend(pdf);
            LumasPdf.pdfImportPageEx(pdf, (uint)i, 1.0, 1.0);
            LumasPdf.pdfEndPage(pdf);
            LumasPdf.pdfCloseFile(pdf);
        }

        // Always set the property back to false when finished.
        LumasPdf.pdfSetUseGlobalImpFiles(pdf, false);

        Console.WriteLine("Pages written to: " + outDir);
        LumasPdf.pdfDeletePDF(pdf);
    }
}

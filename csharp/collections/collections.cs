//  collections -- C# port of examples\Vb6\collections\collections.bas
//  Imports a cover page, creates a PDF portfolio (collection) and attaches
//  three files to it.
using System;
using System.IO;
using LumasPdfSdk;

class Collections
{
    static TErrorProc _err = ErrProc;
    static int ErrProc(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;
    }

    static string Rel(string rel)
    {
        return Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, rel));
    }

    static void Main()
    {
        int ef;
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfCreateNewPDFW(pdf, "");          // The output file is opened later
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);

        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);
        if (LumasPdf.pdfOpenImportFileW(pdf, Rel("../../test_files/collection_en.pdf"), (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            LumasPdf.pdfDeletePDF(pdf);
            Console.WriteLine("Input file \"../../test_files/collection_en.pdf\" not found!");
            return;
        }
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0);
        LumasPdf.pdfCloseImportFile(pdf);
        LumasPdf.pdfCreateCollection(pdf, (int)TColView.civTile);

        ef = LumasPdf.pdfAttachFileW(pdf, Rel("../../test_files/taxform.pdf"), "A PDF file...", true);
        LumasPdf.pdfSetColDefFile(pdf, (uint)ef);     // Opened when viewing in Acrobat 8 or later
        LumasPdf.pdfAttachFileW(pdf, Rel("../../test_files/fulltest.emf"), "An EMF file...", true);
        LumasPdf.pdfAttachFileW(pdf, Rel("../../test_files/sample.txt"), "A text file...", true);

        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
        }
        LumasPdf.pdfCloseFile(pdf);
        Console.WriteLine("PDF Collection \"" + outFile + "\" successfully created!");
        LumasPdf.pdfDeletePDF(pdf);
    }
}

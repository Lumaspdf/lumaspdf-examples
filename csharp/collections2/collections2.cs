//  collections2 -- C# port of examples\Vb6\collections2\collections2.bas
//  Like collections, but adds sortable collection fields and per-item field
//  values, then validates the collection.
using System;
using System.IO;
using LumasPdfSdk;

class Collections2
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
        LumasPdf.pdfCreateNewPDFW(pdf, "");
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

        // A user defined field Index so that we can sort it in every order we want.
        ef = LumasPdf.pdfCreateCollectionFieldW(pdf, (int)TColColumnType.cisCustomNumber, 0, "File index", "Index", false, true);
        LumasPdf.pdfSetColSortField(pdf, (uint)ef, true);

        LumasPdf.pdfCreateCollectionFieldW(pdf, (int)TColColumnType.cisFileName, 1, "File name", "", true, true);
        LumasPdf.pdfCreateCollectionFieldW(pdf, (int)TColColumnType.cisSize, 2, "File size", "", true, false);
        LumasPdf.pdfCreateCollectionFieldW(pdf, (int)TColColumnType.cisModDate, 3, "Modification date", "", true, false);

        ef = LumasPdf.pdfAttachFileW(pdf, Rel("../../test_files/taxform.pdf"), "A PDF file...", true);
        LumasPdf.pdfSetColDefFile(pdf, (uint)ef);
        LumasPdf.pdfCreateColItemNumber(pdf, (uint)ef, "Index", 0.0, "");

        ef = LumasPdf.pdfAttachFileW(pdf, Rel("../../test_files/fulltest.emf"), "An EMF file...", true);
        LumasPdf.pdfCreateColItemNumber(pdf, (uint)ef, "Index", 1.0, "");

        ef = LumasPdf.pdfAttachFileW(pdf, Rel("../../test_files/sample.txt"), "A text file...", true);
        LumasPdf.pdfCreateColItemNumber(pdf, (uint)ef, "Index", 2.0, "");

        // Let's check whether the collection is valid.
        LumasPdf.pdfCheckCollection(pdf);

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

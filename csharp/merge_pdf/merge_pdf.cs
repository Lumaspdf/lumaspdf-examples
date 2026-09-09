// ============================================================================
//  merge_pdf -- C# port of examples\Vb6\merge_pdf\merge_pdf.bas
//  Generic code to merge arbitrary PDF files (with special handling for
//  interactive forms / PDF collections).
// ============================================================================
using System;
using System.IO;
using LumasPdfSdk;

class MergePdf
{
    static TErrorProc _err = PDFError;

    static int PDFError(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return 0;
    }

    static string ExtractFileName(string path)
    {
        int p = path.LastIndexOf('\\');
        if (p < 0) p = path.LastIndexOf('/');
        return p < 0 ? path : path.Substring(p + 1);
    }

    static void Main()
    {
        string exeDir = AppDomain.CurrentDomain.BaseDirectory;

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");            // output file opened later

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 14.0, false, TCodepage.cp1252);
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 50.0, LumasPdf.pdfGetPageWidth(pdf) - 100.0, -1.0,
            (int)LumasPdfConsts.taJustify,
            "The following pages were imported from different PDF files. DynaPDF adjusts the destinations of link annotations and bookmarks so that " +
            "all destinations refer to the new page numbers after import." + "\r" + "\r" +
            "Entire PDF files can be easily merged with ImportPDFFile() but it is also possible to import only specific pages of an arbitrary number " +
            "of PDF files. You can also add further pages or edit imported pages if necessary. An existing page can be opened for editing with EditPage().");
        LumasPdf.pdfEndPage(pdf);

        bool first = true;
        int destPage = 1;
        bool haveXFA = false;
        bool isCollection = false;

        string[] files = new string[]
        {
            Path.Combine(exeDir, "license.pdf"),
            Path.Combine(exeDir, "dynapdf_help.pdf")
        };

        for (int i = 0; i <= 1; i++)
        {
            if (LumasPdf.pdfOpenImportFileW(pdf, files[i], (int)LumasPdfConsts.ptOpen, "") < 0)
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
            if (first)
            {
                first = false;
                haveXFA = LumasPdf.pdfGetInIsXFAForm(pdf) != 0;
                isCollection = LumasPdf.pdfGetInIsCollection(pdf) != 0;
                destPage = LumasPdf.pdfImportPDFFile(pdf, (uint)(destPage + 1), 1.0, 1.0);
                if (destPage < 0) break;
            }
            else
            {
                if (isCollection)
                {
                    if (LumasPdf.pdfGetInIsCollection(pdf) != 0)
                    {
                        // Import the embedded files only
                        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifEmbeddedFiles);
                        if (!LumasPdf.pdfImportCatalogObjects(pdf)) break;
                    }
                    else
                    {
                        LumasPdf.pdfCloseImportFile(pdf);
                        // Add the file to the collection
                        LumasPdf.pdfAttachFileW(pdf, files[i], ExtractFileName(files[i]), true);
                    }
                }
                else
                {
                    if ((LumasPdf.pdfGetInIsCollection(pdf) != 0) ||
                        (((LumasPdf.pdfGetInIsXFAForm(pdf) != 0) || (LumasPdf.pdfGetInFieldCount(pdf) > 0)) &&
                         ((LumasPdf.pdfGetFieldCount(pdf) > 0) || haveXFA)))
                        break;
                    LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);
                    LumasPdf.pdfSetImportFlags2(pdf, LumasPdfConsts.if2UseProxy);
                    destPage = LumasPdf.pdfImportPDFFile(pdf, (uint)(destPage + 1), 1.0, 1.0);
                    if (destPage < 0) break;
                }
            }
            LumasPdf.pdfCloseImportFile(pdf);
        }

        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            string outFile = Path.Combine(exeDir, "out.pdf");
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
            if (LumasPdf.pdfCloseFile(pdf))
                Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
        }
        LumasPdf.pdfDeletePDF(pdf);
    }
}

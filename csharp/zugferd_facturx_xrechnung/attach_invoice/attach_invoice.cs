//  attach_invoice -- C# port of examples\Vb6\zugferd_facturx_xrechnung\attach_invoice\attach_invoice.bas
//  Imports an existing PDF/A-3 invoice, attaches the factur-x.xml e-invoice,
//  associates it with the catalog and sets the FacturX Comfort PDF version.
using System;
using System.IO;
using LumasPdfSdk;

class AttachInvoice
{
    // We try to continue if an error occurs
    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;
    }

    static TErrorProc _errCb = PDFError;

    static void Main()
    {
        string tf = System.IO.Path.Combine(System.AppContext.BaseDirectory, "..", "..", "..", "..", "test_files");

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _errCb);
        LumasPdf.pdfCreateNewPDFW(pdf, "");        // The output file is opened later

        // We assume that the pdf invoice is already a valid PDF/A 3 file in this example.
        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAsPage | LumasPdfConsts.ifImportAll);
        LumasPdf.pdfOpenImportFileW(pdf, tf + "test_invoice.pdf", (int)LumasPdfConsts.ptOpen, "");

        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0);

        int ef = LumasPdf.pdfAttachFileW(pdf, tf + "factur-x.xml", "EN 16931 compliant invoice", false);
        LumasPdf.pdfAssociateEmbFile(pdf, TAFDestObject.adCatalog, -1, TAFRelationship.arAlternative, (uint)ef);

        // ZUGFeRD 2.1+ and FacturX are identically defined in PDF and share the same version constants.
        LumasPdf.pdfSetPDFVersion(pdf, LumasPdfConsts.pvFacturX_Comfort);

        // No fatal error occurred?
        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            // We write the file into the application directory.
            string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
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

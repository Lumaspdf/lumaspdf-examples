//  extract_invoice -- C# port of examples\Vb6\zugferd_facturx_xrechnung\extract_invoice\extract_invoice.bas
//  Creates FacturX and XRechnung invoices (attaching factur-x.xml from a memory
//  buffer via AttachFileEx) and then verifies the embedded e-invoice can be
//  found and extracted again.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class ExtractInvoice
{
    static string TF = System.IO.Path.Combine(System.AppContext.BaseDirectory, "..", "..", "..", "..", "test_files");

    // VCL TColor values used as case labels for console colouring.
    const int clRed = 0xFF;
    const int clGreen = 0x8000;
    const int clYellow = 0xFFFF;
    const int clWhite = 0xFFFFFF;

    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;                      // We try to continue if an error occurs
    }

    static TErrorProc _errCb = PDFError;

    static void SetColorConsole(int AColor)
    {
        switch (AColor)
        {
            case clRed: Console.ForegroundColor = ConsoleColor.Red; break;
            case clGreen: Console.ForegroundColor = ConsoleColor.Green; break;
            case clYellow: Console.ForegroundColor = ConsoleColor.Yellow; break;
            case clWhite: Console.ForegroundColor = ConsoleColor.White; break;
        }
    }

    static byte[] GetFileBuffer(string FileName)
    {
        try
        {
            byte[] b = File.ReadAllBytes(FileName);
            if (b.Length > 0) return b;
        }
        catch { }
        return null;
    }

    static bool HaveEInvoice(IntPtr pdf, string InFileName)
    {
        bool result = false;
        var info = new TPDFVersionInfo();
        info.StructSize = (uint)Marshal.SizeOf(typeof(TPDFVersionInfo));

        LumasPdf.pdfCreateNewPDFW(pdf, "");
        // We need the document info or metadata and embedded files only
        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifDocInfo | LumasPdfConsts.ifEmbeddedFiles);
        LumasPdf.pdfSetImportFlags2(pdf, LumasPdfConsts.if2UseProxy);

        if (LumasPdf.pdfOpenImportFileW(pdf, InFileName, (int)LumasPdfConsts.ptOpen, "") < 0) goto cleanup;

        // Other stuff can be ignored
        LumasPdf.pdfImportCatalogObjects(pdf);

        if (!LumasPdf.pdfGetPDFVersionEx(pdf, ref info)) goto cleanup;

        if ((info.PDFAVersion != 3) || (info.FXDocName == IntPtr.Zero)) goto cleanup;

        string docName = Marshal.PtrToStringAnsi(info.FXDocName);
        int ef = LumasPdf.pdfFindEmbeddedFileW(pdf, docName);
        if (ef < 0)
        {
            SetColorConsole(clRed);
            Console.WriteLine("Invoice " + docName + " not found!");
            goto cleanup;
        }
        if (ef != 0)
        {
            SetColorConsole(clYellow);
            Console.WriteLine("Warning: The invoice should be the first file attachment. This might cause unnecessary problems.");
        }
        var fs = new TPDFFileSpec();
        if (LumasPdf.pdfGetEmbeddedFile(pdf, (uint)ef, ref fs, true))
            result = (fs.BufSize > 0);
    cleanup:
        LumasPdf.pdfFreePDF(pdf);
        return result;
    }

    static bool CreateInvoice(IntPtr pdf, bool FacturX, string InvoiceName, string OutFile)
    {
        bool result = false;
        LumasPdf.pdfCreateNewPDFW(pdf, "");              // The output file is opened later
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diProducer, "");    // Keep the original producer

        if (LumasPdf.pdfOpenImportFileW(pdf, TF + "test_invoice.pdf", (int)LumasPdfConsts.ptOpen, "") < 0) goto done;

        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0);

        // We must be able to override the name: XRechnung requires xrechnung.xml. AttachFileEx() allows that.
        int ef;
        byte[] buffer = GetFileBuffer(TF + "factur-x.xml");
        if (buffer != null)
        {
            IntPtr p = Marshal.AllocHGlobal(buffer.Length);
            try
            {
                Marshal.Copy(buffer, 0, p, buffer.Length);
                ef = LumasPdf.pdfAttachFileExW(pdf, p, (uint)buffer.Length, InvoiceName, "EN 19631 compliant invoice", false);
            }
            finally { Marshal.FreeHGlobal(p); }
        }
        else
        {
            ef = LumasPdf.pdfAttachFileExW(pdf, IntPtr.Zero, 0, InvoiceName, "EN 19631 compliant invoice", false);
        }

        // ZUGFeRD 2.1+ and FacturX share the same version constants.
        if (FacturX)
        {
            LumasPdf.pdfSetPDFVersion(pdf, LumasPdfConsts.pvFacturX_Comfort);
            LumasPdf.pdfAssociateEmbFile(pdf, TAFDestObject.adCatalog, -1, TAFRelationship.arAlternative, (uint)ef);
        }
        else
        {
            LumasPdf.pdfSetPDFVersion(pdf, LumasPdfConsts.pvFacturX_XRechnung);
            LumasPdf.pdfAssociateEmbFile(pdf, TAFDestObject.adCatalog, -1, TAFRelationship.arSource, (uint)ef);
        }

        // No fatal error occurred?
        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            if (LumasPdf.pdfOpenOutputFileW(pdf, OutFile))
                result = LumasPdf.pdfCloseFile(pdf);
        }
    done:
        LumasPdf.pdfFreePDF(pdf);
        return result;
    }

    static void Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _errCb);

        // We write the test files into the application directory.
        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");

        // Test cases: FacturX and XRechnung (invoice name must be xrechnung.xml).
        if ((!CreateInvoice(pdf, true, "factur-x.xml", outFile)) || (!HaveEInvoice(pdf, outFile))
            || (!CreateInvoice(pdf, false, "xrechnung.xml", outFile)) || (!HaveEInvoice(pdf, outFile)))
        {
            SetColorConsole(clRed);
            Console.WriteLine("XML Invoice not found!");
        }
        else
        {
            SetColorConsole(clGreen);
            Console.WriteLine("All tests passed!");
        }

        LumasPdf.pdfDeletePDF(pdf);
    }
}

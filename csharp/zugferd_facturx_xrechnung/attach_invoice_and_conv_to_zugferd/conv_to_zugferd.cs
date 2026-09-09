//  conv_to_zugferd -- C# port of examples\Vb6\zugferd_facturx_xrechnung\
//    attach_invoice_and_conv_to_zugferd\conv_to_zugferd.bas
//  Converts a PDF to PDF/A-3 (FacturX Comfort), attaches the factur-x.xml
//  e-invoice and adds an output intent. Uses font-not-found and ICC-profile
//  replacement callbacks during conformance checking.
using System;
using System.IO;
using LumasPdfSdk;

class ConvToZugferd
{
    // coDefault_PDFA_3 is not exported as a const; its computed value.
    const uint coDefault_PDFA_3 = 0x50EF7F;

    static string TF = System.IO.Path.Combine(System.AppContext.BaseDirectory, "..", "..", "..", "..", "test_files");

    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;                      // We try to continue if an error occurs
    }

    // WeightFromStyle helper: (Style and $7FF00000) shr 20 (+$800 if sign bit set)
    static int WeightFromStyle(int Style)
    {
        uint u = (uint)Style;
        int w = (int)((u & 0x7FF00000u) >> 20);
        if ((u & 0x80000000u) != 0) w += 0x800;
        return w;
    }

    static int FontNotFoundProc(IntPtr Data, IntPtr PDFFont, string FontName, int Style, int StdFontIndex, bool IsSymbolFont)
    {
        int s = Style;
        if (WeightFromStyle(s) < 500) s = (s & 0xF) | LumasPdfConsts.fsRegular;
        return LumasPdf.pdfReplaceFontW(Data, PDFFont, "Arial", s, true);
    }

    static int ReplaceICCProfileProc(IntPtr Data, TICCProfileType ProfileType, int ColorSpace)
    {
        // The most important ICC profiles are available free of charge from Adobe.
        switch (ProfileType)
        {
            case TICCProfileType.ictRGB:
                return LumasPdf.pdfReplaceICCProfileW(Data, (uint)ColorSpace, TF + "sRGB.icc");
            case TICCProfileType.ictCMYK:
                return LumasPdf.pdfReplaceICCProfileW(Data, (uint)ColorSpace, TF + "ISOcoated_v2_bas.ICC");
            default:
                return LumasPdf.pdfReplaceICCProfileW(Data, (uint)ColorSpace, TF + "gray.icc");
        }
    }

    static TErrorProc _errCb = PDFError;
    static TOnFontNotFoundProc _fontCb = FontNotFoundProc;
    static TOnReplaceICCProfile _iccCb = ReplaceICCProfileProc;

    static bool ConvertFile(IntPtr pdf, int ConvType, string InFile, string Invoice, string OutFile)
    {
        LumasPdf.pdfCreateNewPDFW(pdf, "");              // The output file is opened later
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diProducer, "");    // Keep the original producer

        uint convFlags;
        switch (ConvType)
        {
            case (int)TConformanceType.ctFacturX_Comfort:
            case (int)TConformanceType.ctFacturX_Extended:
            case (int)TConformanceType.ctFacturX_XRechnung:
                convFlags = coDefault_PDFA_3;
                break;
            default:
                return false;           // We create e-invoices in this example and nothing else.
        }

        LumasPdf.pdfCreateNewPDFW(pdf, "");              // The output file will be created later
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diProducer, "");    // Keep the original producer

        // These flags require some processing time but they are very useful.
        convFlags = LumasPdfConsts.coCheckImages | LumasPdfConsts.coRepairDamagedImages;

        // ifPrepareForPDFA is required. ifImportAsPage keeps pages from becoming templates.
        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage | LumasPdfConsts.ifPrepareForPDFA);
        // if2UseProxy reduces the memory usage.
        LumasPdf.pdfSetImportFlags2(pdf, LumasPdfConsts.if2UseProxy);

        LumasPdf.pdfOpenImportFileW(pdf, InFile, (int)LumasPdfConsts.ptOpen, "");
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0);
        LumasPdf.pdfCloseImportFile(pdf);

        // The invoice should be the first attachment. If the name is not factur-x.xml use AttachFileEx().
        int ef = LumasPdf.pdfAttachFileW(pdf, Invoice, "EN 16931 compliant invoice", false);
        if (ConvType != (int)TConformanceType.ctFacturX_XRechnung)
            LumasPdf.pdfAssociateEmbFile(pdf, TAFDestObject.adCatalog, -1, TAFRelationship.arAlternative, (uint)ef);
        else
            LumasPdf.pdfAssociateEmbFile(pdf, TAFDestObject.adCatalog, -1, TAFRelationship.arSource, (uint)ef);

        // Note that this code requires the PDF/A Extension for the classic API.
        int retval = LumasPdf.pdfCheckConformance(pdf, ConvType, convFlags, pdf, _fontCb, _iccCb);
        switch (retval)
        {
            case 1: LumasPdf.pdfAddOutputIntentW(pdf, TF + "sRGB.icc"); break;
            case 2: LumasPdf.pdfAddOutputIntentW(pdf, TF + "ISOcoated_v2_bas.ICC"); break;
            case 3: LumasPdf.pdfAddOutputIntentW(pdf, TF + "gray.icc"); break;
        }

        // No fatal error occurred?
        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            // We write the file into the application directory.
            if (!LumasPdf.pdfOpenOutputFileW(pdf, OutFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return false;
            }
            return LumasPdf.pdfCloseFile(pdf);
        }
        return false;
    }

    static void Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _errCb);

        // Non embedded CID fonts usually depend on external cmaps.
        LumasPdf.pdfSetCMapDirW(pdf, System.IO.Path.Combine(System.AppContext.BaseDirectory, "..", "..", "..", "..", "test_files") + "\\CMap", LumasPdfConsts.lcmDelayed | LumasPdfConsts.lcmRecursive);

        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");

        // The profiles Minimum, Basic, and Basic WL are not EN 16931 compliant.
        if (ConvertFile(pdf, (int)TConformanceType.ctFacturX_Comfort, TF + "test_invoice.pdf", TF + "factur-x.xml", outFile))
            Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");

        LumasPdf.pdfDeletePDF(pdf);
    }
}

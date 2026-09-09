// checkconformance -- C# port of examples\Vb6\pdfa_extension\checkconformance\checkconformance.bas
// Imports a PDF and converts it to PDF/A-3b via CheckConformance, using callbacks
// to replace missing fonts and ICC profiles, then writes the result.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class CheckConformance
{
    static readonly string TestFiles = System.IO.Path.Combine(System.AppContext.BaseDirectory, "..", "..", "..", "..", "test_files");

    static TErrorProc _err = PDFError;
    static TOnFontNotFoundProc _fnf = FontNotFoundProc;
    static TOnReplaceICCProfile _icc = ReplaceICCProfileProc;

    static int PDFError(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return 0;
    }

    // Data is the PDF handle passed as UserData to CheckConformance.
    static int FontNotFoundProc(IntPtr data, IntPtr pdfFont, string fontName, int style, int stdFontIndex, bool isSymbolFont)
    {
        // Replace with Arial preserving Style.
        return LumasPdf.pdfReplaceFontW(data, pdfFont, "Arial", style, true);
    }

    static int ReplaceICCProfileProc(IntPtr data, TICCProfileType profileType, int colorSpace)
    {
        switch (profileType)
        {
            case TICCProfileType.ictRGB:  return LumasPdf.pdfReplaceICCProfileW(data, (uint)colorSpace, Path.Combine(TestFiles, "sRGB.icc"));
            case TICCProfileType.ictCMYK: return LumasPdf.pdfReplaceICCProfileW(data, (uint)colorSpace, Path.Combine(TestFiles, "ISOcoated_v2_bas.ICC"));
            default:                      return LumasPdf.pdfReplaceICCProfileW(data, (uint)colorSpace, Path.Combine(TestFiles, "gray.icc"));
        }
    }

    static bool ConvertFile(IntPtr pdf, TConformanceType convType, string inFile, string outFile)
    {
        LumasPdf.pdfCreateNewPDFW(pdf, "");             // The output file is opened later
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diProducer, "");

        uint convFlags;
        switch (convType)
        {
            case TConformanceType.ctNormalize:
                convFlags = LumasPdfConsts.coAllowDeviceSpaces;
                break;
            case TConformanceType.ctPDFA_1b_2005:
                convFlags = LumasPdfConsts.coDefault | LumasPdfConsts.coFlattenLayers;
                break;
            case TConformanceType.ctPDFA_2b:
            case TConformanceType.ctPDFA_2u:
                convFlags = LumasPdfConsts.coDefault | LumasPdfConsts.coDeletePresentation;
                break;
            default:
                // ctPDFA_3b, ctPDFA_4x, ZUGFeRD/FacturX: embedded files are allowed.
                convFlags = (LumasPdfConsts.coDefault | LumasPdfConsts.coDeletePresentation) & ~LumasPdfConsts.coDeleteEmbeddedFiles;
                break;
        }

        convFlags |= LumasPdfConsts.coCheckImages;
        convFlags |= LumasPdfConsts.coRepairDamagedImages;

        if (convType != TConformanceType.ctNormalize)
        {
            LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage | LumasPdfConsts.ifPrepareForPDFA);
            LumasPdf.pdfSetImportFlags2(pdf, LumasPdfConsts.if2UseProxy | LumasPdfConsts.if2DuplicateCheck);
        }
        else
        {
            LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);
            LumasPdf.pdfSetImportFlags2(pdf, LumasPdfConsts.if2UseProxy | LumasPdfConsts.if2DuplicateCheck | LumasPdfConsts.if2Normalize);
        }

        int retval = LumasPdf.pdfOpenImportFileW(pdf, inFile, (int)LumasPdfConsts.ptOpen, "");
        if (retval < 0)
        {
            Console.WriteLine("Could not open the import file (it may be encrypted)!");
            LumasPdf.pdfFreePDF(pdf);
            return false;
        }
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0);
        LumasPdf.pdfCloseImportFile(pdf);

        retval = LumasPdf.pdfCheckConformance(pdf, (int)convType, convFlags, pdf, _fnf, _icc);
        switch (retval)
        {
            case 1: LumasPdf.pdfAddOutputIntentW(pdf, Path.Combine(TestFiles, "sRGB.icc")); break;
            case 2: LumasPdf.pdfAddOutputIntentW(pdf, Path.Combine(TestFiles, "ISOcoated_v2_bas.ICC")); break;
            case 3: LumasPdf.pdfAddOutputIntentW(pdf, Path.Combine(TestFiles, "gray.icc")); break;
        }

        TPDFError e = new TPDFError();
        e.StructSize = (uint)Marshal.SizeOf(typeof(TPDFError));
        int count = LumasPdf.pdfGetErrLogMessageCount(pdf);
        for (int i = 0; i < count; i++)
        {
            LumasPdf.pdfGetErrLogMessage(pdf, (uint)i, ref e);
            Console.WriteLine(Marshal.PtrToStringAnsi(e.Msg));
        }

        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
                return false;
            return LumasPdf.pdfCloseFile(pdf);
        }
        return false;
    }

    static void Main()
    {
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfSetCMapDirW(pdf, Path.Combine(dir, "CMap"), LumasPdfConsts.lcmDelayed | LumasPdfConsts.lcmRecursive);

        string outFile = Path.Combine(dir, "out.pdf");
        string inFile = Path.Combine(dir, "dynapdf_help.pdf");
        if (ConvertFile(pdf, TConformanceType.ctPDFA_3b, inFile, outFile))
            Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");

        LumasPdf.pdfDeletePDF(pdf);
    }
}

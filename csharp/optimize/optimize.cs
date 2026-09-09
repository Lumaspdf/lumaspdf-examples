// optimize -- C# port of examples\Vb6\optimize\optimize.bas
// Imports a PDF, runs Optimize() over it and writes the result.
using System;
using System.IO;
using LumasPdfSdk;

class Optimize
{
    static TErrorProc _err = PDFError;

    static int PDFError(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return 0;                                   // return zero to continue
    }

    static bool DoOptimize(IntPtr pdf, string inFile, string outFile)
    {
        LumasPdf.pdfCreateNewPDFW(pdf, "");         // output file opened later
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diProducer, "");  // keep the original producer

        // ifImportAsPage avoids converting pages to templates; drop the piece info dictionary.
        LumasPdf.pdfSetImportFlags(pdf, (LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage) & ~LumasPdfConsts.ifPieceInfo);
        // if2UseProxy reduces memory usage; duplicate check + normalize recommended.
        LumasPdf.pdfSetImportFlags2(pdf, LumasPdfConsts.if2UseProxy | LumasPdfConsts.if2DuplicateCheck | LumasPdfConsts.if2Normalize | LumasPdfConsts.if2NoResNameCheck);
        int retval = LumasPdf.pdfOpenImportFileW(pdf, inFile, (int)LumasPdfConsts.ptOpen, "");
        if (retval < 0)
        {
            LumasPdf.pdfFreePDF(pdf);
            return false;
        }
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0);
        LumasPdf.pdfCloseImportFile(pdf);

        LumasPdf.pdfOptimize(pdf, LumasPdfConsts.ofInMemory | LumasPdfConsts.ofNewLinkNames | LumasPdfConsts.ofDeleteInvPaths, IntPtr.Zero);

        TPDFError e = new TPDFError();
        e.StructSize = (uint)System.Runtime.InteropServices.Marshal.SizeOf(typeof(TPDFError));
        int count = LumasPdf.pdfGetErrLogMessageCount(pdf);
        for (int i = 0; i < count; i++)
        {
            LumasPdf.pdfGetErrLogMessage(pdf, (uint)i, ref e);
            Console.WriteLine(System.Runtime.InteropServices.Marshal.PtrToStringAnsi(e.Msg));
        }

        if (LumasPdf.pdfHaveOpenDoc(pdf))           // No fatal error occurred?
        {
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfFreePDF(pdf);
                return false;
            }
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
        string inFile = Path.Combine(dir, "sample_multipage.pdf");
        if (DoOptimize(pdf, inFile, outFile))
            Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
        LumasPdf.pdfDeletePDF(pdf);
    }
}

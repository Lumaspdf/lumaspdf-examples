// ============================================================================
//  multiple_signatures -- C# port of
//  examples\Vb6\incremental_updates\multiple_signatures\multiple_signatures.bas
//  Signs a PDF four times (two visible + two invisible) using incremental updates
//  so each new signature does not invalidate the previous ones. When signing a
//  file in place, a temp file is used and moved over the input.
// ============================================================================
using System;
using System.IO;
using LumasPdfSdk;

class MultipleSignatures
{
    static TErrorProc _err = PDFError;
    static string _certFile;

    static int PDFError(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return 0;
    }

    static bool SignFile(IntPtr pdf, string inFileName, string outFileName, string fieldName,
                         string reason, double posX, bool visibleSignature)
    {
        string outName = outFileName;
        bool usedTemp = false;
        if (inFileName == outFileName)
        {
            outName = Path.GetTempFileName();
            usedTemp = true;
        }

        LumasPdf.pdfCreateNewPDFW(pdf, outName);

        // A demo version would add a demo string to each edited page, invalidating
        // previous signatures. This special key avoids that.
        LumasPdf.pdfSetLicenseKey(pdf, "SigDemo");

        // if2IncrementalUpd also sets ifImportAsPage|ifImportAll and if2UseProxy|if2CopyEncryptDict.
        LumasPdf.pdfSetImportFlags2(pdf, LumasPdfConsts.if2IncrementalUpd);
        if (LumasPdf.pdfOpenImportFileW(pdf, inFileName, (int)LumasPdfConsts.ptOpen, "") < 0) return false;
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0);

        if (visibleSignature)
        {
            LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);
            LumasPdf.pdfEditPage(pdf, 1);
            int sig = LumasPdf.pdfCreateSigField(pdf, fieldName, -1, posX, 30.0, 180.0, 40.0);
            LumasPdf.pdfSetFieldBorderWidth(pdf, (uint)sig, 0.0);
            LumasPdf.pdfEndPage(pdf);
        }

        bool ok = LumasPdf.pdfCloseAndSignFile(pdf, _certFile, "123456", reason, "");
        if (ok && usedTemp)
        {
            if (File.Exists(outFileName)) File.Delete(outFileName);
            try { File.Move(outName, outFileName); }
            catch { return false; }
        }
        return ok;
    }

    static void Main()
    {
        string exeDir = AppDomain.CurrentDomain.BaseDirectory;
        _certFile = Path.Combine(exeDir, "test_cert.pfx");
        string inputFile = Path.Combine(exeDir, "license.pdf");

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);

        string filePath = Path.Combine(exeDir, "out.pdf");

        // Sign the file 4 times: two visible and two invisible signatures.
        if (SignFile(pdf, inputFile, filePath, "Signature1", "Test signature 1", 50.0, true))
            if (SignFile(pdf, filePath, filePath, "Signature2", "Test signature 2", 430.0, true))
                if (SignFile(pdf, filePath, filePath, "", "Test signature 3", 0.0, false))
                    if (SignFile(pdf, filePath, filePath, "", "Test signature 4", 0.0, false))
                        Console.WriteLine("PDF file \"" + filePath + "\" successfully created!");

        LumasPdf.pdfDeletePDF(pdf);
    }
}

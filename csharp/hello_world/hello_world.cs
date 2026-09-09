// ============================================================================
//  hello_world -- C# port of examples\Vb6\hello_world\hello_world.bas
//  Writes out.pdf with a single centered line of italic text plus a timestamp.
// ============================================================================
using System;
using System.IO;
using LumasPdfSdk;

class HelloWorld
{
    // Keep the delegate alive so the GC cannot collect it while the DLL holds it.
    static TErrorProc _err = ErrProc;

    static int ErrProc(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return -1;                       // break processing if an error occurs
    }

    static void Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        if (!LumasPdf.pdfCreateNewPDFW(pdf, ""))     // output file opened later
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diCreator, "Delphi Example project");
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diTitle, "My first PDF output");

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsItalic, 30.0, true, TCodepage.cp1252);
        LumasPdf.pdfWriteFTextW(pdf, LumasPdfConsts.taCenter,
            "My first PDF output..." + "\r" + "\r" + DateTime.Now.ToString());
        LumasPdf.pdfEndPage(pdf);

        string outFile = "";
        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, null);
            outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
            LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        }
        if (LumasPdf.pdfCloseFile(pdf))
            Console.WriteLine("OK: " + outFile);

        LumasPdf.pdfDeletePDF(pdf);
    }
}

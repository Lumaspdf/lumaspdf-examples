//  migration_states -- C# port of examples\Vb6\annotations\migration_states\migration_states.bas
//  A square annotation whose review state is set to Completed then Accepted.
using System;
using System.IO;
using LumasPdfSdk;

class MigrationStates
{
    const uint NO_COLOR = 0xFFFFFFF1;   // transparent

    static readonly TErrorProc _err = PDFError;
    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType) { return 0; }

    static void Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();

        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfAppend(pdf);
        int annot = LumasPdf.pdfSquareAnnotW(pdf, 50, 50, 200, 100, 3, NO_COLOR, 255, TPDFColorSpace.csDeviceRGB, "Jim", "Test", "Just test...");
        int reply = LumasPdf.pdfSetAnnotMigrationStateW(pdf, (uint)annot, TAnnotState.asCompleted, "Harry");
        LumasPdf.pdfSetAnnotStringW(pdf, (uint)reply, (int)TAnnotString.asContent, "The state was set to Completed!");

        reply = LumasPdf.pdfSetAnnotMigrationStateW(pdf, (uint)reply, TAnnotState.asAccepted, "Jim");
        LumasPdf.pdfSetAnnotStringW(pdf, (uint)reply, (int)TAnnotString.asContent, "The state was set to Accepted!");
        LumasPdf.pdfEndPage(pdf);

        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile)) { LumasPdf.pdfDeletePDF(pdf); return; }
            if (LumasPdf.pdfCloseFile(pdf))
                Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
        }

        LumasPdf.pdfDeletePDF(pdf);
    }
}

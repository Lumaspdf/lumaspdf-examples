//  annotation_replies -- C# port of examples\Vb6\annotations\annotation_replies\annotation_replies.bas
//  A square annotation with a reply, and a reply to that reply.
using System;
using System.IO;
using LumasPdfSdk;

class AnnotationReplies
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
        int reply = LumasPdf.pdfSetAnnotMigrationStateW(pdf, (uint)annot, TAnnotState.asCreateReply, "Harry");
        LumasPdf.pdfSetAnnotStringW(pdf, (uint)reply, (int)TAnnotString.asContent, "This is a reply!");

        reply = LumasPdf.pdfSetAnnotMigrationStateW(pdf, (uint)reply, TAnnotState.asCreateReply, "Jim");
        LumasPdf.pdfSetAnnotStringW(pdf, (uint)reply, (int)TAnnotString.asContent, "This is a reply to a reply!");
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

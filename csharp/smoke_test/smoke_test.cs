//  smoke_test -- C# port of examples\Vb6\smoke_test\smoke_test.bas
//  End-to-end proof the flat LumasPdf .NET binding drives the engine:
//  creates a PDF with text, a red rectangle and a bookmark.
using System;
using System.IO;
using LumasPdfSdk;

class SmokeTest
{
    static void Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();
        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "smoke_out.pdf");

        if (!LumasPdf.pdfCreateNewPDFW(pdf, outFile))
        {
            Console.WriteLine("CreateNewPDF failed");
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diTitle, "LumasPdf example-mirror smoke test");
        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsRegular, 24.0, true, TCodepage.cp1252);
        LumasPdf.pdfWriteTextW(pdf, 50, 700, "Examples run on LumasPdf.dll");
        LumasPdf.pdfSetFillColor(pdf, 255);                 // red (COLORREF, R in low byte)
        LumasPdf.pdfRectangle(pdf, 50, 500, 200, 100, (int)TPathFillMode.fmFill);
        LumasPdf.pdfAddBookmarkW(pdf, "First page", -1, 1, 0);
        LumasPdf.pdfEndPage(pdf);

        if (!LumasPdf.pdfCloseFile(pdf))
        {
            Console.WriteLine("CloseFile failed");
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        Console.WriteLine("OK: " + outFile);
        LumasPdf.pdfDeletePDF(pdf);
    }
}

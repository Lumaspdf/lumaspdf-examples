// ============================================================================
//  edit_page -- C# port of examples\Vb6\edit_page\edit_page.bas
//  Imports a rotated page, opens it for editing and writes a formatted text
//  block onto it.
// ============================================================================
using System;
using System.IO;
using LumasPdfSdk;

class EditPage
{
    static TErrorProc _err = PDFError;

    static int PDFError(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return 0;                        // try to continue on error
    }

    static void Main()
    {
        string exeDir = AppDomain.CurrentDomain.BaseDirectory;

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");          // output file opened later

        // Import anything and don't convert pages to templates
        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);

        string inFile = Path.Combine(exeDir, "rotated_270.pdf");
        if (LumasPdf.pdfOpenImportFileW(pdf, inFile, (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0);
        LumasPdf.pdfCloseImportFile(pdf);

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);
        // Move the coordinate origin into the visible area.
        LumasPdf.pdfSetUseVisibleCoords(pdf, true);

        LumasPdf.pdfEditPage(pdf, 1);
        int orientation = LumasPdf.pdfGetOrientation(pdf);
        if (orientation != 0)
            LumasPdf.pdfSetOrientationEx(pdf, orientation);
        LumasPdf.pdfSetLeading(pdf, 14.0);
        int f = LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 12.0, false, TCodepage.cp1252);
        LumasPdf.pdfSetListFont(pdf, (uint)f);

        // We call the Unicode (W) export, so the bullet must be the Unicode
        // bullet U+2022 -- not code page 1252 char 144 (which is U+0090 in Unicode).
        string b = "\u2022";
        string cr = "\r";
        string s = "It is not difficult to edit an imported page but two things must be considered:" + cr + cr + "\\LI[20," + b + "]\\LD[16]The page's "
          + "orientation.\\EL#\\LI[20," + b + "]\\LD[12]The coordinate origin. The coordinate origin can be taken from the crop box if present, or from the media box (Left and Bottom).\\EL#" + cr + "\\LD[12]"
          + "Although it is possible to correct the coordinate origin manually, it is much easier to set the property SetUseVisibleCoords() to true. DynaPDF moves the zero point then automatically "
          + "into the visible area of the page." + cr + cr
          + "The functions GetPageWidth() and GetPageHeight() return then also the logical width or height of the page depending on the orientation and whether a crop box is present." + cr + cr
          + "The handling of rotated pages is a bit more complicated since the orientation is just a property. That means there is no guarantee that the contents is rotated "
          + "into the opposite direction like the contents in this page. Whether this is the case depends on the creator of the PDF file." + cr + cr
          + "However, by default it is probably best to assume that the contents is rotated. SetOrientationEx() rotates the coordinate system so that we can work with the page as if it was "
          + "not rotated. If this produces a wrong result then don't call SetOrientationEx()." + cr + cr
          + "Now you ask probably yourself whether it is possible to identify the orientation of the contents in a page. The answer is maybe. It is possible to parse a page with ParseContent() "
          + "and to inspect the transformation matrices but this can produce wrong results especially if a page contains not much contents.";

        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 200.0, LumasPdf.pdfGetPageWidth(pdf) - 100.0, -1.0, (int)LumasPdfConsts.taJustify, s);
        LumasPdf.pdfEndPage(pdf);

        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            string outFile = Path.Combine(exeDir, "out.pdf");
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

//  render_page -- C# port of examples\Vb6\rendering_engine\render_page\render_page.bas
//  Loads a PDF, imports the first page and renders it to a TIFF image file.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class RenderPage
{
    [DllImport("user32.dll")] static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("user32.dll")] static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);
    [DllImport("gdi32.dll")] static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
    const int HORZRES = 8;

    // Error callback. We try to continue if an error occurs.
    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;
    }
    static TErrorProc _errCb = PDFError;

    static void Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _errCb);
        LumasPdf.pdfCreateNewPDFW(pdf, "");   // We create no PDF file in this example

        string baseDir = AppDomain.CurrentDomain.BaseDirectory;
        LumasPdf.pdfSetCMapDirW(pdf, Path.Combine(baseDir, "..\\..\\..\\Resource\\CMap\\"),
            LumasPdfConsts.lcmRecursive | LumasPdfConsts.lcmDelayed);

        if (LumasPdf.pdfOpenImportFileW(pdf, "../../../../sample_multipage.pdf", (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        // Import pages manually: only the output intent is needed for color management, then reset.
        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifContentOnly);
        LumasPdf.pdfImportCatalogObjects(pdf);
        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);
        LumasPdf.pdfSetImportFlags2(pdf, LumasPdfConsts.if2UseProxy);

        int pageCount = LumasPdf.pdfGetInPageCount(pdf);
        if (pageCount < 1)
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        // We render only the first page in this example.
        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfImportPageEx(pdf, 1, 1.0, 1.0);
        LumasPdf.pdfEndPage(pdf);

        // Confirm the page object exists (as the GUI viewer does before rendering).
        if (LumasPdf.pdfGetPageObject(pdf, 1) == IntPtr.Zero)
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        IntPtr dc = GetDC(IntPtr.Zero);
        int w = GetDeviceCaps(dc, HORZRES);
        ReleaseDC(IntPtr.Zero, dc);

        string outFile = Path.Combine(baseDir, "render_page.tif");
        if (LumasPdf.pdfRenderPageToImageW(pdf, 1, outFile, 0, w, 0, LumasPdfConsts.rfDefault,
                TPDFPixFormat.pxfRGB, LumasPdfConsts.cfLZW, TImageFormat.ifmTIFF))
        {
            Console.WriteLine("Rendered page 1 to " + outFile);
        }

        LumasPdf.pdfDeletePDF(pdf);
    }
}

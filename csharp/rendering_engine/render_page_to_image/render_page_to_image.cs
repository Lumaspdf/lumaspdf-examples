//  render_page_to_image -- C# port of
//  examples\Vb6\rendering_engine\render_page_to_image\render_page_to_image.bas
//  Loads a PDF, imports the first page and renders it to a TIFF image file.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class RenderPageToImage
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

        // Import anything and don't convert pages to templates
        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);
        if (LumasPdf.pdfOpenImportFileW(pdf, "../../../../sample_multipage.pdf", (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        // We render only the first page in this example.
        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfImportPageEx(pdf, 1, 1.0, 1.0);
        LumasPdf.pdfEndPage(pdf);

        IntPtr dc = GetDC(IntPtr.Zero);
        int w = GetDeviceCaps(dc, HORZRES);
        ReleaseDC(IntPtr.Zero, dc);

        string filePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.tif");
        if (LumasPdf.pdfRenderPageToImageW(pdf, 1, filePath, 0, w, 0, LumasPdfConsts.rfDefault,
                TPDFPixFormat.pxfRGB, LumasPdfConsts.cfLZW, TImageFormat.ifmTIFF))
        {
            Console.WriteLine("TIFF image \"" + filePath + "\" successfully created!");
        }

        LumasPdf.pdfDeletePDF(pdf);
    }
}

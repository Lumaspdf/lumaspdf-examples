//  image_extraction -- C# port of
//  examples\Vb6\content_parser\image_extraction\image_extraction.bas
//  Imports dynapdf_help.pdf and extracts every image into a multi-page TIFF by
//  parsing each page's content stream.
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class ImageExtraction
{
    // Native callback delegate types (see TPDFParseInterface in LumasPdf.pas).
    delegate int BeginTemplateDel(IntPtr Data, IntPtr PDFObject, int Handle, ref TPDFRect BBox, IntPtr Matrix);
    delegate int InsertImageDel(IntPtr Data, ref TPDFImage Image);

    // Keep delegates alive for the whole run.
    static BeginTemplateDel _beginTemplate = BeginTemplate;
    static InsertImageDel _insertImage = InsertImage;
    static TErrorProc _err = ErrProc;

    static HashSet<IntPtr> m_Images = new HashSet<IntPtr>();
    static HashSet<int> m_Templates = new HashSet<int>();

    static int ErrProc(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;
    }

    static int BeginTemplate(IntPtr Data, IntPtr PDFObject, int Handle, ref TPDFRect BBox, IntPtr Matrix)
    {
        if (m_Templates.Contains(Handle)) return 1;   // Skip the template
        m_Templates.Add(Handle);
        return 0;
    }

    static int InsertImage(IntPtr Data, ref TPDFImage Image)
    {
        if (!Image.InlineImage)
        {
            if (m_Images.Contains(Image.ObjectPtr)) return 0;   // Already handled?
            m_Images.Add(Image.ObjectPtr);
        }
        // If an image cannot be decompressed we can get a compressed image here.
        if (Image.Filter != TDecodeFilter.dfNone) return 0;
        // Note that Flate compression is no standard filter.
        if (Image.BitsPerPixel == 1)
            LumasPdf.pdfAddImage(Data, LumasPdfConsts.cfCCITT4, LumasPdfConsts.icNone, ref Image);
        else
            LumasPdf.pdfAddImage(Data, LumasPdfConsts.cfLZW, LumasPdfConsts.icNone, ref Image);
        return 0;
    }

    static void Main()
    {
        TPDFParseInterface stack = new TPDFParseInterface();
        stack.BeginTemplate = Marshal.GetFunctionPointerForDelegate(_beginTemplate);
        stack.InsertImage = Marshal.GetFunctionPointerForDelegate(_insertImage);

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");

        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);
        string inFile = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,
            "../../../../dynapdf_help.pdf"));
        if (LumasPdf.pdfOpenImportFileW(pdf, inFile, (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            Console.WriteLine("Input file \"dynapdf_help.pdf\" not found!");
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }
        if (LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0)
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }
        // Flatten form fields so we can extract images of these objects too.
        LumasPdf.pdfFlattenForm(pdf);

        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.tif");
        if (!LumasPdf.pdfCreateImageW(pdf, outFile, TImageFormat.ifmTIFF))
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }
        int pageCount = LumasPdf.pdfGetPageCount(pdf);
        for (int i = 1; i <= pageCount; i++)
        {
            LumasPdf.pdfEditPage(pdf, i);
            // The pdf handle is passed as the parser Data pointer.
            LumasPdf.pdfParseContent(pdf, pdf, ref stack, (int)LumasPdfConsts.pfDecomprAllImages);
            LumasPdf.pdfEndPage(pdf);
        }
        if (LumasPdf.pdfCloseImage(pdf))
            Console.WriteLine("TIFF image \"" + outFile + "\" successfully created!");

        GC.KeepAlive(_beginTemplate);
        GC.KeepAlive(_insertImage);
        LumasPdf.pdfDeletePDF(pdf);
    }
}

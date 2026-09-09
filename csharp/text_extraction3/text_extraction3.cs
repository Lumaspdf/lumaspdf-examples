//  text_extraction3 -- C# port of examples\Vb6\text_extraction3\text_extraction3.bas
//  Imports a PDF and extracts its text page by page with pdfExtractText, then
//  writes the result to out.txt as UTF-16LE (with BOM).
using System;
using System.IO;
using System.Text;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class TextExtraction3
{
    static TErrorProc _errCb = PDFError;

    // Error callback function. The rendering engine calls this on every error/warning.
    public static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;                       // We try to continue if an error occurs
    }

    static void WritePageIdentifier(FileStream f, int pageNum)
    {
        if (pageNum > 1)
        {
            byte[] nl = Encoding.Unicode.GetBytes("\r\n");
            f.Write(nl, 0, nl.Length);
        }
        byte[] b = Encoding.Unicode.GetBytes("%----------------------- Page " + pageNum + " -----------------------------\r\n");
        f.Write(b, 0, b.Length);
    }

    static void WriteWCharsFromPtr(FileStream f, IntPtr ptr, int wcharCount)
    {
        if (ptr == IntPtr.Zero || wcharCount <= 0) return;
        byte[] b = new byte[wcharCount * 2];
        Marshal.Copy(ptr, b, 0, wcharCount * 2);
        // Write exactly the wchar count the engine reported; deliberately do NOT
        // stop at a NUL. Until 2026-08-02 pdfExtractText could hand back a buffer
        // with U+0000 embedded (a simple font's character code 0 decoded straight
        // through CP1252), and the Delphi vendor wrapper's
        // "Text := WideString(txt)" truncated the caller's text there -- this
        // example lost every page after the first such glyph. The cause was fixed
        // in the engine (Lumas.Pdf.Document.DecodeGIDString), so honouring the
        // reported length is now both correct and byte-identical to the
        // reference. Truncating here too would re-hide the bug if it returned.
        f.Write(b, 0, wcharCount * 2);
    }

    static void Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _errCb);
        LumasPdf.pdfCreateNewPDFW(pdf, "");            // We do not create a PDF file in this example

        // External cmaps should always be loaded when extracting text from PDF files.
        string cmapDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "CMap");
        LumasPdf.pdfSetCMapDirW(pdf, cmapDir, LumasPdfConsts.lcmRecursive | LumasPdfConsts.lcmDelayed);

        // Import anything and don't convert pages to templates
        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);

        // Original used a fixed input ..\..\..\dynapdf_help.pdf
        string inFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "in.pdf");
        if (!File.Exists(inFile)) inFile = System.IO.Path.Combine(System.AppContext.BaseDirectory, "..", "..", "..", "..", "test_files") + "\\dynapdf_help.pdf";
        if (LumasPdf.pdfOpenImportFileW(pdf, inFile, (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0);
        LumasPdf.pdfCloseImportFile(pdf);

        // Flatten markup annotations and form fields so their text can be extracted too.
        LumasPdf.pdfFlattenAnnots(pdf, LumasPdfConsts.affMarkupAnnots);
        LumasPdf.pdfFlattenForm(pdf);

        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.txt");
        FileStream f = new FileStream(outFile, FileMode.Create, FileAccess.Write);
        f.Write(new byte[] { 0xFF, 0xFE }, 0, 2);      // UTF-16LE BOM

        int cnt = LumasPdf.pdfGetPageCount(pdf);
        for (int i = 1; i <= cnt; i++)
        {
            WritePageIdentifier(f, i);
            IntPtr textPtr = IntPtr.Zero;
            uint textLen = 0;
            // It is not recommended to sort text on the y-axis since it sometimes causes strange results.
            if (LumasPdf.pdfExtractText(pdf, (uint)i, LumasPdfConsts.tefDeleteOverlappingText | LumasPdfConsts.tefSortTextX, IntPtr.Zero, ref textPtr, ref textLen))
            {
                if (textLen > 0) WriteWCharsFromPtr(f, textPtr, (int)textLen);
            }
        }
        f.Close();

        Console.WriteLine("Text successfully extracted to " + outFile);
        LumasPdf.pdfDeletePDF(pdf);
    }
}

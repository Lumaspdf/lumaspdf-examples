//  alternate_fonts -- C# port of
//  examples\Vb6\complex_text\alternate_font_lists\alternate_fonts.bas
//  Complex text layout with an alternate font list to improve font substitution.
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using LumasPdfSdk;

class AlternateFonts
{
    static TErrorProc _err = ErrProc;
    static int ErrProc(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;
    }

    static string GetFileBuffer(string fileName)
    {
        try { return Encoding.Unicode.GetString(File.ReadAllBytes(fileName)); }
        catch { return ""; }
    }

    static void Main()
    {
        string[] fonts = {
            "Malgun Gothic",   // Korean
            "Mangal",          // Hindi or Marathi
            "Nyala",           // Amharic
            "Shonar Bangla",   // Bengali
            "Shruti"           // Gujarati
        };

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");

        string txt = GetFileBuffer(Path.GetFullPath(Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory, "../../../test_files/multi_lang.txt")));

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);
        LumasPdf.pdfSetGStateFlags(pdf, LumasPdfConsts.gfComplexText, false);

        // Provide an alternate font list (array of PWideChar).
        int altFonts = LumasPdf.pdfCreateAltFontList(pdf);
        IntPtr[] ptrs = new IntPtr[fonts.Length];
        for (int i = 0; i < fonts.Length; i++)
            ptrs[i] = Marshal.StringToHGlobalUni(fonts[i]);

        GCHandle h = GCHandle.Alloc(ptrs, GCHandleType.Pinned);
        LumasPdf.pdfSetAltFontsW(pdf, (uint)altFonts, h.AddrOfPinnedObject(), (uint)fonts.Length);
        h.Free();

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfSetFontW(pdf, "Arial", LumasPdfConsts.fsRegular, 10.0, true, TCodepage.cpUnicode);
        LumasPdf.pdfActivateAltFontList(pdf, altFonts, true);

        LumasPdf.pdfSetLeading(pdf, LumasPdf.pdfGetTypoLeading(pdf));
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 50.0,
            LumasPdf.pdfGetPageWidth(pdf) - 100.0, LumasPdf.pdfGetPageHeight(pdf) - 100.0,
            (int)LumasPdfConsts.taJustify, txt);
        LumasPdf.pdfEndPage(pdf);

        foreach (IntPtr p in ptrs) Marshal.FreeHGlobal(p);

        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
        }
        if (LumasPdf.pdfCloseFile(pdf))
            Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
        LumasPdf.pdfDeletePDF(pdf);
    }
}

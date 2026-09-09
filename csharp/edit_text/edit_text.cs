// ============================================================================
//  edit_text -- C# port of examples\Vb6\edit_text\edit_text.bas
//  Imports a PDF, then uses the content parser to find and replace every
//  occurrence of a search string on each page.
// ============================================================================
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class EditText
{
    static TErrorProc _err = ErrProc;

    static int ErrProc(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return 0;                        // try to continue on error
    }

    static void Main()
    {
        string exeDir = AppDomain.CurrentDomain.BaseDirectory;

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfCreateNewPDFW(pdf, "");            // output file opened later
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        // Avoid the conversion of pages to templates
        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);

        string inFile = Path.Combine(exeDir, "sample_multipage.pdf");
        if (LumasPdf.pdfOpenImportFileW(pdf, inFile, (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0);
        LumasPdf.pdfCloseImportFile(pdf);

        IntPtr ctx = LumasPdf.psrCreateParserContext(pdf, LumasPdfConsts.ofDefault, IntPtr.Zero);
        string searchText = "PDF";                     // occurs very often in the help file
        string replaceText = "XDF";                    // just an example

        IntPtr selPtr = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(TTextSelection)));
        try
        {
            for (int i = 1; i <= LumasPdf.pdfGetPageCount(pdf); i++)
            {
                TContent content = new TContent();
                // The flag cpfEnableTextSelection is required, otherwise no text can be found.
                if (LumasPdf.psrParsePage(pdf, ctx, IntPtr.Zero, IntPtr.Zero, (uint)i,
                        LumasPdfConsts.cpfEnableTextSelection, IntPtr.Zero, ref content))
                {
                    IntPtr curr = IntPtr.Zero;
                    TTextSelection sel = new TTextSelection();
                    while (LumasPdf.psrFindText(pdf, ctx, IntPtr.Zero, (uint)LumasPdfConsts.stDefault, curr,
                                searchText, (uint)searchText.Length, ref sel))
                    {
                        LumasPdf.psrReplaceSelText(pdf, ctx, TReplaceTextFlags.rtfDefault, ref sel,
                            replaceText, (uint)replaceText.Length);
                        Marshal.StructureToPtr(sel, selPtr, false);
                        curr = selPtr;
                    }
                    LumasPdf.psrWriteToPage(pdf, ctx, LumasPdfConsts.ofDefault, IntPtr.Zero);
                }
            }
        }
        finally
        {
            Marshal.FreeHGlobal(selPtr);
        }
        LumasPdf.psrDeleteParserContext(ref ctx);

        string outFile = Path.Combine(exeDir, "out.pdf");
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

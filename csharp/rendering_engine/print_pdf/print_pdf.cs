// print_pdf -- C# port of examples\Vb6\rendering_engine\print_pdf\print_pdf.bas
// Loads a PDF, imports the first page and prints it. A printer is chosen through
// the standard Print dialog (PrintDlg). COMPILE-ONLY: opens a UI print dialog,
// so it is built but not run in automated smoke testing.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class PrintPdf
{
    static TErrorProc _err = PDFError;

    [StructLayout(LayoutKind.Sequential)]
    struct PRINTDLG
    {
        public int lStructSize;
        public IntPtr hwndOwner;
        public IntPtr hDevMode;
        public IntPtr hDevNames;
        public IntPtr hDC;
        public int Flags;
        public short nFromPage;
        public short nToPage;
        public short nMinPage;
        public short nMaxPage;
        public short nCopies;
        public IntPtr hInstance;
        public IntPtr lCustData;
        public IntPtr lpfnPrintHook;
        public IntPtr lpfnSetupHook;
        public IntPtr lpPrintTemplateName;
        public IntPtr lpSetupTemplateName;
        public IntPtr hPrintTemplate;
        public IntPtr hSetupTemplate;
    }

    [DllImport("comdlg32.dll", EntryPoint = "PrintDlgA")]
    static extern int PrintDlg(ref PRINTDLG pPD);
    [DllImport("gdi32.dll")]
    static extern int DeleteDC(IntPtr hDC);

    const int PD_RETURNDC = 0x100;
    const int PD_HIDEPRINTTOFILE = 0x100000;
    const int PD_DISABLEPRINTTOFILE = 0x80000;
    const int PD_NOSELECTION = 0x4;

    static int PDFError(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return 0;
    }

    static IntPtr GetPrinterDC()
    {
        PRINTDLG pd = new PRINTDLG();
        pd.lStructSize = Marshal.SizeOf(typeof(PRINTDLG));
        pd.Flags = PD_RETURNDC | PD_HIDEPRINTTOFILE | PD_DISABLEPRINTTOFILE | PD_NOSELECTION;
        if (PrintDlg(ref pd) != 0)
            return pd.hDC;
        Console.WriteLine("Cancelled!");
        return IntPtr.Zero;
    }

    static void Main()
    {
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");    // We create no PDF file in this example

        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);
        if (LumasPdf.pdfOpenImportFileW(pdf, Path.Combine(dir, "sample_multipage.pdf"), (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfImportPageEx(pdf, 1, 1.0, 1.0);
        LumasPdf.pdfEndPage(pdf);

        // Make sure the same result is printed that Acrobat would print (layers, etc.).
        LumasPdf.pdfApplyAppEvent(pdf, LumasPdfConsts.aePrint, false);

        IntPtr dc = GetPrinterDC();
        if (dc != IntPtr.Zero)
        {
            uint flags = LumasPdfConsts.pffDefault | LumasPdfConsts.pffAutoRotateAndCenter | LumasPdfConsts.pffShrinkToPrintArea;
            if (LumasPdf.pdfPrintPDFFileW(pdf, "", "Test Print", new UIntPtr((ulong)dc.ToInt64()), flags, IntPtr.Zero, IntPtr.Zero))
                Console.WriteLine("Page 1 successfully printed");
            DeleteDC(dc);
        }

        LumasPdf.pdfDeletePDF(pdf);
    }
}

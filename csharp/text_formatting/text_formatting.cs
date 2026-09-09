//  text_formatting -- C# port of examples\Vb6\text_formatting\text_formatting.bas
//  Lays out sample.txt into N columns using a page-break callback and writes
//  out.pdf. The combo box that selected the number of columns is replaced by a
//  constant (the form's default selection was 3 columns).
using System;
using System.IO;
using System.Text;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class TextFormatting
{
    // Holds the formatting options.
    struct TOutRect
    {
        public double PosX;      // Original x-coordinate of first output rectangle
        public double PosY;      // Original y-coordinate of first output rectangle
        public double Width_;    // Original width of first output rectangle
        public double Height_;   // Original height of first output rectangle
        public double Distance;  // Space between columns
        public int Column;       // Current column
        public int ColCount;     // Number of columns
    }

    static TOutRect gRect;
    static IntPtr gPDF;

    static TErrorProc _errCb = ErrProc;
    static TOnPageBreakProc _breakCb = OnPageBreakProc;

    public static int ErrProc(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return -1;                       // we break processing if an error occurred.
    }

    // Page-break callback. Places the next column or starts a new page.
    public static int OnPageBreakProc(IntPtr Data, double LastPosX, double LastPosY, bool PageBreak)
    {
        LumasPdf.pdfSetPageCoords(gPDF, (int)TPageCoord.pcTopDown);   // we use top down coordinates
        gRect.Column = gRect.Column + 1;
        // PageBreak is nonzero if the string contains a page break tag.
        if ((!PageBreak) && (gRect.Column < gRect.ColCount))
        {
            // Calculate the x-coordinate of the column
            double x = gRect.PosX + gRect.Column * (gRect.Width_ + gRect.Distance);
            // change the output rectangle, do not close the page!
            LumasPdf.pdfSetTextRect(gPDF, x, gRect.PosY, gRect.Width_, gRect.Height_);
            return 0;            // we do not change the alignment
        }
        else
        {
            // the page is full, close the current one and append a new page
            LumasPdf.pdfEndPage(gPDF);
            LumasPdf.pdfAppend(gPDF);
            LumasPdf.pdfSetTextRect(gPDF, gRect.PosX, gRect.PosY, gRect.Width_, gRect.Height_);
            gRect.Column = 0;
            return 0;
        }
    }

    static string LoadTextFile(string fileName)
    {
        if (!File.Exists(fileName)) return "";
        byte[] b = File.ReadAllBytes(fileName);
        return Encoding.Default.GetString(b);   // sample.txt is an ANSI text file
    }

    static void Main()
    {
        // The text is stored in a file. Original: ..\..\test_files\sample.txt
        string txtPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "sample.txt");
        if (!File.Exists(txtPath)) txtPath = System.IO.Path.Combine(System.AppContext.BaseDirectory, "..", "..", "..", "..", "test_files") + "\\sample.txt";
        string fText = LoadTextFile(txtPath);

        gPDF = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(gPDF, IntPtr.Zero, _errCb);
        LumasPdf.pdfSetDocInfoW(gPDF, TDocumentInfo.diCreator, "C++ test app");
        LumasPdf.pdfSetDocInfoW(gPDF, TDocumentInfo.diSubject, "Multi-column text");
        LumasPdf.pdfSetDocInfoW(gPDF, TDocumentInfo.diTitle, "Multi-column text");
        LumasPdf.pdfSetPageCoords(gPDF, (int)TPageCoord.pcTopDown);

        if (!LumasPdf.pdfCreateNewPDFW(gPDF, ""))     // The output file is opened later
        {
            LumasPdf.pdfDeletePDF(gPDF);
            return;
        }

        // Initialize the output rectangle, number of columns and so on.
        gRect.ColCount = 3;                 // Form combo default was 3 columns
        gRect.Column = 0;
        gRect.Distance = 10.0;
        gRect.PosX = 50.0;
        gRect.PosY = 50.0;
        gRect.Height_ = LumasPdf.pdfGetPageHeight(gPDF) - 100.0;
        gRect.Width_ = (LumasPdf.pdfGetPageWidth(gPDF) - 100.0 - (gRect.ColCount - 1) * gRect.Distance) / gRect.ColCount;

        // Pass the structure to the callback function (via the static field here).
        LumasPdf.pdfSetOnPageBreakProc(gPDF, IntPtr.Zero, _breakCb);
        LumasPdf.pdfAppend(gPDF);                     // Append a new page
        LumasPdf.pdfSetTextRect(gPDF, gRect.PosX, gRect.PosY, gRect.Width_, gRect.Height_);
        LumasPdf.pdfSetFontW(gPDF, "Arial", LumasPdfConsts.fsNone, 9.0, true, TCodepage.cp1252);   // A font is always required
        // NOTE: this call must stay on the *Ansi* entry point. The Delphi original declares
        // `fText: AnsiString` (Unit1.pas), so `WriteFText(taJustify, fText)` binds to the
        // AnsiString overload -> pdfWriteFTextA. sample.txt is a cp1252 file and the font was
        // created with cp1252, so the Ansi path is the faithful one; pdfWriteFTextW takes a
        // different line-breaking/justification path in the engine and repaginates the document.
        LumasPdf.pdfWriteFTextA(gPDF, LumasPdfConsts.taJustify, fText);              // Now print the text

        LumasPdf.pdfEndPage(gPDF);                    // Close the last page
        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
        // No fatal error occurred?
        if (LumasPdf.pdfHaveOpenDoc(gPDF))
        {
            LumasPdf.pdfSetOnErrorProc(gPDF, IntPtr.Zero, null);
            if (!LumasPdf.pdfOpenOutputFileW(gPDF, outFile))
            {
                LumasPdf.pdfDeletePDF(gPDF);
                return;
            }
            LumasPdf.pdfSetOnErrorProc(gPDF, IntPtr.Zero, _errCb);
        }
        if (LumasPdf.pdfCloseFile(gPDF))
        {
            Console.WriteLine("OK: " + outFile);
        }

        LumasPdf.pdfDeletePDF(gPDF);
    }
}

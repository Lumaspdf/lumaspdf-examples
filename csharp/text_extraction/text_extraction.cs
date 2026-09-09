//  text_extraction -- C# port of examples\Vb6\text_extraction\text_extraction.bas
//  Imports a PDF and extracts its text with GetPageText()/TPDFStack, rebuilding
//  text lines and word boundaries by transforming each text record to user
//  space. Output is written to out.txt as UTF-16LE (with BOM).
using System;
using System.IO;
using System.Text;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class TextExtraction
{
    // TTextDir
    const int tfLeftToRight = 0;
    const int tfRightToLeft = 1;
    const int tfTopToBottom = 2;
    const int tfBottomToTop = 4;
    const int tfNotInitialized = 5;

    const double MAX_LINE_ERROR = 4.0;   // square of the allowed error (2 * 2)

    // CPDFToText member fields
    static IntPtr m_PDF;
    static FileStream m_File;
    static TPDFStack m_Stack;
    static int m_LastTextDir;
    static double m_LastTextEndX;
    static double m_LastTextEndY;
    static double m_LastTextInfX;
    static double m_LastTextInfY;

    // CIntList (template handle list)
    static int[] m_Templates;
    static int m_TemplCount;

    static TErrorProc _errCb = ErrProc;

    public static int ErrProc(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;                        // We try to continue if an error occurs
    }

    // ------------------------- output helpers -------------------------
    static void WriteWStr(string s)
    {
        if (string.IsNullOrEmpty(s)) return;
        byte[] b = Encoding.Unicode.GetBytes(s);  // UTF-16LE
        m_File.Write(b, 0, b.Length);
    }

    static void WriteWCharsFromPtr(IntPtr ptr, int wcharCount)
    {
        if (ptr == IntPtr.Zero || wcharCount <= 0) return;
        byte[] b = new byte[wcharCount * 2];
        Marshal.Copy(ptr, b, 0, wcharCount * 2);
        m_File.Write(b, 0, b.Length);
    }

    // ------------------------- CIntList -------------------------
    static void ListClear()
    {
        m_TemplCount = 0;
    }

    static void ListAdd(int value)
    {
        if (m_TemplCount == 0) m_Templates = new int[64];
        if (m_TemplCount > m_Templates.Length - 1) Array.Resize(ref m_Templates, m_TemplCount + 64);
        m_Templates[m_TemplCount] = value;
        m_TemplCount++;
    }

    static int ListFind(int value)
    {
        for (int i = 0; i < m_TemplCount; i++)
            if (m_Templates[i] == value) return i;
        return -1;
    }

    // ------------------------- matrix helpers -------------------------
    static TCTM MulMatrix(ref TCTM M1, ref TCTM M2)
    {
        TCTM r = new TCTM();
        r.a = M2.a * M1.a + M2.b * M1.c;
        r.b = M2.a * M1.b + M2.b * M1.d;
        r.c = M2.c * M1.a + M2.d * M1.c;
        r.d = M2.c * M1.b + M2.d * M1.d;
        r.x = M2.x * M1.a + M2.y * M1.c + M1.x;
        r.y = M2.x * M1.b + M2.y * M1.d + M1.y;
        return r;
    }

    static void Transform(ref TCTM M, ref double x, ref double y)
    {
        double tx = x;
        x = tx * M.a + y * M.c + M.x;
        y = tx * M.b + y * M.d + M.y;
    }

    static double CalcDistance(double x1, double y1, double x2, double y2)
    {
        double dx = x2 - x1;
        double dy = y2 - y1;
        return Math.Sqrt(dx * dx + dy * dy);
    }

    static bool IsPointOnLine(double x, double y, double x0, double y0, double x1, double y1)
    {
        x = x - x0;
        y = y - y0;
        double dx = x1 - x0;
        double dy = y1 - y0;
        double di = (x * dx + y * dy) / (dx * dx + dy * dy);
        if (di < 0.0) di = 0.0;
        else if (di > 1.0) di = 1.0;
        dx = x - di * dx;
        dy = y - di * dy;
        di = dx * dx + dy * dy;
        return di < MAX_LINE_ERROR;
    }

    // ------------------------- text reconstruction -------------------------
    static void AddText()
    {
        double x1 = 0.0, x2 = 0.0, x3;
        double y1 = 0.0, y2 = m_Stack.FontSize, y3;
        double distance, spaceWidth;
        int textDir;
        float spw;

        // Transform the text matrix to user space
        TCTM m = MulMatrix(ref m_Stack.ctm, ref m_Stack.tm);
        Transform(ref m, ref x1, ref y1);   // Start point of the text record
        Transform(ref m, ref x2, ref y2);   // Second point -> text direction
        // Determine the text direction
        if (y1 == y2)
            textDir = ((x1 > x2 ? 1 : 0) + 1) * 2;
        else
            textDir = (y1 > y2 ? 1 : 0);

        // Wrong direction or not on the same text line?
        if ((textDir != m_LastTextDir) || (!IsPointOnLine(x1, y1, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY)))
        {
            // Extend the x-coordinate to an infinite point.
            m_LastTextInfX = 1000000.0;
            m_LastTextInfY = 0.0;
            Transform(ref m, ref m_LastTextInfX, ref m_LastTextInfY);
            if (m_LastTextDir != tfNotInitialized) WriteWStr("\r\n");
        }
        else
        {
            // Space width is measured in text space, distance in user space -> transform.
            x3 = m_Stack.SpaceWidth;
            y3 = 0.0;
            Transform(ref m, ref x3, ref y3);
            spaceWidth = CalcDistance(x1, y1, x3, y3);
            distance = CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1);
            if (distance > spaceWidth) WriteWStr(" ");
        }

        // Use the half space width to decide whether a space must be inserted.
        spw = (float)(-m_Stack.SpaceWidth * 0.5);
        IntPtr baseP = m_Stack.Kerning;
        int stride = Marshal.SizeOf(typeof(TTextRecordW));   // 24 bytes on x64
        for (int i = 0; i < m_Stack.KerningCount; i++)
        {
            TTextRecordW rec = (TTextRecordW)Marshal.PtrToStructure((IntPtr)(baseP.ToInt64() + (long)i * stride), typeof(TTextRecordW));
            if (rec.Advance < spw) WriteWStr(" ");
            // The Kerning array contains Unicode strings (two bytes per character).
            WriteWCharsFromPtr(rec.Text, rec.Length);
        }

        // Do not set the cursor to the real string end (see original comment).
        m_LastTextEndX = m_Stack.TextWidth + spw;       // spw is negative
        m_LastTextEndY = 0.0;
        m_LastTextDir = textDir;
        Transform(ref m, ref m_LastTextEndX, ref m_LastTextEndY);
    }

    static void ParseText()
    {
        bool haveMore = LumasPdf.pdfGetPageText(m_PDF, ref m_Stack);
        if ((!haveMore) && (m_Stack.TextLen == 0)) return;
        AddText();
        if (haveMore)
        {
            while (LumasPdf.pdfGetPageText(m_PDF, ref m_Stack))
                AddText();
        }
    }

    static void ParseTemplates()
    {
        int tmplCount = LumasPdf.pdfGetTemplCount(m_PDF);
        for (int i = 0; i < tmplCount; i++)
        {
            if (!LumasPdf.pdfEditTemplate(m_PDF, (uint)i)) return;
            int tmpl = LumasPdf.pdfGetTemplHandle(m_PDF);
            if (ListFind(tmpl) < 0)
            {
                ListAdd(tmpl);
                if (!LumasPdf.pdfInitStack(m_PDF, ref m_Stack)) return;
                ParseText();
                int tmplCount2 = LumasPdf.pdfGetTemplCount(m_PDF);
                for (int j = 0; j < tmplCount2; j++)
                    ParseTemplates();
                LumasPdf.pdfEndTemplate(m_PDF);
            }
            else
            {
                LumasPdf.pdfEndTemplate(m_PDF);
            }
        }
    }

    static void ParsePage()
    {
        ListClear();
        if (!LumasPdf.pdfInitStack(m_PDF, ref m_Stack))
        {
            Console.WriteLine(Marshal.PtrToStringAnsi(LumasPdf.pdfGetErrorMessage(m_PDF)));
            return;
        }
        m_LastTextEndX = 0.0;
        m_LastTextEndY = 0.0;
        m_LastTextDir = tfNotInitialized;
        m_LastTextInfX = 0.0;
        m_LastTextInfY = 0.0;
        ParseText();
        ParseTemplates();
    }

    static void Main()
    {
        m_PDF = LumasPdf.pdfNewPDF();
        LumasPdf.pdfCreateNewPDFW(m_PDF, "");          // We do not produce a PDF file in this example
        LumasPdf.pdfSetOnErrorProc(m_PDF, IntPtr.Zero, _errCb);

        // External cmaps should always be loaded when extracting text from PDF files.
        string cmapDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "CMap");
        LumasPdf.pdfSetCMapDirW(m_PDF, cmapDir, LumasPdfConsts.lcmRecursive | LumasPdfConsts.lcmDelayed);

        // Avoid the conversion of pages to templates.
        LumasPdf.pdfSetImportFlags(m_PDF, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);

        // Original used a fixed input ..\..\..\sample_multipage.pdf
        string inFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "in.pdf");
        if (!File.Exists(inFile)) inFile = System.IO.Path.Combine(System.AppContext.BaseDirectory, "..", "..", "..", "..", "test_files") + "\\sample_multipage.pdf";
        if (LumasPdf.pdfOpenImportFileW(m_PDF, inFile, (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            LumasPdf.pdfDeletePDF(m_PDF);
            return;
        }
        LumasPdf.pdfImportPDFFile(m_PDF, 1, 1.0, 1.0);
        LumasPdf.pdfCloseImportFile(m_PDF);

        // Flatten markup annotations and form fields so their text can be extracted too.
        LumasPdf.pdfFlattenAnnots(m_PDF, LumasPdfConsts.affMarkupAnnots);
        LumasPdf.pdfFlattenForm(m_PDF);

        // Open the output file (out.txt in the application directory).
        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.txt");
        m_File = new FileStream(outFile, FileMode.Create, FileAccess.Write);
        m_File.Write(new byte[] { 0xFF, 0xFE }, 0, 2);         // UTF-16LE BOM

        // Note that page numbering starts at 1!
        int pageCount = LumasPdf.pdfGetPageCount(m_PDF);
        for (int i = 1; i <= pageCount; i++)
        {
            LumasPdf.pdfEditPage(m_PDF, i);           // Open the page
            WriteWStr((i > 1 ? "\r\n" : "") + "%----------------------- Page " + i + " -----------------------------\r\n");
            ParsePage();
            LumasPdf.pdfEndPage(m_PDF);               // Close the page
        }
        m_File.Close();

        Console.WriteLine("Text successfully extracted to " + outFile);
        LumasPdf.pdfDeletePDF(m_PDF);
    }
}

//  text_extraction2 -- C# port of
//  examples\Vb6\content_parser\text_extraction2\text_extraction2.bas
//  Extracts the text of a PDF file by driving pdfParseContent() with a
//  TPDFParseInterface of stdcall callbacks. Output is out.txt as UTF-16LE (BOM).
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using LumasPdfSdk;

class TextExtraction2
{
    // TTextDir
    const int tfNotInitialized = 5;
    const double MAX_LINE_ERROR = 4.0;   // square of the allowed error (2 * 2)

    struct TGState
    {
        public IntPtr ActiveFont;
        public float CharSpacing;
        public float FontSize;
        public int FontType;
        public TCTM Matrix;
        public float SpaceWidth;
        public int TextDrawMode;
        public float TextScale;
        public float WordSpacing;
    }

    static IntPtr m_PDF;
    static FileStream m_File;
    static TGState m_GState;
    static int m_LastTextDir;
    static double m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY;

    static TGState[] m_StackItems = new TGState[0];
    static int m_StackCount;
    static int m_StackCapacity;

    static readonly int RecW = Marshal.SizeOf(typeof(TTextRecordW));

    // ---- callback delegates ----
    delegate int BeginTemplateDel(IntPtr Data, IntPtr PDFObject, int Handle, ref TPDFRect BBox, IntPtr Matrix);
    delegate void EndTemplateDel(IntPtr Data);
    delegate void MulMatrixDel(IntPtr Data, IntPtr PDFObject, ref TCTM Matrix);
    delegate int RestoreGSDel(IntPtr Data);
    delegate int SaveGSDel(IntPtr Data);
    delegate void SetCharSpacingDel(IntPtr Data, IntPtr PDFObject, double Value);
    delegate void SetFontDel(IntPtr Data, IntPtr PDFObject, int FontType, bool Embedded, IntPtr FontName, int Style, double FontSize, IntPtr Font);
    delegate void SetTextDrawModeDel(IntPtr Data, IntPtr PDFObject, int Mode);
    delegate void SetTextScaleDel(IntPtr Data, IntPtr PDFObject, double Value);
    delegate void SetWordSpacingDel(IntPtr Data, IntPtr PDFObject, double Value);
    delegate int ShowTextArrayWDel(IntPtr Data, IntPtr Source, ref TCTM Matrix, IntPtr Kerning, uint Count, double Width, bool Decoded);

    static BeginTemplateDel _beginTemplate = ParseBeginTemplate;
    static EndTemplateDel _endTemplate = ParseEndTemplate;
    static MulMatrixDel _mulMatrix = ParseMulMatrix;
    static RestoreGSDel _restoreGS = ParseRestoreGraphicState;
    static SaveGSDel _saveGS = ParseSaveGraphicState;
    static SetCharSpacingDel _setCharSpacing = ParseSetCharSpacing;
    static SetFontDel _setFont = ParseSetFont;
    static SetTextDrawModeDel _setTextDrawMode = ParseSetTextDrawMode;
    static SetTextScaleDel _setTextScale = ParseSetTextScale;
    static SetWordSpacingDel _setWordSpacing = ParseSetWordSpacing;
    static ShowTextArrayWDel _showTextArrayW = ParseShowTextArrayW;
    static TErrorProc _err = ErrProc;

    static int ErrProc(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;
    }

    // ---- output helpers ----
    static void WriteWStr(string s)
    {
        if (string.IsNullOrEmpty(s)) return;
        byte[] b = Encoding.Unicode.GetBytes(s);
        m_File.Write(b, 0, b.Length);
    }

    static void WriteWCharsFromPtr(IntPtr ptr, int wcharCount)
    {
        if (ptr == IntPtr.Zero || wcharCount <= 0) return;
        byte[] b = new byte[wcharCount * 2];
        Marshal.Copy(ptr, b, 0, b.Length);
        m_File.Write(b, 0, b.Length);
    }

    // ---- stack ----
    static bool StackRestore(ref TGState f)
    {
        if (m_StackCount > 0)
        {
            m_StackCount--;
            f = m_StackItems[m_StackCount];
            return true;
        }
        return false;
    }

    static int StackSave(ref TGState f)
    {
        if (m_StackCount == m_StackCapacity)
        {
            m_StackCapacity += 28;
            Array.Resize(ref m_StackItems, m_StackCapacity);
        }
        m_StackItems[m_StackCount] = f;
        m_StackCount++;
        return 0;
    }

    // ---- matrix helpers ----
    static TCTM MulMatrix(TCTM M1, TCTM M2)
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

    static void Transform(TCTM M, ref double x, ref double y)
    {
        double tx = x;
        x = tx * M.a + y * M.c + M.x;
        y = tx * M.b + y * M.d + M.y;
    }

    static double CalcDistance(double x1, double y1, double x2, double y2)
    {
        double dx = x2 - x1, dy = y2 - y1;
        return Math.Sqrt(dx * dx + dy * dy);
    }

    static bool IsPointOnLine(double x, double y, double x0, double y0, double x1, double y1)
    {
        double dx, dy, di;
        x -= x0; y -= y0;
        dx = x1 - x0; dy = y1 - y0;
        double denom = dx * dx + dy * dy;
        if (denom == 0.0)   // KEEP the div-by-zero guard
            return (x * x + y * y) < MAX_LINE_ERROR;
        di = (x * dx + y * dy) / denom;
        if (di < 0.0) di = 0.0; else if (di > 1.0) di = 1.0;
        dx = x - di * dx;
        dy = y - di * dy;
        di = dx * dx + dy * dy;
        return di < MAX_LINE_ERROR;
    }

    // ---- CPDFToText ----
    static bool DoRestoreGState() { return StackRestore(ref m_GState); }
    static int DoSaveGState() { return StackSave(ref m_GState); }

    static void ResetGState()
    {
        m_GState.ActiveFont = IntPtr.Zero;
        m_GState.CharSpacing = 0f;
        m_GState.FontSize = 1f;
        m_GState.FontType = (int)TFontType.ftType1;
        m_GState.Matrix.a = 1.0; m_GState.Matrix.b = 0.0; m_GState.Matrix.c = 0.0;
        m_GState.Matrix.d = 1.0; m_GState.Matrix.x = 0.0; m_GState.Matrix.y = 0.0;
        m_GState.SpaceWidth = 0f;
        m_GState.TextDrawMode = (int)TDrawMode.dmNormal;
        m_GState.TextScale = 100f;
        m_GState.WordSpacing = 0f;
    }

    static void DoInit()
    {
        while (DoRestoreGState()) { }
        ResetGState();
        m_LastTextDir = tfNotInitialized;
        m_LastTextEndX = 0.0; m_LastTextEndY = 0.0;
        m_LastTextInfX = 0.0; m_LastTextInfY = 0.0;
    }

    static void DoSetFont(IntPtr IFont, int FontType, double FontSize)
    {
        m_GState.ActiveFont = IFont;
        m_GState.FontSize = (float)FontSize;
        m_GState.FontType = FontType;
        m_GState.SpaceWidth = (float)LumasPdf.fntGetSpaceWidth(IFont, FontSize);
        if (FontSize < 0.0) m_GState.SpaceWidth = -m_GState.SpaceWidth;
    }

    static void DoWritePageIdentifier(int pageNum)
    {
        if (pageNum > 1) WriteWStr("\r\n");
        WriteWStr("%----------------------- Page " + pageNum + " -----------------------------\r\n");
    }

    static int DoAddText(TCTM Matrix, IntPtr Kerning, int Count, double Widen, bool Decoded)
    {
        if (!Decoded) return 0;

        double x1 = 0.0, y1 = 0.0, x2 = 0.0, y2 = m_GState.FontSize, x3, y3;
        double distance, spaceWidth;
        int textDir;
        TCTM m = MulMatrix(m_GState.Matrix, Matrix);
        Transform(m, ref x1, ref y1);       // Start point of the text record
        Transform(m, ref x2, ref y2);       // Second point -> text direction

        if (y1 == y2)
            textDir = ((x1 > x2 ? 1 : 0) + 1) * 2;
        else
            textDir = (y1 > y2 ? 1 : 0);

        if ((textDir != m_LastTextDir) || (!IsPointOnLine(x1, y1, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY)))
        {
            m_LastTextInfX = 1000000.0;
            m_LastTextInfY = 0.0;
            Transform(m, ref m_LastTextInfX, ref m_LastTextInfY);
            if (m_LastTextDir != tfNotInitialized) WriteWStr("\r\n");
        }
        else
        {
            x3 = m_GState.SpaceWidth; y3 = 0.0;
            Transform(m, ref x3, ref y3);
            spaceWidth = CalcDistance(x1, y1, x3, y3);
            distance = CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1);
            if (distance > spaceWidth) WriteWStr(" ");
        }

        float spw = -m_GState.SpaceWidth * 0.5f;
        for (int i = 0; i < Count; i++)
        {
            TTextRecordW rec = (TTextRecordW)Marshal.PtrToStructure(IntPtr.Add(Kerning, i * RecW), typeof(TTextRecordW));
            if (rec.Advance < spw) WriteWStr(" ");
            WriteWCharsFromPtr(rec.Text, rec.Length);
        }

        m_LastTextEndX = Widen + spw;   // spw is negative
        m_LastTextEndY = 0.0;
        m_LastTextDir = textDir;
        Transform(m, ref m_LastTextEndX, ref m_LastTextEndY);
        return 0;
    }

    // ---- parse callback thunks ----
    static int ParseBeginTemplate(IntPtr Data, IntPtr PDFObject, int Handle, ref TPDFRect BBox, IntPtr Matrix)
    {
        if (DoSaveGState() < 0) return -1;
        if (Matrix != IntPtr.Zero)
        {
            TCTM mtx = (TCTM)Marshal.PtrToStructure(Matrix, typeof(TCTM));
            m_GState.Matrix = MulMatrix(m_GState.Matrix, mtx);
        }
        return 0;
    }
    static void ParseEndTemplate(IntPtr Data) { DoRestoreGState(); }
    static void ParseMulMatrix(IntPtr Data, IntPtr PDFObject, ref TCTM Matrix)
    { m_GState.Matrix = MulMatrix(m_GState.Matrix, Matrix); }
    static int ParseRestoreGraphicState(IntPtr Data) { DoRestoreGState(); return 0; }
    static int ParseSaveGraphicState(IntPtr Data) { DoSaveGState(); return 0; }
    static void ParseSetCharSpacing(IntPtr Data, IntPtr PDFObject, double Value) { m_GState.CharSpacing = (float)Value; }
    static void ParseSetFont(IntPtr Data, IntPtr PDFObject, int FontType, bool Embedded, IntPtr FontName, int Style, double FontSize, IntPtr Font)
    { DoSetFont(Font, FontType, FontSize); }
    static void ParseSetTextDrawMode(IntPtr Data, IntPtr PDFObject, int Mode) { m_GState.TextDrawMode = Mode; }
    static void ParseSetTextScale(IntPtr Data, IntPtr PDFObject, double Value) { m_GState.TextScale = (float)Value; }
    static void ParseSetWordSpacing(IntPtr Data, IntPtr PDFObject, double Value) { m_GState.WordSpacing = (float)Value; }
    static int ParseShowTextArrayW(IntPtr Data, IntPtr Source, ref TCTM Matrix, IntPtr Kerning, uint Count, double Width, bool Decoded)
    { return DoAddText(Matrix, Kerning, (int)Count, Width, Decoded); }

    static void Main()
    {
        m_PDF = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(m_PDF, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(m_PDF, "");

        LumasPdf.pdfSetCMapDirW(m_PDF, Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "CMap"),
            LumasPdfConsts.lcmRecursive | LumasPdfConsts.lcmDelayed);

        LumasPdf.pdfSetImportFlags(m_PDF, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);

        string inFile = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "../../../../dynapdf_help.pdf"));
        if (LumasPdf.pdfOpenImportFileW(m_PDF, inFile, (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            Console.WriteLine("Input file \"" + inFile + "\" not found!");
            LumasPdf.pdfDeletePDF(m_PDF);
            return;
        }
        if (LumasPdf.pdfImportPDFFile(m_PDF, 1, 1.0, 1.0) < 0)
        {
            LumasPdf.pdfDeletePDF(m_PDF);
            return;
        }

        LumasPdf.pdfFlattenAnnots(m_PDF, LumasPdfConsts.affMarkupAnnots);
        LumasPdf.pdfFlattenForm(m_PDF);

        TPDFParseInterface stack = new TPDFParseInterface();
        stack.BeginTemplate = Marshal.GetFunctionPointerForDelegate(_beginTemplate);
        stack.EndTemplate = Marshal.GetFunctionPointerForDelegate(_endTemplate);
        stack.MulMatrix = Marshal.GetFunctionPointerForDelegate(_mulMatrix);
        stack.RestoreGraphicState = Marshal.GetFunctionPointerForDelegate(_restoreGS);
        stack.SaveGraphicState = Marshal.GetFunctionPointerForDelegate(_saveGS);
        stack.SetCharSpacing = Marshal.GetFunctionPointerForDelegate(_setCharSpacing);
        stack.SetFont = Marshal.GetFunctionPointerForDelegate(_setFont);
        stack.SetTextDrawMode = Marshal.GetFunctionPointerForDelegate(_setTextDrawMode);
        stack.SetTextScale = Marshal.GetFunctionPointerForDelegate(_setTextScale);
        stack.SetWordSpacing = Marshal.GetFunctionPointerForDelegate(_setWordSpacing);
        stack.ShowTextArrayW = Marshal.GetFunctionPointerForDelegate(_showTextArrayW);

        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.txt");
        m_File = new FileStream(outFile, FileMode.Create, FileAccess.Write);
        m_File.Write(new byte[] { 0xFF, 0xFE }, 0, 2);   // UTF-16LE BOM

        int pageCount = LumasPdf.pdfGetPageCount(m_PDF);
        for (int i = 1; i <= pageCount; i++)
        {
            LumasPdf.pdfEditPage(m_PDF, i);
            DoInit();
            DoWritePageIdentifier(i);
            LumasPdf.pdfParseContent(m_PDF, IntPtr.Zero, ref stack, (int)LumasPdfConsts.pfNone);
            LumasPdf.pdfEndPage(m_PDF);
        }
        m_File.Close();

        Console.WriteLine("Text successfully extracted to " + outFile);

        GC.KeepAlive(_beginTemplate); GC.KeepAlive(_endTemplate); GC.KeepAlive(_mulMatrix);
        GC.KeepAlive(_restoreGS); GC.KeepAlive(_saveGS); GC.KeepAlive(_setCharSpacing);
        GC.KeepAlive(_setFont); GC.KeepAlive(_setTextDrawMode); GC.KeepAlive(_setTextScale);
        GC.KeepAlive(_setWordSpacing); GC.KeepAlive(_showTextArrayW);
        LumasPdf.pdfDeletePDF(m_PDF);
    }
}

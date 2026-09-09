//  text_search -- C# port of examples\Vb6\content_parser\text_search\text_search.bas
//  Imports dynapdf_help.pdf, searches for the Unicode string "PDF" across the
//  content stream via pdfParseContent + a flattened state machine, and draws
//  yellow multiply-blend rectangles over each match. Output out.pdf.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class TextSearch
{
    const string DLL = "LumasPdf.dll";
    // Raw-pointer overload of fntTranslateRawCode (wrapper takes a managed string).
    [DllImport(DLL, EntryPoint = "fntTranslateRawCode", CallingConvention = CallingConvention.StdCall, ExactSpelling = true)]
    static extern int fntTranslateRawCodeP(IntPtr IFont, IntPtr Text, uint Len, ref double Width, IntPtr OutText, ref int OutLen, ref int Decoded, float CharSpacing, float WordSpacing, float TextScale);

    const int tfNotInitialized = 5;
    const double MAX_LINE_ERROR = 4.0;

    struct GStateT
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
    // current graphics state
    static IntPtr m_ActiveFont;
    static float m_CharSpacing, m_FontSize, m_SpaceWidth, m_TextScale, m_WordSpacing;
    static int m_FontType, m_TextDrawMode;
    static TCTM m_Matrix;

    // stack
    static GStateT[] m_Items = new GStateT[0];
    static int m_Count, m_Capacity;

    // search / hit tracking
    static double m_EndX1, m_EndY1, m_EndX4, m_EndY4;
    static bool m_HavePos;
    static int m_LastTextDir;
    static double m_LastTextInfX, m_LastTextInfY;
    static IntPtr m_OutBuf;           // 64 bytes (32 WideChars)
    static char[] m_SearchChars = new char[0];
    static int m_SearchTextLen;
    static int m_SearchPos;
    static int m_SelCount;
    static double m_x1, m_y1, m_x4, m_y4;

    static readonly int RecA = Marshal.SizeOf(typeof(TTextRecordA));

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
    delegate int ShowTextArrayADel(IntPtr Data, IntPtr Obj, ref TCTM Matrix, IntPtr Source, uint Count, double Width);

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
    static ShowTextArrayADel _showTextArrayA = ParseShowTextArrayA;
    static TErrorProc _err = ErrProc;

    static int ErrProc(IntPtr Data, int ErrCode, string ErrMessage, int ErrType)
    {
        Console.WriteLine(ErrMessage);
        return 0;
    }

    // ---- matrix / geometry ----
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

    // ---- search string ----
    static void SetSearchText(string txt)
    {
        m_SearchTextLen = txt.Length;
        if (m_SearchTextLen > 0)
            m_SearchChars = txt.ToCharArray();
        m_SearchPos = 0;
    }

    static int SPCode()
    {
        if (m_SearchPos >= m_SearchTextLen) return 0;
        return m_SearchChars[m_SearchPos];
    }

    static void Reset_()
    {
        m_HavePos = false;
        m_SearchPos = 0;
    }

    static bool Compare(IntPtr TextPtr, int Len)
    {
        IntPtr endPtr = IntPtr.Add(TextPtr, Len * 2);
        while ((long)TextPtr < (long)endPtr)
        {
            int wc = (ushort)Marshal.ReadInt16(TextPtr);
            if (SPCode() != wc)
            {
                m_HavePos = false;
                m_SearchPos = 0;
                return false;
            }
            TextPtr = IntPtr.Add(TextPtr, 2);
            m_SearchPos++;
            if (SPCode() == 0)
            {
                m_SearchPos = 0;
                return ((long)TextPtr == (long)endPtr);
            }
        }
        return true;
    }

    // ---- stack ----
    static int SaveGState()
    {
        if (m_Count == m_Capacity)
        {
            m_Capacity += 28;
            Array.Resize(ref m_Items, m_Capacity);
        }
        GStateT g;
        g.ActiveFont = m_ActiveFont; g.CharSpacing = m_CharSpacing; g.FontSize = m_FontSize;
        g.FontType = m_FontType; g.Matrix = m_Matrix; g.SpaceWidth = m_SpaceWidth;
        g.TextDrawMode = m_TextDrawMode; g.TextScale = m_TextScale; g.WordSpacing = m_WordSpacing;
        m_Items[m_Count] = g;
        m_Count++;
        return 0;
    }

    static bool RestoreGState()
    {
        if (m_Count > 0)
        {
            m_Count--;
            GStateT g = m_Items[m_Count];
            m_ActiveFont = g.ActiveFont; m_CharSpacing = g.CharSpacing; m_FontSize = g.FontSize;
            m_FontType = g.FontType; m_Matrix = g.Matrix; m_SpaceWidth = g.SpaceWidth;
            m_TextDrawMode = g.TextDrawMode; m_TextScale = g.TextScale; m_WordSpacing = g.WordSpacing;
            return true;
        }
        return false;
    }

    // ---- rectangle drawing ----
    static void SetStartCoord(TCTM Matrix, double x)
    {
        m_x1 = x; m_y1 = 0.0;
        m_x4 = x; m_y4 = m_FontSize;
        Transform(Matrix, ref m_x1, ref m_y1);
        Transform(Matrix, ref m_x4, ref m_y4);
        m_HavePos = true;
    }

    static bool DrawRectEx(double x2, double y2, double x3, double y3)
    {
        LumasPdf.pdfMoveTo(m_PDF, m_x1, m_y1);
        LumasPdf.pdfLineTo(m_PDF, x2, y2);
        LumasPdf.pdfLineTo(m_PDF, x3, y3);
        LumasPdf.pdfLineTo(m_PDF, m_x4, m_y4);
        m_HavePos = false;
        m_SelCount++;
        return LumasPdf.pdfClosePath(m_PDF, TPathFillMode.fmFill);
    }

    static bool DrawRect(TCTM Matrix, double EndX)
    {
        double x2 = EndX, y2 = 0.0, x3 = EndX, y3 = m_FontSize;
        Transform(Matrix, ref x2, ref y2);
        Transform(Matrix, ref x3, ref y3);
        return DrawRectEx(x2, y2, x3, y3);
    }

    // ---- init ----
    static void InitGState()
    {
        while (RestoreGState()) { }
        m_ActiveFont = IntPtr.Zero;
        m_CharSpacing = 0f;
        m_FontSize = 1f;
        m_Matrix.a = 1.0; m_Matrix.b = 0.0; m_Matrix.c = 0.0;
        m_Matrix.d = 1.0; m_Matrix.x = 0.0; m_Matrix.y = 0.0;
        m_SpaceWidth = 0f;
        m_TextDrawMode = (int)TDrawMode.dmNormal;
        m_TextScale = 100f;
        m_WordSpacing = 0f;
        m_LastTextDir = tfNotInitialized;
        m_LastTextInfX = 0.0; m_LastTextInfY = 0.0;
    }

    static void TS_Create()
    {
        m_ActiveFont = IntPtr.Zero;
        m_CharSpacing = 0f;
        m_FontSize = 1f;
        m_FontType = (int)TFontType.ftType1;
        m_Matrix.a = 1.0; m_Matrix.b = 0.0; m_Matrix.c = 0.0;
        m_Matrix.d = 1.0; m_Matrix.x = 0.0; m_Matrix.y = 0.0;
        m_SpaceWidth = 0f;
        m_TextDrawMode = (int)TDrawMode.dmNormal;
        m_TextScale = 100f;
        m_WordSpacing = 0f;
        m_Count = 0;
        m_Capacity = 0;
    }

    static void TS_Init()
    {
        InitGState();
        Reset_();
        m_SelCount = 0;
    }

    // ---- matching core ----
    static bool MarkSubString(ref double x, TCTM Matrix, IntPtr SourcePtr)
    {
        TTextRecordA srec = (TTextRecordA)Marshal.PtrToStructure(SourcePtr, typeof(TTextRecordA));
        int i = 0;
        float spaceWidth2 = -m_SpaceWidth * 6f;
        int maxLen = srec.Length;
        IntPtr srcPtr = srec.Text;
        if (srec.Advance < -m_SpaceWidth)
        {
            if ((srec.Advance > spaceWidth2) && (SPCode() == 32))
            {
                if (!m_HavePos)
                {
                    SetStartCoord(Matrix, x);
                    m_SearchPos++;
                    if (SPCode() == 0)
                    {
                        if (!DrawRect(Matrix, x - srec.Advance)) return false;
                        Reset_();
                    }
                }
                else if (SPCode() == 0)
                {
                    if (!DrawRect(Matrix, 0.0)) return false;
                    Reset_();
                }
                else
                {
                    m_SearchPos++;
                }
            }
            else
            {
                Reset_();
            }
        }
        x = x - srec.Advance;
        int outLen = 0;
        double w = 0.0;
        int decoded = 0;
        while (i < maxLen)
        {
            int consumed = fntTranslateRawCodeP(m_ActiveFont, IntPtr.Add(srcPtr, i), (uint)(maxLen - i), ref w, m_OutBuf, ref outLen, ref decoded, m_CharSpacing, m_WordSpacing, m_TextScale);
            if (consumed <= 0) break;   // safety: never let i stall
            i += consumed;
            if (decoded == 0) return true;   // cannot convert -> skip record but keep going
            if (Compare(m_OutBuf, outLen))
            {
                if (!m_HavePos) SetStartCoord(Matrix, x);
                x += w;
                if (m_SearchPos == 0)
                {
                    if (!DrawRect(Matrix, x - m_CharSpacing)) return false;
                }
            }
            else
            {
                x += w;
            }
        }
        return true;
    }

    static int MarkText(TCTM Matrix, IntPtr SourcePtr, int Count, double Width_)
    {
        double x, x1 = 0.0, x2 = 0.0, x3, y1 = 0.0, y2 = m_FontSize, y3;
        double distance, spaceWidth;
        int textDir;
        TCTM m = MulMatrix(m_Matrix, Matrix);
        Transform(m, ref x1, ref y1);
        Transform(m, ref x2, ref y2);
        if (y1 == y2)
            textDir = ((x1 > x2 ? 1 : 0) + 1) * 2;
        else
            textDir = (y1 > y2 ? 1 : 0);

        // Reproduce Delphi's short-circuit OR.
        bool wrongLine = false;
        if (textDir != m_LastTextDir)
            wrongLine = true;
        else if (!IsPointOnLine(x1, y1, m_EndX1, m_EndY1, m_LastTextInfX, m_LastTextInfY))
            wrongLine = true;

        if (wrongLine)
        {
            m_LastTextInfX = 1000000.0;
            m_LastTextInfY = 0.0;
            Transform(m, ref m_LastTextInfX, ref m_LastTextInfY);
            Reset_();
        }
        else
        {
            x3 = m_SpaceWidth; y3 = 0.0;
            Transform(m, ref x3, ref y3);
            spaceWidth = CalcDistance(x1, y1, x3, y3);
            distance = CalcDistance(m_EndX1, m_EndY1, x1, y1);
            if (distance > spaceWidth)
            {
                if ((distance < spaceWidth * 6.0) && (SPCode() == 32))
                {
                    if (!m_HavePos)
                    {
                        m_HavePos = true;
                        m_SearchPos++;
                        if (SPCode() == 0)
                        {
                            m_x1 = m_EndX1; m_y1 = m_EndY1;
                            m_x4 = m_EndX4; m_y4 = m_EndY4;
                            if (!DrawRectEx(x1, y1, x2, y2)) return -1;
                            Reset_();
                        }
                    }
                    else if (SPCode() == 32)
                    {
                        if (!DrawRectEx(x1, y1, x2, y2)) return -1;
                        Reset_();
                    }
                    else
                    {
                        m_SearchPos++;
                    }
                }
                else
                {
                    Reset_();
                }
            }
        }

        x = 0.0;
        IntPtr recPtr = SourcePtr;
        for (int i = 0; i < Count; i++)
        {
            if (!MarkSubString(ref x, m, recPtr)) return -1;
            recPtr = IntPtr.Add(recPtr, RecA);
        }
        m_LastTextDir = textDir;
        m_EndX1 = Width_; m_EndY1 = 0.0;
        m_EndX4 = 0.0; m_EndY4 = m_FontSize;
        Transform(m, ref m_EndX1, ref m_EndY1);
        Transform(m, ref m_EndX4, ref m_EndY4);
        return 0;
    }

    static int BeginTemplate(IntPtr MatrixPtr)
    {
        if (SaveGState() < 0) return -1;
        if (MatrixPtr != IntPtr.Zero)
        {
            TCTM mtx = (TCTM)Marshal.PtrToStructure(MatrixPtr, typeof(TCTM));
            m_Matrix = MulMatrix(m_Matrix, mtx);
        }
        return 0;
    }

    static void TS_SetFont(IntPtr IFont, int FontType, double FontSize)
    {
        m_ActiveFont = IFont;
        m_FontSize = (float)FontSize;
        m_FontType = FontType;
        m_SpaceWidth = (float)(LumasPdf.fntGetSpaceWidth(IFont, FontSize) * 0.5);
    }

    // ---- parse callback thunks ----
    static int ParseBeginTemplate(IntPtr Data, IntPtr PDFObject, int Handle, ref TPDFRect BBox, IntPtr Matrix)
    { return BeginTemplate(Matrix); }
    static void ParseEndTemplate(IntPtr Data) { RestoreGState(); }
    static void ParseMulMatrix(IntPtr Data, IntPtr PDFObject, ref TCTM Matrix)
    { m_Matrix = MulMatrix(m_Matrix, Matrix); }
    static int ParseRestoreGraphicState(IntPtr Data) { RestoreGState(); return 0; }
    static int ParseSaveGraphicState(IntPtr Data) { return SaveGState(); }
    static void ParseSetCharSpacing(IntPtr Data, IntPtr PDFObject, double Value) { m_CharSpacing = (float)Value; }
    static void ParseSetFont(IntPtr Data, IntPtr PDFObject, int FontType, bool Embedded, IntPtr FontName, int Style, double FontSize, IntPtr Font)
    { TS_SetFont(Font, FontType, FontSize); }
    static void ParseSetTextDrawMode(IntPtr Data, IntPtr PDFObject, int Mode) { m_TextDrawMode = Mode; }
    static void ParseSetTextScale(IntPtr Data, IntPtr PDFObject, double Value) { m_TextScale = (float)Value; }
    static void ParseSetWordSpacing(IntPtr Data, IntPtr PDFObject, double Value) { m_WordSpacing = (float)Value; }
    static int ParseShowTextArrayA(IntPtr Data, IntPtr Obj, ref TCTM Matrix, IntPtr Source, uint Count, double Width)
    { return MarkText(Matrix, Source, (int)Count, Width); }

    static void Main()
    {
        int selCount = 0;
        m_PDF = IntPtr.Zero;
        TS_Create();
        m_OutBuf = Marshal.AllocHGlobal(64);

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
        stack.ShowTextArrayA = Marshal.GetFunctionPointerForDelegate(_showTextArrayA);

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

        SetSearchText("PDF");

        TPDFExtGState g = new TPDFExtGState();
        LumasPdf.pdfInitExtGState(ref g);
        g.BlendMode = TBlendMode.bmMultiply;
        uint gs = (uint)LumasPdf.pdfCreateExtGState(m_PDF, ref g);

        int pageCount = LumasPdf.pdfGetPageCount(m_PDF);
        for (int i = 1; i <= pageCount; i++)
        {
            LumasPdf.pdfEditPage(m_PDF, i);
            LumasPdf.pdfSetExtGState(m_PDF, gs);
            LumasPdf.pdfSetFillColor(m_PDF, (uint)(255 | (255 << 8)));   // RGB(255,255,0)
            TS_Init();
            LumasPdf.pdfParseContent(m_PDF, IntPtr.Zero, ref stack, (int)LumasPdfConsts.pfNone);
            LumasPdf.pdfEndPage(m_PDF);
            if (m_SelCount > 0)
            {
                selCount += m_SelCount;
                Console.WriteLine("Found string on Page: " + i + " " + m_SelCount + " times!");
            }
        }

        string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
        if (LumasPdf.pdfHaveOpenDoc(m_PDF))
        {
            if (!LumasPdf.pdfOpenOutputFileW(m_PDF, outFile))
            {
                LumasPdf.pdfDeletePDF(m_PDF);
                return;
            }
        }
        if (LumasPdf.pdfCloseFile(m_PDF))
            Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
        Console.WriteLine("\nFound string in the file " + selCount + " times!");

        Marshal.FreeHGlobal(m_OutBuf);
        GC.KeepAlive(_beginTemplate); GC.KeepAlive(_endTemplate); GC.KeepAlive(_mulMatrix);
        GC.KeepAlive(_restoreGS); GC.KeepAlive(_saveGS); GC.KeepAlive(_setCharSpacing);
        GC.KeepAlive(_setFont); GC.KeepAlive(_setTextDrawMode); GC.KeepAlive(_setTextScale);
        GC.KeepAlive(_setWordSpacing); GC.KeepAlive(_showTextArrayA);
        LumasPdf.pdfDeletePDF(m_PDF);
    }
}

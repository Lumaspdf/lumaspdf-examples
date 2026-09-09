//  text_coordinates -- C# port of
//  examples\Vb6\content_parser\text_coordinates\text_coordinates.bas
//  Imports sample_multipage.pdf and, for every page, runs pdfParseContent with a
//  callback interface. MarkText draws lines under each text record to visualise
//  the computed text coordinates, alternating stroke colour blue/red.
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class TextCoordinates
{
    const string DLL = "LumasPdf.dll";
    // Raw-pointer overload of fntGetTextWidth (wrapper takes a managed string).
    [DllImport(DLL, EntryPoint = "fntGetTextWidth", CallingConvention = CallingConvention.StdCall, ExactSpelling = true)]
    static extern double fntGetTextWidthP(IntPtr IFont, IntPtr Text, uint Len, float CharSpacing, float WordSpacing, float TextScale);

    // VCL COLORREF colours.
    const uint clRed = 0xFF;
    const uint clBlue = 0xFF0000;

    // ---- flattened TGState ----
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
    static int m_Count;
    static TGState m_GState;

    static TGState[] m_Items = new TGState[0];
    static int m_StackCap;
    static int m_StackCount;

    static readonly int RecW = Marshal.SizeOf(typeof(TTextRecordW));
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

    static void Transform(TCTM m, ref double x, ref double y)
    {
        double tx = x;
        x = tx * m.a + y * m.c + m.x;
        y = tx * m.b + y * m.d + m.y;
    }

    // ---- stack ----
    static bool RestoreGState()
    {
        if (m_StackCount > 0)
        {
            m_StackCount--;
            m_GState = m_Items[m_StackCount];
            return true;
        }
        return false;
    }

    static int SaveGState()
    {
        if (m_StackCount == m_StackCap)
        {
            m_StackCap += 28;
            Array.Resize(ref m_Items, m_StackCap);
        }
        m_Items[m_StackCount] = m_GState;
        m_StackCount++;
        return 0;
    }

    // ---- CTextCoordinates ----
    static void ResetGState()
    {
        m_GState.ActiveFont = IntPtr.Zero;
        m_GState.CharSpacing = 0f;
        m_GState.FontSize = 1f;
        m_GState.FontType = (int)TFontType.ftType1;
        m_GState.Matrix.a = 1.0; m_GState.Matrix.b = 0.0; m_GState.Matrix.c = 0.0;
        m_GState.Matrix.d = 1.0; m_GState.Matrix.x = 0.0; m_GState.Matrix.y = 0.0;
        m_GState.TextDrawMode = (int)TDrawMode.dmNormal;
        m_GState.TextScale = 100f;
        m_GState.WordSpacing = 0f;
    }

    static void TCInit()
    {
        while (RestoreGState()) { }
        m_Count = 0;
        ResetGState();
    }

    static int BeginTemplateImpl(IntPtr MatrixPtr)
    {
        if (SaveGState() < 0) return -1;
        if (MatrixPtr != IntPtr.Zero)
        {
            TCTM tmp = (TCTM)Marshal.PtrToStructure(MatrixPtr, typeof(TCTM));
            m_GState.Matrix = MulMatrix(m_GState.Matrix, tmp);
        }
        return 0;
    }

    static void SetFontImpl(IntPtr IFont, int FontType, double FontSize)
    {
        m_GState.ActiveFont = IFont;
        m_GState.FontSize = (float)FontSize;
        m_GState.FontType = FontType;
        m_GState.SpaceWidth = (float)LumasPdf.fntGetSpaceWidth(IFont, FontSize);
    }

    static int MarkText(TCTM Matrix, IntPtr Source, IntPtr Kerning, int Count, double AWidth, bool Decoded)
    {
        if (!Decoded) return 0;

        double x1 = 0.0, y1 = 0.0, x2, y2, textWidth;
        TCTM m = MulMatrix(m_GState.Matrix, Matrix);
        Transform(m, ref x1, ref y1);       // Start point of the text record

        textWidth = 0.0;
        if (m_GState.FontType == (int)TFontType.ftType0)
        {
            // Word spacing must be ignored if a CID font is selected!
            for (int i = 0; i < Count; i++)
            {
                TTextRecordW krec = (TTextRecordW)Marshal.PtrToStructure(IntPtr.Add(Kerning, i * RecW), typeof(TTextRecordW));
                if (krec.Advance != 0f)
                {
                    textWidth -= krec.Advance;
                    x1 = textWidth; y1 = 0.0;
                    Transform(m, ref x1, ref y1);
                }
                textWidth += krec.Width;
                x2 = textWidth; y2 = 0.0;
                Transform(m, ref x2, ref y2);
                LumasPdf.pdfMoveTo(m_PDF, x1, y1);
                LumasPdf.pdfLineTo(m_PDF, x2, y2);
                LumasPdf.pdfSetStrokeColor(m_PDF, (m_Count & 1) != 0 ? clRed : clBlue);
                if (!LumasPdf.pdfStrokePath(m_PDF)) return -1;
                x1 = x2; y1 = y2;
            }
        }
        else
        {
            for (int i = 0; i < Count; i++)
            {
                TTextRecordA srec = (TTextRecordA)Marshal.PtrToStructure(IntPtr.Add(Source, i * RecA), typeof(TTextRecordA));
                int j = 0, last = 0;
                if (srec.Advance != 0f)
                {
                    textWidth -= srec.Advance;
                    x1 = textWidth; y1 = 0.0;
                    Transform(m, ref x1, ref y1);
                }
                int rlen = srec.Length;
                if (srec.Text == IntPtr.Zero) rlen = 0;
                byte[] srcBytes = null;
                if (rlen > 0)
                {
                    srcBytes = new byte[rlen];
                    Marshal.Copy(srec.Text, srcBytes, 0, rlen);
                }
                while (j < rlen)
                {
                    if (srcBytes[j] != 32)
                    {
                        j++;
                    }
                    else
                    {
                        if (j > last)
                        {
                            textWidth += fntGetTextWidthP(m_GState.ActiveFont, IntPtr.Add(srec.Text, last), (uint)(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale);
                            x2 = textWidth; y2 = 0.0;
                            Transform(m, ref x2, ref y2);
                            LumasPdf.pdfMoveTo(m_PDF, x1, y1);
                            LumasPdf.pdfLineTo(m_PDF, x2, y2);
                            LumasPdf.pdfSetStrokeColor(m_PDF, (m_Count & 1) != 0 ? clRed : clBlue);
                            if (!LumasPdf.pdfStrokePath(m_PDF)) return -1;
                        }
                        last = j;
                        j++;
                        while (j < rlen && srcBytes[j] == 32) j++;
                        textWidth += fntGetTextWidthP(m_GState.ActiveFont, IntPtr.Add(srec.Text, last), (uint)(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale);
                        last = j;
                        x1 = textWidth; y1 = 0.0;
                        Transform(m, ref x1, ref y1);
                    }
                }
                x2 = x1; y2 = y1;
                if (j > last)
                {
                    textWidth += fntGetTextWidthP(m_GState.ActiveFont, IntPtr.Add(srec.Text, last), (uint)(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale);
                    x2 = textWidth; y2 = 0.0;
                    Transform(m, ref x2, ref y2);
                    LumasPdf.pdfMoveTo(m_PDF, x1, y1);
                    LumasPdf.pdfLineTo(m_PDF, x2, y2);
                    LumasPdf.pdfSetStrokeColor(m_PDF, (m_Count & 1) != 0 ? clRed : clBlue);
                    if (!LumasPdf.pdfStrokePath(m_PDF)) return -1;
                }
                x1 = x2; y1 = y2;
            }
        }
        m_Count++;
        return 0;
    }

    // ---- parse callback thunks ----
    static int ParseBeginTemplate(IntPtr Data, IntPtr PDFObject, int Handle, ref TPDFRect BBox, IntPtr Matrix)
    { return BeginTemplateImpl(Matrix); }
    static void ParseEndTemplate(IntPtr Data) { RestoreGState(); }
    static void ParseMulMatrix(IntPtr Data, IntPtr PDFObject, ref TCTM Matrix)
    { m_GState.Matrix = MulMatrix(m_GState.Matrix, Matrix); }
    static int ParseRestoreGraphicState(IntPtr Data) { RestoreGState(); return 0; }
    static int ParseSaveGraphicState(IntPtr Data) { SaveGState(); return 0; }
    static void ParseSetCharSpacing(IntPtr Data, IntPtr PDFObject, double Value) { m_GState.CharSpacing = (float)Value; }
    static void ParseSetFont(IntPtr Data, IntPtr PDFObject, int FontType, bool Embedded, IntPtr FontName, int Style, double FontSize, IntPtr Font)
    { SetFontImpl(Font, FontType, FontSize); }
    static void ParseSetTextDrawMode(IntPtr Data, IntPtr PDFObject, int Mode) { m_GState.TextDrawMode = Mode; }
    static void ParseSetTextScale(IntPtr Data, IntPtr PDFObject, double Value) { m_GState.TextScale = (float)Value; }
    static void ParseSetWordSpacing(IntPtr Data, IntPtr PDFObject, double Value) { m_GState.WordSpacing = (float)Value; }
    static int ParseShowTextArrayW(IntPtr Data, IntPtr Source, ref TCTM Matrix, IntPtr Kerning, uint Count, double Width, bool Decoded)
    { return MarkText(Matrix, Source, Kerning, (int)Count, Width, Decoded); }

    static void Main()
    {
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

        IntPtr pdf = LumasPdf.pdfNewPDF();
        m_PDF = pdf;
        m_StackCount = 0;
        m_StackCap = 0;
        m_Count = 0;
        ResetGState();

        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");

        string cmapDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "CMap");
        LumasPdf.pdfSetCMapDirW(pdf, cmapDir, LumasPdfConsts.lcmRecursive | LumasPdfConsts.lcmDelayed);

        LumasPdf.pdfSetImportFlags(pdf, LumasPdfConsts.ifImportAll | LumasPdfConsts.ifImportAsPage);

        string inFile = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "../../../../sample_multipage.pdf"));
        if (LumasPdf.pdfOpenImportFileW(pdf, inFile, (int)LumasPdfConsts.ptOpen, "") < 0)
        {
            Console.WriteLine("Input file \"" + inFile + "\" not found!");
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }
        if (LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0)
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        LumasPdf.pdfFlattenAnnots(pdf, LumasPdfConsts.affMarkupAnnots);
        LumasPdf.pdfFlattenForm(pdf);

        int pageCount = LumasPdf.pdfGetPageCount(pdf);
        for (int i = 1; i <= pageCount; i++)
        {
            LumasPdf.pdfEditPage(pdf, i);
            LumasPdf.pdfSetLineWidth(pdf, 0.5);
            TCInit();
            LumasPdf.pdfParseContent(pdf, IntPtr.Zero, ref stack, (int)LumasPdfConsts.pfNone);
            LumasPdf.pdfEndPage(pdf);
        }

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

        GC.KeepAlive(_beginTemplate); GC.KeepAlive(_endTemplate); GC.KeepAlive(_mulMatrix);
        GC.KeepAlive(_restoreGS); GC.KeepAlive(_saveGS); GC.KeepAlive(_setCharSpacing);
        GC.KeepAlive(_setFont); GC.KeepAlive(_setTextDrawMode); GC.KeepAlive(_setTextScale);
        GC.KeepAlive(_setWordSpacing); GC.KeepAlive(_showTextArrayW);
        LumasPdf.pdfDeletePDF(pdf);
    }
}

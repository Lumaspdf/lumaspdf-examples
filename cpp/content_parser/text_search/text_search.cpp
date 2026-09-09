// text_search -- C++ port of examples\Vb6\content_parser\text_search\text_search.bas
// Imports dynapdf_help.pdf, searches for the Unicode string "PDF" across the
// content stream via pdfParseContent + a flattened CTextSearch state machine,
// and draws yellow multiply-blend rectangles over each match. Prints per-page
// and total hit counts. Output out.pdf.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <cmath>
#include <string>
#include <vector>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static UI32 RGBv(int r,int g,int b){ return (UI32)(r | (g<<8) | (b<<16)); }

// TTextDir
static const SI32 tfNotInitialized = 5;
static const double MAX_LINE_ERROR = 4.0;   // square of the allowed error (2*2)

struct GStateT {
    PFNT   ActiveFont;
    float  CharSpacing;
    float  FontSize;
    SI32   FontType;
    TCTM   Matrix;
    float  SpaceWidth;
    SI32   TextDrawMode;
    float  TextScale;
    float  WordSpacing;
};

static PPDF   m_PDF;
// current "live" graphics state
static PFNT   m_ActiveFont;
static float  m_CharSpacing;
static float  m_FontSize;
static SI32   m_FontType;
static TCTM   m_Matrix;
static float  m_SpaceWidth;
static SI32   m_TextDrawMode;
static float  m_TextScale;
static float  m_WordSpacing;
// graphics-state stack
static std::vector<GStateT> m_Items;
// search / hit-tracking state
static double m_EndX1, m_EndY1, m_EndX4, m_EndY4;
static bool   m_HavePos;
static SI32   m_LastTextDir;
static double m_LastTextInfX, m_LastTextInfY;
static LWCHAR m_OutBuf[32];      // ABI buffer: fixed 2-byte UTF-16 units,
                                 // NOT wchar_t (4 bytes off Windows)
static std::vector<unsigned short> m_SearchChars;
static SI32   m_SearchTextLen;
static SI32   m_SearchPos;        // 0-based; == len means "at the #0 terminator"
static SI32   m_SelCount;
static double m_x1, m_y1, m_x4, m_y4;

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

// ------------------------- matrix / geometry -------------------------
static TCTM MulMatrix(const TCTM& M1, const TCTM& M2){
    TCTM r;
    r.a = M2.a*M1.a + M2.b*M1.c;
    r.b = M2.a*M1.b + M2.b*M1.d;
    r.c = M2.c*M1.a + M2.d*M1.c;
    r.d = M2.c*M1.b + M2.d*M1.d;
    r.x = M2.x*M1.a + M2.y*M1.c + M1.x;
    r.y = M2.x*M1.b + M2.y*M1.d + M1.y;
    return r;
}
static void Transform(const TCTM& M, double& x, double& y){
    double tx = x;
    x = tx*M.a + y*M.c + M.x;
    y = tx*M.b + y*M.d + M.y;
}
static double CalcDistance(double x1,double y1,double x2,double y2){
    double dx=x2-x1, dy=y2-y1; return sqrt(dx*dx+dy*dy);
}
static bool IsPointOnLine(double x,double y,double x0,double y0,double x1,double y1){
    double dx,dy,di;
    x -= x0; y -= y0;
    dx = x1-x0; dy = y1-y0;
    if((dx*dx + dy*dy) == 0.0)
        return (x*x + y*y) < MAX_LINE_ERROR;   // degenerate segment
    di = (x*dx + y*dy) / (dx*dx + dy*dy);
    if(di < 0.0) di = 0.0; else if(di > 1.0) di = 1.0;
    dx = x - di*dx;
    dy = y - di*dy;
    di = dx*dx + dy*dy;
    return di < MAX_LINE_ERROR;
}

// ------------------------- search string -------------------------
static void SetSearchText(const wchar_t* Txt){
    m_SearchTextLen = (SI32)wcslen(Txt);
    m_SearchChars.clear();
    for(SI32 i = 0; i < m_SearchTextLen; i++)
        m_SearchChars.push_back((unsigned short)Txt[i]);
    m_SearchPos = 0;
}
static unsigned short SPCode(){
    if(m_SearchPos >= m_SearchTextLen) return 0;
    return m_SearchChars[m_SearchPos];
}
static void Reset_(){
    m_HavePos = false;
    m_SearchPos = 0;
}
static bool Compare(const LWCHAR* TextPtr, SI32 Len){
    const LWCHAR* endPtr = TextPtr + Len;
    while(TextPtr < endPtr){
        unsigned short wc = (unsigned short)*TextPtr;
        if(SPCode() != wc){
            m_HavePos = false;
            m_SearchPos = 0;
            return false;
        }
        TextPtr++;
        m_SearchPos++;
        if(SPCode() == 0){
            m_SearchPos = 0;
            return TextPtr == endPtr;
        }
    }
    return true;
}

// ------------------------- graphics-state stack -------------------------
static SI32 SaveGState(){
    GStateT s;
    s.ActiveFont=m_ActiveFont; s.CharSpacing=m_CharSpacing; s.FontSize=m_FontSize;
    s.FontType=m_FontType; s.Matrix=m_Matrix; s.SpaceWidth=m_SpaceWidth;
    s.TextDrawMode=m_TextDrawMode; s.TextScale=m_TextScale; s.WordSpacing=m_WordSpacing;
    m_Items.push_back(s);
    return 0;
}
static bool RestoreGState(){
    if(m_Items.empty()) return false;
    GStateT s = m_Items.back(); m_Items.pop_back();
    m_ActiveFont=s.ActiveFont; m_CharSpacing=s.CharSpacing; m_FontSize=s.FontSize;
    m_FontType=s.FontType; m_Matrix=s.Matrix; m_SpaceWidth=s.SpaceWidth;
    m_TextDrawMode=s.TextDrawMode; m_TextScale=s.TextScale; m_WordSpacing=s.WordSpacing;
    return true;
}

// ------------------------- rectangle drawing -------------------------
static void SetStartCoord(const TCTM& Matrix, double x){
    m_x1 = x; m_y1 = 0.0;
    m_x4 = x; m_y4 = m_FontSize;
    Transform(Matrix, m_x1, m_y1);
    Transform(Matrix, m_x4, m_y4);
    m_HavePos = true;
}
static bool DrawRectEx(double x2,double y2,double x3,double y3){
    pdfMoveTo(m_PDF, m_x1, m_y1);
    pdfLineTo(m_PDF, x2, y2);
    pdfLineTo(m_PDF, x3, y3);
    pdfLineTo(m_PDF, m_x4, m_y4);
    m_HavePos = false;
    m_SelCount++;
    return pdfClosePath(m_PDF, fmFill) != 0;
}
static bool DrawRect(const TCTM& Matrix, double EndX){
    double x2=EndX, y2=0.0, x3=EndX, y3=m_FontSize;
    Transform(Matrix, x2, y2);
    Transform(Matrix, x3, y3);
    return DrawRectEx(x2, y2, x3, y3);
}

// ------------------------- init / reset -------------------------
static void InitGState(){
    while(RestoreGState()){}
    m_ActiveFont = nullptr;
    m_CharSpacing = 0.0f;
    m_FontSize = 1.0f;
    m_Matrix = {1.0,0.0,0.0,1.0,0.0,0.0};
    m_SpaceWidth = 0.0f;
    m_TextDrawMode = dmNormal;
    m_TextScale = 100.0f;
    m_WordSpacing = 0.0f;
    m_LastTextDir = tfNotInitialized;
    m_LastTextInfX = 0.0;
    m_LastTextInfY = 0.0;
}
static void TS_Create(){
    m_ActiveFont = nullptr;
    m_CharSpacing = 0.0f;
    m_FontSize = 1.0f;
    m_FontType = ftType1;
    m_Matrix = {1.0,0.0,0.0,1.0,0.0,0.0};
    m_SpaceWidth = 0.0f;
    m_TextDrawMode = dmNormal;
    m_TextScale = 100.0f;
    m_WordSpacing = 0.0f;
    m_Items.clear();
}
static void TS_Init(){
    InitGState();
    Reset_();
    m_SelCount = 0;
}

// ------------------------- text matching core -------------------------
static bool MarkSubString(double& x, const TCTM& Matrix, TTextRecordAPtr SourcePtr){
    TTextRecordA srec = *SourcePtr;
    SI32 i = 0, outLen = 0;
    LBOOL decoded = 0;
    double w = 0.0;
    float spaceWidth2 = -m_SpaceWidth * 6.0f;
    SI32 maxLen = srec.Length;
    const char* srcPtr = srec.Text;

    if(srec.Advance < -m_SpaceWidth){
        // If the distance is too large we assume no space was emulated here.
        if((srec.Advance > spaceWidth2) && (SPCode() == 32)){
            if(!m_HavePos){
                SetStartCoord(Matrix, x);
                m_SearchPos++;
                if(SPCode() == 0){
                    if(!DrawRect(Matrix, x - srec.Advance)) return false;
                    Reset_();
                }
            } else if(SPCode() == 0){
                if(!DrawRect(Matrix, 0.0)) return false;
                Reset_();
            } else {
                m_SearchPos++;
            }
        } else {
            Reset_();
        }
    }
    x = x - srec.Advance;
    while(i < maxLen){
        UI32 consumed = fntTranslateRawCode(m_ActiveFont, srcPtr + i, (UI32)(maxLen - i), &w, m_OutBuf, &outLen, &decoded, m_CharSpacing, m_WordSpacing, m_TextScale);
        if((SI32)consumed <= 0) break;     // safety: never let i stall
        i += (SI32)consumed;
        // Skip this text record if the text cannot be converted to Unicode.
        if(decoded == 0) return true;
        // outLen is always > 0 if decoded is true.
        if(Compare(m_OutBuf, outLen)){
            if(!m_HavePos) SetStartCoord(Matrix, x);
            x = x + w;
            if(m_SearchPos == 0){
                if(!DrawRect(Matrix, x - m_CharSpacing)) return false;
            }
        } else {
            x = x + w;
        }
    }
    return true;
}

static SI32 MarkText(TCTM* MatrixP, TTextRecordAPtr SourcePtr, UI32 Count, double Width_){
    double x, x1=0.0, y1=0.0, x2=0.0, y2=m_FontSize, x3, y3, distance, spaceWidth;
    SI32 textDir;
    TCTM m = MulMatrix(m_Matrix, *MatrixP);
    Transform(m, x1, y1);
    Transform(m, x2, y2);
    if(y1 == y2) textDir = ((x1 > x2 ? 1 : 0) + 1) * 2;
    else         textDir = (y1 > y2 ? 1 : 0);

    // Short-circuit reproduced explicitly (IsPointOnLine divides).
    bool wrongLine = false;
    if(textDir != m_LastTextDir) wrongLine = true;
    else if(!IsPointOnLine(x1, y1, m_EndX1, m_EndY1, m_LastTextInfX, m_LastTextInfY)) wrongLine = true;

    if(wrongLine){
        m_LastTextInfX = 1000000.0;
        m_LastTextInfY = 0.0;
        Transform(m, m_LastTextInfX, m_LastTextInfY);
        Reset_();
    } else {
        x3 = m_SpaceWidth; y3 = 0.0;
        Transform(m, x3, y3);
        spaceWidth = CalcDistance(x1, y1, x3, y3);
        distance   = CalcDistance(m_EndX1, m_EndY1, x1, y1);
        if(distance > spaceWidth){
            if((distance < spaceWidth * 6.0) && (SPCode() == 32)){
                if(!m_HavePos){
                    m_HavePos = true;
                    m_SearchPos++;
                    if(SPCode() == 0){
                        m_x1 = m_EndX1; m_y1 = m_EndY1;
                        m_x4 = m_EndX4; m_y4 = m_EndY4;
                        if(!DrawRectEx(x1, y1, x2, y2)) return -1;
                        Reset_();
                    }
                } else if(SPCode() == 32){
                    if(!DrawRectEx(x1, y1, x2, y2)) return -1;
                    Reset_();
                } else {
                    m_SearchPos++;
                }
            } else {
                Reset_();
            }
        }
    }

    x = 0.0;
    TTextRecordAPtr recPtr = SourcePtr;
    for(UI32 i = 0; i < Count; i++){
        if(!MarkSubString(x, m, recPtr)) return -1;
        recPtr++;
    }
    m_LastTextDir = textDir;
    m_EndX1 = Width_; m_EndY1 = 0.0;
    m_EndX4 = 0.0;    m_EndY4 = m_FontSize;
    Transform(m, m_EndX1, m_EndY1);
    Transform(m, m_EndX4, m_EndY4);
    return 0;
}

// ------------------------- CTextSearch helpers -------------------------
static SI32 BeginTemplate(TPDFRect* BBox, PCTM MatrixPtr){
    if(SaveGState() < 0) return -1;
    if(MatrixPtr) m_Matrix = MulMatrix(m_Matrix, *MatrixPtr);
    return 0;
}
static void TS_SetFont(PFNT IFont, SI32 FontType, double FontSize){
    m_ActiveFont = IFont;
    m_FontSize = (float)FontSize;
    m_FontType = FontType;
    m_SpaceWidth = (float)(fntGetSpaceWidth(IFont, FontSize) * 0.5);
}

// ------------------------- parse callbacks -------------------------
static SI32 PDF_CALL cbBeginTemplate(void* Data, void* PDFObject, SI32 Handle, TPDFRect* BBox, PCTM Matrix){ return BeginTemplate(BBox, Matrix); }
static void PDF_CALL cbEndTemplate(void* Data){ RestoreGState(); }
static void PDF_CALL cbMulMatrix(void* Data, void* PDFObject, TCTM* Matrix){ m_Matrix = MulMatrix(m_Matrix, *Matrix); }
static SI32 PDF_CALL cbRestoreGS(void* Data){ RestoreGState(); return 0; }
static SI32 PDF_CALL cbSaveGS(void* Data){ return SaveGState(); }
static void PDF_CALL cbSetCharSpacing(void* Data, void* PDFObject, double Value){ m_CharSpacing = (float)Value; }
static void PDF_CALL cbSetFont(void* Data, void* PDFObject, TFontType FontType, LBOOL Embedded, const char* FontName, TFStyle Style, double FontSize, PFNT Font){ TS_SetFont(Font, (SI32)FontType, FontSize); }
static void PDF_CALL cbSetTextDrawMode(void* Data, void* PDFObject, TDrawMode Mode){ m_TextDrawMode = (SI32)Mode; }
static void PDF_CALL cbSetTextScale(void* Data, void* PDFObject, double Value){ m_TextScale = (float)Value; }
static void PDF_CALL cbSetWordSpacing(void* Data, void* PDFObject, double Value){ m_WordSpacing = (float)Value; }
static SI32 PDF_CALL cbShowTextArrayA(void* Data, char* Obj, TCTM* Matrix, TTextRecordAPtr Source, UI32 Count, double Width){
    return MarkText(Matrix, Source, Count, Width);
}

int main(int argc, char** argv){
    SI32 selCount = 0;
    TS_Create();

    TPDFParseInterface stack{};
    stack.BeginTemplate      = cbBeginTemplate;
    stack.EndTemplate        = cbEndTemplate;
    stack.MulMatrix          = cbMulMatrix;
    stack.RestoreGraphicState= cbRestoreGS;
    stack.SaveGraphicState   = cbSaveGS;
    stack.SetCharSpacing     = cbSetCharSpacing;
    stack.SetFont            = cbSetFont;
    stack.SetTextDrawMode    = cbSetTextDrawMode;
    stack.SetTextScale       = cbSetTextScale;
    stack.SetWordSpacing     = cbSetWordSpacing;
    stack.ShowTextArrayA     = cbShowTextArrayA;   // this example uses the A slot

    m_PDF = pdfNewPDF();
    pdfSetOnErrorProc(m_PDF, nullptr, ErrProc);
    pdfCreateNewPDFA(m_PDF, "");

    std::string cmapDir = exeDir(argv[0]) + "/CMap";
    pdfSetCMapDirA(m_PDF, cmapDir.c_str(), lcmRecursive | lcmDelayed);

    pdfSetImportFlags(m_PDF, ifImportAll | ifImportAsPage);

    const char* inFile = LUMAS_REPO_ROOT "/dynapdf_help.pdf";
    if(pdfOpenImportFileA(m_PDF, inFile, ptOpen, "") < 0){
        printf("Input file \"%s\" not found!\n", inFile);
        pdfDeletePDF(m_PDF);
        return 0;
    }
    if(pdfImportPDFFile(m_PDF, 1, 1.0, 1.0) < 0){ pdfDeletePDF(m_PDF); return 0; }

    pdfFlattenAnnots(m_PDF, affMarkupAnnots);
    pdfFlattenForm(m_PDF);

    // The search text must be defined in Unicode.
    SetSearchText(L"PDF");

    // Draw rectangles at the match positions with blend mode multiply so the
    // text in the background stays visible.
    TPDFExtGState g{};
    pdfInitExtGState(&g);
    g.BlendMode = bmMultiply;
    UI32 gs = pdfCreateExtGState(m_PDF, &g);

    for(SI32 i = 1; i <= pdfGetPageCount(m_PDF); i++){
        pdfEditPage(m_PDF, i);
        pdfSetExtGState(m_PDF, gs);
        pdfSetFillColor(m_PDF, RGBv(255, 255, 0));
        TS_Init();
        pdfParseContent(m_PDF, nullptr, &stack, pfNone);
        pdfEndPage(m_PDF);
        if(m_SelCount > 0){
            selCount += m_SelCount;
            printf("Found string on Page: %d %d times!\n", (int)i, (int)m_SelCount);
        }
    }

    std::string outFile;
    if(pdfHaveOpenDoc(m_PDF) != 0){
        outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(m_PDF, outFile.c_str()) == 0){ pdfDeletePDF(m_PDF); return 0; }
    }
    if(pdfCloseFile(m_PDF) != 0)
        printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
    printf("\nFound string in the file %d times!\n", (int)selCount);
    pdfDeletePDF(m_PDF);
    return 0;
}

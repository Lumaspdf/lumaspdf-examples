// text_extraction2 -- C++ port of
//   examples\Vb6\content_parser\text_extraction2\text_extraction2.bas
// Extracts the text of a PDF by driving pdfParseContent() with a
// TPDFParseInterface of stdcall callbacks. The CPDFToText / CStack helpers are
// flattened into module-level globals (exactly one parser instance exists) and
// the Data pointer is ignored. Output is out.txt as UTF-16LE (with BOM).
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <cstring>
#include <cmath>
#include <string>
#include <vector>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

// TTextDir
static const SI32 tfNotInitialized = 5;
static const double MAX_LINE_ERROR = 4.0;   // square of the allowed error (2*2)

struct TGState {
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

static PPDF  m_PDF;
static FILE* m_File;
static TGState m_GState;
static SI32   m_LastTextDir;
static double m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY;
static std::vector<TGState> m_Stack;

// ------------------------- error callback -------------------------
static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

// ------------------------- output helpers -------------------------
static void WriteWChars(const wchar_t* p, size_t count){
    if(!p || count == 0) return;
    fwrite(p, sizeof(wchar_t), count, m_File);
}
static void WriteWStr(const wchar_t* s){ WriteWChars(s, wcslen(s)); }

// ------------------------- CStack -------------------------
static bool StackRestore(TGState& F){
    if(!m_Stack.empty()){ F = m_Stack.back(); m_Stack.pop_back(); return true; }
    return false;
}
static SI32 StackSave(const TGState& F){ m_Stack.push_back(F); return 0; }

// ------------------------- matrix helpers -------------------------
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
    di = (x*dx + y*dy) / (dx*dx + dy*dy);
    if(di < 0.0) di = 0.0; else if(di > 1.0) di = 1.0;
    dx = x - di*dx;
    dy = y - di*dy;
    di = dx*dx + dy*dy;
    return di < MAX_LINE_ERROR;
}

// ------------------------- CPDFToText (flattened) -------------------------
static bool DoRestoreGState(){ return StackRestore(m_GState); }
static SI32 DoSaveGState(){ return StackSave(m_GState); }

static void ResetGState(){
    m_GState.ActiveFont = nullptr;
    m_GState.CharSpacing = 0.0f;
    m_GState.FontSize = 1.0f;
    m_GState.FontType = ftType1;
    m_GState.Matrix = {1.0,0.0,0.0,1.0,0.0,0.0};
    m_GState.SpaceWidth = 0.0f;
    m_GState.TextDrawMode = dmNormal;
    m_GState.TextScale = 100.0f;
    m_GState.WordSpacing = 0.0f;
}
static void DoInit(){
    while(DoRestoreGState()){}
    ResetGState();
    m_LastTextDir = tfNotInitialized;
    m_LastTextEndX = m_LastTextEndY = m_LastTextInfX = m_LastTextInfY = 0.0;
}
static void DoSetFont(PFNT IFont, SI32 FontType, double FontSize){
    m_GState.ActiveFont = IFont;
    m_GState.FontSize = (float)FontSize;
    m_GState.FontType = FontType;
    m_GState.SpaceWidth = (float)fntGetSpaceWidth(IFont, FontSize);
    if(FontSize < 0.0) m_GState.SpaceWidth = -m_GState.SpaceWidth;
}
static void DoWritePageIdentifier(SI32 PageNum){
    if(PageNum > 1) WriteWStr(L"\r\n");
    wchar_t buf[128];
    swprintf(buf, 128, L"%%----------------------- Page %d -----------------------------\r\n", (int)PageNum);
    WriteWStr(buf);
}

// ------------------------- text reconstruction -------------------------
static SI32 DoAddText(TCTM* Matrix, TTextRecordWPtr Kerning, UI32 Count, double Widen, LBOOL Decoded){
    if(Decoded == 0) return 0;

    double x1=0.0, y1=0.0, x2=0.0, y2=m_GState.FontSize, x3, y3;
    TCTM m = MulMatrix(m_GState.Matrix, *Matrix);
    Transform(m, x1, y1);          // Start point of the text record
    Transform(m, x2, y2);          // Second point -> text direction
    SI32 textDir;
    if(y1 == y2) textDir = ((x1 > x2 ? 1 : 0) + 1) * 2;
    else         textDir = (y1 > y2 ? 1 : 0);

    if((textDir != m_LastTextDir) ||
       (!IsPointOnLine(x1, y1, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY))){
        m_LastTextInfX = 1000000.0;
        m_LastTextInfY = 0.0;
        Transform(m, m_LastTextInfX, m_LastTextInfY);
        if(m_LastTextDir != tfNotInitialized) WriteWStr(L"\r\n");
    } else {
        x3 = m_GState.SpaceWidth; y3 = 0.0;
        Transform(m, x3, y3);
        double spaceWidth = CalcDistance(x1, y1, x3, y3);
        double distance   = CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1);
        if(distance > spaceWidth) WriteWStr(L" ");
    }

    float spw = -m_GState.SpaceWidth * 0.5f;
    for(UI32 i = 0; i < Count; i++){
        TTextRecordW rec = Kerning[i];
        if(rec.Advance < spw) WriteWStr(L" ");
        WriteWChars((const wchar_t*)rec.Text, (size_t)rec.Length);
    }

    m_LastTextEndX = Widen + spw;   // spw is negative
    m_LastTextEndY = 0.0;
    m_LastTextDir = textDir;
    Transform(m, m_LastTextEndX, m_LastTextEndY);
    return 0;
}

// ------------------------- parse callbacks -------------------------
static SI32 PDF_CALL cbBeginTemplate(void* Data, void* PDFObject, SI32 Handle, TPDFRect* BBox, PCTM Matrix){
    if(DoSaveGState() < 0) return -1;
    if(Matrix) m_GState.Matrix = MulMatrix(m_GState.Matrix, *Matrix);
    return 0;
}
static void PDF_CALL cbEndTemplate(void* Data){ DoRestoreGState(); }
static void PDF_CALL cbMulMatrix(void* Data, void* PDFObject, TCTM* Matrix){ m_GState.Matrix = MulMatrix(m_GState.Matrix, *Matrix); }
static SI32 PDF_CALL cbRestoreGS(void* Data){ DoRestoreGState(); return 0; }
static SI32 PDF_CALL cbSaveGS(void* Data){ DoSaveGState(); return 0; }
static void PDF_CALL cbSetCharSpacing(void* Data, void* PDFObject, double Value){ m_GState.CharSpacing = (float)Value; }
static void PDF_CALL cbSetFont(void* Data, void* PDFObject, TFontType FontType, LBOOL Embedded, const char* FontName, TFStyle Style, double FontSize, PFNT Font){ DoSetFont(Font, (SI32)FontType, FontSize); }
static void PDF_CALL cbSetTextDrawMode(void* Data, void* PDFObject, TDrawMode Mode){ m_GState.TextDrawMode = (SI32)Mode; }
static void PDF_CALL cbSetTextScale(void* Data, void* PDFObject, double Value){ m_GState.TextScale = (float)Value; }
static void PDF_CALL cbSetWordSpacing(void* Data, void* PDFObject, double Value){ m_GState.WordSpacing = (float)Value; }
static SI32 PDF_CALL cbShowTextArrayW(void* Data, TTextRecordAPtr Source, TCTM* Matrix, TTextRecordWPtr Kerning, UI32 Count, double Width, LBOOL Decoded){
    return DoAddText(Matrix, Kerning, Count, Width, Decoded);
}

int main(int argc, char** argv){
    m_PDF = pdfNewPDF();
    pdfSetOnErrorProc(m_PDF, nullptr, ErrProc);
    pdfCreateNewPDFA(m_PDF, "");

    std::string cmapDir = exeDir(argv[0]) + "/CMap";
    pdfSetCMapDirA(m_PDF, cmapDir.c_str(), lcmRecursive | lcmDelayed);

    pdfSetImportFlags(m_PDF, ifImportAll | ifImportAsPage);

    const char* inFile = LUMAS_REPO_ROOT "/sample_multipage.pdf";
    if(pdfOpenImportFileA(m_PDF, inFile, ptOpen, "") < 0){
        printf("Input file \"%s\" not found!\n", inFile);
        pdfDeletePDF(m_PDF);
        return 0;
    }
    if(pdfImportPDFFile(m_PDF, 1, 1.0, 1.0) < 0){ pdfDeletePDF(m_PDF); return 0; }

    pdfFlattenAnnots(m_PDF, affMarkupAnnots);
    pdfFlattenForm(m_PDF);

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
    stack.ShowTextArrayW     = cbShowTextArrayW;

    std::string outFile = exeDir(argv[0]) + "/out.txt";
    m_File = fopen(outFile.c_str(), "wb");
    if(!m_File){ pdfDeletePDF(m_PDF); return 0; }
    unsigned char bom[2] = {0xFF, 0xFE};   // UTF-16LE BOM
    fwrite(bom, 1, 2, m_File);

    for(SI32 i = 1; i <= pdfGetPageCount(m_PDF); i++){
        pdfEditPage(m_PDF, i);
        DoInit();
        DoWritePageIdentifier(i);
        pdfParseContent(m_PDF, nullptr, &stack, pfNone);
        pdfEndPage(m_PDF);
    }
    fclose(m_File);

    printf("Text successfully extracted to %s\n", outFile.c_str());
    pdfDeletePDF(m_PDF);
    return 0;
}

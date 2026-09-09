// text_extraction -- C++ port of examples\Vb6\text_extraction\text_extraction.bas
// Imports a PDF and extracts its text with GetPageText()/TPDFStack, rebuilding
// text lines and word boundaries by transforming each text record to user
// space. Output is written to out.txt as UTF-16LE (with BOM).
#include "apputil.h"
#include <cmath>
#include <vector>

// TTextDir
static const SI32 tfNotInitialized = 5;
static const double MAX_LINE_ERROR = 4.0;   // square of the allowed error (2 * 2)

static PPDF      m_PDF;
static FILE*     m_File;
static TPDFStack m_Stack;
static SI32      m_LastTextDir;
static double    m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY;

// template handle list
static std::vector<SI32> m_Templates;

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;   // We try to continue if an error occurs
}

// ------------------------- output helpers -------------------------
// out.txt is UTF-16LE (2-byte units; the BOM is written below), and LWCHAR is
// 2 bytes on EVERY platform -- so the stride must be sizeof(LWCHAR), never
// sizeof(wchar_t). It was the latter: a harmless no-op on Windows (wchar_t is
// 2 bytes there) and wrong TWICE off Windows. The engine hands back 2-byte
// text, so writing it at a 4-byte stride READ PAST THE BUFFER -- about half of
// every emitted record was allocator debris (75.7% NUL on macOS, live heap
// fragments on Linux) -- and the result could not be decoded as the UTF-16LE
// its own BOM declares. Every Linux/macOS out.txt came out exactly 2n-2 bytes.
//
// The example's own decorations are pure ASCII, so they are widened here
// instead of being built with swprintf/wchar_t, which is UTF-32 off Windows.
// lumaspdf.h states both rules outright: write LUMAS_TEXT() not L"...", and
// use lumas_u16len() not wcslen() (wcslen takes wchar_t* and is wrong here).
static void WriteAscii(const char* s){
    if(!s) return;
    for(; *s; ++s){ LWCHAR u = (LWCHAR)(unsigned char)*s; fwrite(&u, sizeof(LWCHAR), 1, m_File); }
}
static void WriteWCharsFromPtr(const LWCHAR* p, SI32 count){
    if(!p || count <= 0) return;
    fwrite(p, sizeof(LWCHAR), (size_t)count, m_File);
}

// ------------------------- CIntList -------------------------
static void ListClear(){ m_Templates.clear(); }
static void ListAdd(SI32 v){ m_Templates.push_back(v); }
static SI32 ListFind(SI32 v){
    for(size_t i = 0; i < m_Templates.size(); i++) if(m_Templates[i] == v) return (SI32)i;
    return -1;
}

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

// ------------------------- text reconstruction -------------------------
static void AddText(){
    double x1=0.0, y1=0.0, x2=0.0, y2=m_Stack.FontSize, x3, y3;
    TCTM m = MulMatrix(m_Stack.ctm, m_Stack.tm);
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
        if(m_LastTextDir != tfNotInitialized) WriteAscii("\r\n");
    } else {
        x3 = m_Stack.SpaceWidth; y3 = 0.0;
        Transform(m, x3, y3);
        double spaceWidth = CalcDistance(x1, y1, x3, y3);
        double distance   = CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1);
        if(distance > spaceWidth) WriteAscii(" ");
    }

    float spw = -m_Stack.SpaceWidth * 0.5f;
    for(UI32 i = 0; i < m_Stack.KerningCount; i++){
        TTextRecordW rec = m_Stack.Kerning[i];
        if(rec.Advance < spw) WriteAscii(" ");
        WriteWCharsFromPtr(rec.Text, rec.Length);
    }

    m_LastTextEndX = m_Stack.TextWidth + spw;   // spw is negative
    m_LastTextEndY = 0.0;
    m_LastTextDir = textDir;
    Transform(m, m_LastTextEndX, m_LastTextEndY);
}

static void ParseText(){
    bool haveMore = (pdfGetPageText(m_PDF, &m_Stack) != 0);
    if((!haveMore) && (m_Stack.TextLen == 0)) return;
    AddText();
    if(haveMore){
        while(pdfGetPageText(m_PDF, &m_Stack) != 0) AddText();
    }
}

static void ParseTemplates(){
    SI32 tmplCount = pdfGetTemplCount(m_PDF);
    for(SI32 i = 0; i < tmplCount; i++){
        if(pdfEditTemplate(m_PDF, i) == 0) return;
        SI32 tmpl = pdfGetTemplHandle(m_PDF);
        if(ListFind(tmpl) < 0){
            ListAdd(tmpl);
            if(pdfInitStack(m_PDF, &m_Stack) == 0) return;
            ParseText();
            SI32 tmplCount2 = pdfGetTemplCount(m_PDF);
            for(SI32 j = 0; j < tmplCount2; j++) ParseTemplates();
            pdfEndTemplate(m_PDF);
        } else {
            pdfEndTemplate(m_PDF);
        }
    }
}

static void ParsePage(){
    ListClear();
    if(pdfInitStack(m_PDF, &m_Stack) == 0){
        printf("%s\n", pdfGetErrorMessage(m_PDF));
        return;
    }
    m_LastTextEndX = m_LastTextEndY = 0.0;
    m_LastTextDir = tfNotInitialized;
    m_LastTextInfX = m_LastTextInfY = 0.0;
    ParseText();
    ParseTemplates();
}

int main(){
    ChdirToExe();
    m_PDF = pdfNewPDF();
    pdfCreateNewPDFA(m_PDF, "");          // We do not produce a PDF file in this example
    pdfSetOnErrorProc(m_PDF, 0, ErrProc);

    pdfSetCMapDirA(m_PDF, "CMap", lcmRecursive | lcmDelayed);

    pdfSetImportFlags(m_PDF, ifImportAll | ifImportAsPage);
    const char* inFile = "in.pdf";
    if(pdfOpenImportFileA(m_PDF, inFile, ptOpen, "") < 0){
        pdfDeletePDF(m_PDF);
        return 0;
    }
    pdfImportPDFFile(m_PDF, 1, 1.0, 1.0);
    pdfCloseImportFile(m_PDF);

    pdfFlattenAnnots(m_PDF, affMarkupAnnots);
    pdfFlattenForm(m_PDF);

    m_File = fopen("out.txt", "wb");
    if(!m_File){ pdfDeletePDF(m_PDF); return 0; }
    unsigned char bom[2] = {0xFF, 0xFE};   // UTF-16LE BOM
    fwrite(bom, 1, 2, m_File);

    for(SI32 i = 1; i <= pdfGetPageCount(m_PDF); i++){
        pdfEditPage(m_PDF, i);
        // snprintf into a NARROW buffer, then widen: swprintf writes wchar_t,
        // which is UTF-32 off Windows and would corrupt this UTF-16LE file.
        char buf[128];
        int n = snprintf(buf, sizeof(buf), "%s%%----------------------- Page %d -----------------------------\r\n",
                         (i > 1 ? "\r\n" : ""), (int)i);
        if(n > 0) WriteAscii(buf);
        ParsePage();
        pdfEndPage(m_PDF);
    }
    fclose(m_File);

    printf("Text successfully extracted to out.txt\n");
    pdfDeletePDF(m_PDF);
    return 0;
}

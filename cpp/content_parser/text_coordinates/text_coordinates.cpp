// text_coordinates -- C++ port of
//   examples\Vb6\content_parser\text_coordinates\text_coordinates.bas
// Imports dynapdf_help.pdf, then for every page runs pdfParseContent with a
// callback interface. The MarkText callback draws lines under each text record
// to visualise the computed text coordinates, alternating blue/red. The OO
// CTextCoordinates / CStack are flattened to module-level globals. Output out.pdf.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>
#include <vector>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

// VCL COLORREF colours.
static const UI32 clRed  = 0x000000FF;
static const UI32 clBlue = 0x00FF0000;

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

static PPDF   m_PDF;
static SI32   m_Count;
static TGState m_GState;
static std::vector<TGState> m_Stack;

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
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
static void Transform(const TCTM& m, double& x, double& y){
    double tx = x;
    x = tx*m.a + y*m.c + m.x;
    y = tx*m.b + y*m.d + m.y;
}

// ------------------------- stack -------------------------
static bool RestoreGState(){
    if(!m_Stack.empty()){ m_GState = m_Stack.back(); m_Stack.pop_back(); return true; }
    return false;
}
static SI32 SaveGState(){ m_Stack.push_back(m_GState); return 0; }

// ------------------------- CTextCoordinates -------------------------
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
static void TCInit(){
    while(RestoreGState()){}
    m_Count = 0;
    ResetGState();
}
static void SetFontImpl(PFNT IFont, SI32 FontType, double FontSize){
    m_GState.ActiveFont = IFont;
    m_GState.FontSize = (float)FontSize;
    m_GState.FontType = FontType;
    m_GState.SpaceWidth = (float)fntGetSpaceWidth(IFont, FontSize);
}

static void SetLineColor(){
    if(m_Count & 1) pdfSetStrokeColor(m_PDF, clRed);
    else            pdfSetStrokeColor(m_PDF, clBlue);
}

// CTextCoordinates.MarkText
static SI32 MarkText(TCTM* Matrix, TTextRecordAPtr Source, TTextRecordWPtr Kerning, UI32 Count, double AWidth, LBOOL Decoded){
    if(Decoded == 0) return 0;

    double x1=0.0, y1=0.0, x2, y2, textWidth;
    TCTM m = MulMatrix(m_GState.Matrix, *Matrix);
    Transform(m, x1, y1);          // Start point of the text record

    textWidth = 0.0;
    if(m_GState.FontType == ftType0){
        // Word spacing must be ignored if a CID font is selected!
        for(UI32 i = 0; i < Count; i++){
            TTextRecordW krec = Kerning[i];
            if(krec.Advance != 0.0f){
                textWidth -= krec.Advance;
                x1 = textWidth; y1 = 0.0;
                Transform(m, x1, y1);
            }
            textWidth += krec.Width;
            x2 = textWidth; y2 = 0.0;
            Transform(m, x2, y2);
            pdfMoveTo(m_PDF, x1, y1);
            pdfLineTo(m_PDF, x2, y2);
            SetLineColor();
            if(pdfStrokePath(m_PDF) == 0) return -1;
            x1 = x2; y1 = y2;
        }
    } else {
        // Draw lines under segments separated by space characters so that word
        // spacing is handled correctly.
        x2 = 0.0; y2 = 0.0;
        for(UI32 i = 0; i < Count; i++){
            TTextRecordA srec = Source[i];
            SI32 j = 0, last = 0;
            if(srec.Advance != 0.0f){
                textWidth -= srec.Advance;
                x1 = textWidth; y1 = 0.0;
                Transform(m, x1, y1);
            }
            SI32 rlen = srec.Length;
            if(srec.Text == nullptr) rlen = 0;
            const unsigned char* src = (const unsigned char*)srec.Text;
            while(j < rlen){
                if(src[j] != 32){
                    j++;
                } else {
                    if(j > last){
                        textWidth += fntGetTextWidth(m_GState.ActiveFont, srec.Text + last, (UI32)(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale);
                        x2 = textWidth; y2 = 0.0;
                        Transform(m, x2, y2);
                        pdfMoveTo(m_PDF, x1, y1);
                        pdfLineTo(m_PDF, x2, y2);
                        SetLineColor();
                        if(pdfStrokePath(m_PDF) == 0) return -1;
                    }
                    last = j;
                    j++;
                    while(j < rlen && src[j] == 32) j++;
                    textWidth += fntGetTextWidth(m_GState.ActiveFont, srec.Text + last, (UI32)(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale);
                    last = j;
                    x1 = textWidth; y1 = 0.0;
                    Transform(m, x1, y1);
                }
            }
            if(j > last){
                textWidth += fntGetTextWidth(m_GState.ActiveFont, srec.Text + last, (UI32)(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale);
                x2 = textWidth; y2 = 0.0;
                Transform(m, x2, y2);
                pdfMoveTo(m_PDF, x1, y1);
                pdfLineTo(m_PDF, x2, y2);
                SetLineColor();
                if(pdfStrokePath(m_PDF) == 0) return -1;
            }
            x1 = x2; y1 = y2;
        }
    }
    m_Count++;
    return 0;
}

// ------------------------- parse callbacks -------------------------
static SI32 PDF_CALL cbBeginTemplate(void* Data, void* PDFObject, SI32 Handle, TPDFRect* BBox, PCTM Matrix){
    if(SaveGState() < 0) return -1;
    if(Matrix) m_GState.Matrix = MulMatrix(m_GState.Matrix, *Matrix);
    return 0;
}
static void PDF_CALL cbEndTemplate(void* Data){ RestoreGState(); }
static void PDF_CALL cbMulMatrix(void* Data, void* PDFObject, TCTM* Matrix){ m_GState.Matrix = MulMatrix(m_GState.Matrix, *Matrix); }
static SI32 PDF_CALL cbRestoreGS(void* Data){ RestoreGState(); return 0; }
static SI32 PDF_CALL cbSaveGS(void* Data){ SaveGState(); return 0; }
static void PDF_CALL cbSetCharSpacing(void* Data, void* PDFObject, double Value){ m_GState.CharSpacing = (float)Value; }
static void PDF_CALL cbSetFont(void* Data, void* PDFObject, TFontType FontType, LBOOL Embedded, const char* FontName, TFStyle Style, double FontSize, PFNT Font){ SetFontImpl(Font, (SI32)FontType, FontSize); }
static void PDF_CALL cbSetTextDrawMode(void* Data, void* PDFObject, TDrawMode Mode){ m_GState.TextDrawMode = (SI32)Mode; }
static void PDF_CALL cbSetTextScale(void* Data, void* PDFObject, double Value){ m_GState.TextScale = (float)Value; }
static void PDF_CALL cbSetWordSpacing(void* Data, void* PDFObject, double Value){ m_GState.WordSpacing = (float)Value; }
static SI32 PDF_CALL cbShowTextArrayW(void* Data, TTextRecordAPtr Source, TCTM* Matrix, TTextRecordWPtr Kerning, UI32 Count, double Width, LBOOL Decoded){
    return MarkText(Matrix, Source, Kerning, Count, Width, Decoded);
}

int main(int argc, char** argv){
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

    PPDF pdf = pdfNewPDF();
    m_PDF = pdf;
    m_Count = 0;
    ResetGState();

    pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    std::string cmapDir = exeDir(argv[0]) + "/CMap";
    pdfSetCMapDirA(pdf, cmapDir.c_str(), lcmRecursive | lcmDelayed);

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);

    const char* inFile = LUMAS_REPO_ROOT "/dynapdf_help.pdf";
    if(pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0){
        printf("Input file \"%s\" not found!\n", inFile);
        pdfDeletePDF(pdf);
        return 0;
    }
    if(pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0){ pdfDeletePDF(pdf); return 0; }

    pdfFlattenAnnots(pdf, affMarkupAnnots);
    pdfFlattenForm(pdf);

    for(SI32 i = 1; i <= pdfGetPageCount(pdf); i++){
        pdfEditPage(pdf, i);
        pdfSetLineWidth(pdf, 0.5);
        TCInit();
        pdfParseContent(pdf, nullptr, &stack, pfNone);
        pdfEndPage(pdf);
    }

    std::string outFile;
    if(pdfHaveOpenDoc(pdf) != 0){
        outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){ pdfDeletePDF(pdf); return 0; }
    }
    if(pdfCloseFile(pdf) != 0)
        printf("PDF file \"%s\" successfully created!\n", outFile.c_str());

    pdfDeletePDF(pdf);
    return 0;
}

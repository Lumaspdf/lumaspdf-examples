// measure_lines -- C++ port of examples\Vb6\annotations\measure_lines\measure_lines.bas
// Two dimension/measure line annotations on a rotated rectangle, configured
// through a TLineAnnotParms record.
#include <lumaspdf.h>
#include <cstdio>
#include <string>

// The Delphi original passes Delphi `string` (UnicodeString), so LineAnnot
// resolves to the WIDE overload; the *A twin used here before wrote
// PDFDocEncoding where the reference writes a UTF-16BE PDF text string. LWCHAR
// is wchar_t on Windows and char16_t elsewhere, so the literal must go through
// the header's own LUMAS_TEXT() macro -- a bare u"..." does not convert to
// LWCHAR* under MSVC, and a bare L"..." is 4 bytes wide off Windows.
#define W_(s) ((LWCHAR*)LUMAS_TEXT(s))

// Widen an ASCII snprintf result into an LWCHAR buffer. Deliberately hand-rolled
// rather than swprintf/mbstowcs: those produce wchar_t, which is 4 bytes wide off
// Windows and would feed the W entry points half-width garbage (see the LWCHAR
// hazard note at the top of wrappers/c/lumaspdf.h).
static void WidenAscii(const char* src, LWCHAR* dst, size_t cap){
    size_t i = 0;
    for(; src[i] && i + 1 < cap; ++i) dst[i] = (LWCHAR)(unsigned char)src[i];
    dst[i] = 0;
}

static const UI32 clCream = 15793151;
static const UI32 clBlack = 0;

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    return 0;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFW(pdf, W_(""));

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);

    double w = 300.0;
    double h = 100.0;
    double x = pdfGetPageWidth(pdf) / 2;
    double y = pdfGetPageHeight(pdf) / 2;

    // Save the graphics state because the coordinate system will be rotated.
    pdfSaveGraphicState(pdf);

    pdfSetGStateFlags(pdf, (TGStateFlags)gfRealTopDownCoords, 0);    // This simplifies the handling a little bit.
    pdfRotateCoords(pdf, -30.0, x, y);

    x = -w / 2;
    y = -h / 2;

    pdfSetFillColor(pdf, clCream);
    pdfRectangle(pdf, x, y, w, h, fmFillStroke);

    char   txt[64];
    LWCHAR wtxt[64];
    snprintf(txt, sizeof(txt), "%.1f", w);
    WidenAscii(txt, wtxt, 64);
    SI32 a = pdfLineAnnotW(pdf, x, y, x + w, y, 1.0, leClosedArrow, leClosedArrow, clBlack, clBlack, csDeviceRGB, W_("This is a measure line"), W_("Measure Line"), wtxt);

    TLineAnnotParms p{};
    p.StructSize = sizeof(p);
    p.Caption = 1;              // The parameter Content of LineAnnot() is used as caption.
    p.LeaderLineLen = 10.0f;
    p.LeaderLineExtend = 4.0f;  // Try different values to understand what these parameters change.
    p.LeaderLineOffset = 2.0f;
    pdfSetLineAnnotParms(pdf, a, -1, 0.0, &p);

    snprintf(txt, sizeof(txt), "%.1f", h);
    WidenAscii(txt, wtxt, 64);
    a = pdfLineAnnotW(pdf, x, y + h, x, y, 1.0, leClosedArrow, leClosedArrow, clBlack, clBlack, csDeviceRGB, W_("This is a measure line"), W_("Measure Line"), wtxt);
    // The parameters are exactly the same as above
    pdfSetLineAnnotParms(pdf, a, -1, 0.0, &p);

    pdfRestoreGraphicState(pdf);

    pdfEndPage(pdf);

    if(pdfHaveOpenDoc(pdf) != 0){
        std::string outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){
            pdfDeletePDF(pdf);
            return 0;
        }
        if(pdfCloseFile(pdf) != 0){
            printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
        }
    }

    pdfDeletePDF(pdf);
    return 0;
}

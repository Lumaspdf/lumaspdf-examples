// quad_points -- C++ port of examples\Vb6\annotations\quad_points\quad_points.bas
// Highlight and link annotations rotated with the coordinate system by
// setting their quad points explicitly.
#include <lumaspdf.h>
#include <cstdio>
#include <string>

// The Delphi original passes Delphi `string` (UnicodeString), so every call
// resolves to the WIDE overload; the *A twins used here before wrote
// PDFDocEncoding where the reference writes a UTF-16BE PDF text string. LWCHAR
// is wchar_t on Windows and char16_t elsewhere, so the literal must go through
// the header's own LUMAS_TEXT() macro -- a bare u"..." does not convert to
// LWCHAR* under MSVC, and a bare L"..." is 4 bytes wide off Windows.
#define W_(s) ((LWCHAR*)LUMAS_TEXT(s))
//
// ENGINE GAP -- pdfWriteText is DELIBERATELY left on the *A twin here.
// cpp/src/pdf/document.cpp TLumasPdfDoc::WriteTextW applies ResetFrameTextY()
// at the top of the function AND then, on the std-14/Type1 fallback path,
// tail-calls WriteTextA(posX, posY, ...) which applies it a SECOND time. Under
// pcTopDown that adds the font size twice, so pdfWriteTextW lands each run one
// full font size below where the Delphi reference puts it. Delphi's
// Lumas.Pdf.Document.pas WriteTextW applies ResetFrameTextY only inside its
// early-exit branches and passes the UNMODIFIED PosY down to WriteTextA.
// Switching to pdfWriteTextW would INTRODUCE a content difference, not remove
// one. Reported, not fixed (the engine DLL is shared).

static const UI32 clYellow = 65535;
static const UI32 clRed = 255;
static const UI32 clBlue = 16711680;

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

// Increment the y-coordinate of every point (Delphi IncY helper).
static void IncY(TFltPoint* points, int n, float Value){
    for(int i = 0; i < n; ++i) points[i].y += Value;
}

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    return 0;
}

int main(int argc, char** argv){
    TFltPoint points[4]{};

    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFW(pdf, W_(""));

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);

    pdfSaveGraphicState(pdf);

    pdfSetGStateFlags(pdf, (TGStateFlags)gfRealTopDownCoords, 0);    // This simplifies the handling a little bit.
    pdfRotateCoords(pdf, -30.0, 50.0, 200.0);

    const char* text  = "Some rotated text on a page...";   // pdfWriteTextA -- see ENGINE GAP note above
    LWCHAR*     textW = W_("Some rotated text on a page...");
    pdfSetFontW(pdf, W_("Helvetica"), fsRegular, 20.0, 0, cp1252);

    float d = (float)pdfGetDescent(pdf);
    float w = (float)pdfGetTextWidthW(pdf, textW);

    // Highlight annotations do not consider coordinate transformations made on a page.
    // To get such annotations rotated we must set the annotation's quad points.
    pdfWriteTextA(pdf, 0.0, 0.0, text);
    SI32 a = pdfHighlightAnnotW(pdf, atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, W_("Test app"), W_("Highligh Annotations"), W_("This is a highlight annotation"));
    // Consider the unusual order of the points!
    points[0].x = 0.0f;  points[0].y = d;          // Top left corner
    points[1].x = w;     points[1].y = d;          // Top right corner
    points[2].x = 0.0f;  points[2].y = 20.0f + d;  // Bottom left corner
    points[3].x = w;     points[3].y = 20.0f + d;  // Bottom right corner
    pdfSetAnnotQuadPoints(pdf, a, points, 4);

    pdfWriteTextA(pdf, 0.0, 30.0, text);
    a = pdfHighlightAnnotW(pdf, atSquiggly, 50.0, 80.0, w, 20.0, clRed, W_("Test app"), W_("Squiggly Annotations"), W_("This is a squiggly annotation"));
    IncY(points, 4, 30.0f);
    pdfSetAnnotQuadPoints(pdf, a, points, 4);

    pdfWriteTextA(pdf, 0.0, 60.0, text);
    a = pdfHighlightAnnotW(pdf, atStrikeOut, 50.0, 110.0, w, 20.0, clRed, W_("Test app"), W_("Strikeout Annotations"), W_("This is a strikeout annotation"));
    IncY(points, 4, 30.0f);
    pdfSetAnnotQuadPoints(pdf, a, points, 4);

    pdfWriteTextA(pdf, 0.0, 90.0, text);
    a = pdfHighlightAnnotW(pdf, atUnderline, 50.0, 140.0, w, 20.0, clRed, W_("Test app"), W_("Underline Annotations"), W_("This is a underline annotation"));
    IncY(points, 4, 30.0f);
    pdfSetAnnotQuadPoints(pdf, a, points, 4);

    text  = "Link annotations support quad points too";
    textW = W_("Link annotations support quad points too");
    w = (float)pdfGetTextWidthW(pdf, textW);
    pdfWriteTextA(pdf, 0.0, 120.0, text);
    // Link annotations support quad points too.
    a = pdfWebLinkW(pdf, 0.0, 120.0, w, 20, W_("www.lumaspdf.com"));
    pdfSetAnnotBorderWidth(pdf, a, 1.0);
    pdfSetAnnotColor(pdf, a, fcBorderColor, csDeviceRGB, clBlue);
    points[0].x = 0.0f;  points[0].y = 120.0f + d;   // Top left corner
    points[1].x = w;     points[1].y = 120.0f + d;   // Top right corner
    points[2].x = 0.0f;  points[2].y = 140.0f + d;   // Bottom left corner
    points[3].x = w;     points[3].y = 140.0f + d;   // Bottom right corner
    pdfSetAnnotQuadPoints(pdf, a, points, 4);

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

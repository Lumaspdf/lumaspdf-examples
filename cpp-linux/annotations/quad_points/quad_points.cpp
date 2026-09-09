// quad_points -- C++ port of examples\Vb6\annotations\quad_points\quad_points.bas
// Highlight and link annotations rotated with the coordinate system by
// setting their quad points explicitly.
#include <lumaspdf.h>
#include <cstdio>
#include <string>

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
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);

    pdfSaveGraphicState(pdf);

    pdfSetGStateFlags(pdf, (TGStateFlags)gfRealTopDownCoords, 0);    // This simplifies the handling a little bit.
    pdfRotateCoords(pdf, -30.0, 50.0, 200.0);

    const char* text = "Some rotated text on a page...";
    pdfSetFontA(pdf, "Helvetica", fsRegular, 20.0, 0, cp1252);

    float d = (float)pdfGetDescent(pdf);
    float w = (float)pdfGetTextWidthA(pdf, text);

    // Highlight annotations do not consider coordinate transformations made on a page.
    // To get such annotations rotated we must set the annotation's quad points.
    pdfWriteTextA(pdf, 0.0, 0.0, text);
    SI32 a = pdfHighlightAnnotA(pdf, atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, "Test app", "Highligh Annotations", "This is a highlight annotation");
    // Consider the unusual order of the points!
    points[0].x = 0.0f;  points[0].y = d;          // Top left corner
    points[1].x = w;     points[1].y = d;          // Top right corner
    points[2].x = 0.0f;  points[2].y = 20.0f + d;  // Bottom left corner
    points[3].x = w;     points[3].y = 20.0f + d;  // Bottom right corner
    pdfSetAnnotQuadPoints(pdf, a, points, 4);

    pdfWriteTextA(pdf, 0.0, 30.0, text);
    a = pdfHighlightAnnotA(pdf, atSquiggly, 50.0, 80.0, w, 20.0, clRed, "Test app", "Squiggly Annotations", "This is a squiggly annotation");
    IncY(points, 4, 30.0f);
    pdfSetAnnotQuadPoints(pdf, a, points, 4);

    pdfWriteTextA(pdf, 0.0, 60.0, text);
    a = pdfHighlightAnnotA(pdf, atStrikeOut, 50.0, 110.0, w, 20.0, clRed, "Test app", "Strikeout Annotations", "This is a strikeout annotation");
    IncY(points, 4, 30.0f);
    pdfSetAnnotQuadPoints(pdf, a, points, 4);

    pdfWriteTextA(pdf, 0.0, 90.0, text);
    a = pdfHighlightAnnotA(pdf, atUnderline, 50.0, 140.0, w, 20.0, clRed, "Test app", "Underline Annotations", "This is a underline annotation");
    IncY(points, 4, 30.0f);
    pdfSetAnnotQuadPoints(pdf, a, points, 4);

    text = "Link annotations support quad points too";
    w = (float)pdfGetTextWidthA(pdf, text);
    pdfWriteTextA(pdf, 0.0, 120.0, text);
    // Link annotations support quad points too.
    a = pdfWebLinkA(pdf, 0.0, 120.0, w, 20, "www.dynaforms.com");
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

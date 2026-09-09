// metafiles -- C++ port of examples\Vb6\metafiles\metafiles.bas
// Places three EMF metafiles, each centered and scaled to a landscape page,
// with a red frame around them.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

static const UI32 CLR_RED = 255;
static const double MARGIN = 10.0;
static const char* DIR = LUMAS_REPO_ROOT "/";

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void PlaceEMFCentered(PPDF pdf, const char* mFile, double width, double height){
    TRectL r{};
    pdfGetLogMetafileSizeA(pdf, mFile, &r);
    double w = r.Right - r.Left;
    double h = r.Bottom - r.Top;
    width  -= 2.0 * MARGIN;
    height -= 2.0 * MARGIN;
    double sx = width / w;
    if(h * sx <= height){
        double x = MARGIN;
        h = h * sx;
        double y = (height - h) / 2.0;
        pdfInsertMetafileA(pdf, mFile, x, y, width, 0.0);
        pdfSetStrokeColor(pdf, CLR_RED);
        pdfRectangle(pdf, x, y, width, h, fmStroke);
    } else {
        sx = height / h;
        w = w * sx;
        double x = (width - w) / 2.0;
        double y = MARGIN;
        pdfInsertMetafileA(pdf, mFile, x, y, 0.0, height);
        pdfSetStrokeColor(pdf, CLR_RED);
        pdfRectangle(pdf, x, y, w, height, fmStroke);
    }
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    if(pdfCreateNewPDFA(pdf, "") == 0){ pdfDeletePDF(pdf); return 1; }

    pdfSetPageCoords(pdf, pcTopDown);

    const char* names[3] = { "sample_vector.emf", "sample_vector.emf", "sample_vector.emf" };
    for(int i = 0; i < 3; ++i){
        std::string mf = std::string(DIR) + names[i];
        pdfAppend(pdf);
        pdfSetOrientationEx(pdf, 90);
        PlaceEMFCentered(pdf, mf.c_str(), pdfGetPageWidth(pdf), pdfGetPageHeight(pdf));
        pdfEndPage(pdf);
    }

    std::string outFile = exeDir(argv[0]) + "/out.pdf";
    if(pdfHaveOpenDoc(pdf) != 0){
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){ pdfDeletePDF(pdf); return 1; }
    }
    if(pdfCloseFile(pdf) != 0) printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
    pdfDeletePDF(pdf);
    return 0;
}

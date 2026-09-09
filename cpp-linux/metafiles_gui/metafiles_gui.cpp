// metafiles_gui -- C++ port of examples\Vb6\metafiles_gui\metafiles_gui.bas
// The Delphi original was a GUI metafile viewer/converter; here the core logic is a
// plain main(): load an EMF, place it centered on a page, write out.pdf.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

static const double MARGIN = 10.0;

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void PlaceEMFCentered(PPDF pdf, const char* mFile, double width, double height){
    TRectL r{};
    pdfGetLogMetafileSize(pdf, mFile, &r);
    double w = r.Right - r.Left;
    double h = r.Bottom - r.Top;
    width  -= 2.0 * MARGIN;
    height -= 2.0 * MARGIN;
    double sx = width / w;
    if(h * sx <= height){
        double x = MARGIN, y = MARGIN;
        pdfInsertMetafile(pdf, mFile, x, y, width, 0.0);
    } else {
        sx = height / h;
        w = w * sx;
        double x = MARGIN + (width - w) / 2.0;
        double y = MARGIN;
        pdfInsertMetafile(pdf, mFile, x, y, 0.0, height);
    }
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    pdfSetCompressionFilter(pdf, cfFlate);
    pdfSetJPEGQuality(pdf, 70);

    // Original input came from an interactive shell tree; here a fixed file.
    const char* inFile = LUMAS_REPO_ROOT "/sample_vector.emf";
    std::string outFile = exeDir(argv[0]) + "/out.pdf";

    if(pdfCreateNewPDFA(pdf, "") == 0){ pdfDeletePDF(pdf); return 1; }

    pdfSetCompressionLevel(pdf, clNone);
    pdfSetCompressionFilter(pdf, cfFlate);
    pdfSetColorSpace(pdf, csDeviceRGB);
    pdfSetMetaConvFlags(pdf, mfDefault);
    pdfSetPageCoords(pdf, pcTopDown);
    pdfAppend(pdf);
    pdfSetResolution(pdf, 300);
    pdfSetJPEGQuality(pdf, 70);
    PlaceEMFCentered(pdf, inFile, pdfGetPageWidth(pdf), pdfGetPageHeight(pdf));
    pdfEndPage(pdf);

    if(pdfHaveOpenDoc(pdf) != 0){
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){ pdfFreePDF(pdf); pdfDeletePDF(pdf); return 1; }
        if(pdfCloseFile(pdf) != 0) printf("OK: %s\n", outFile.c_str());
    }
    pdfDeletePDF(pdf);
    return 0;
}

// layer_tree -- C++ port of examples\Vb6\layers\layer_tree\layer_tree.bas
// Three optional-content groups arranged in a display tree with a titled group.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

static const UI32 clBlue = 0xFF0000;
static const UI32 clBlack = 0x0;
static const char* IMG = LUMAS_REPO_ROOT "/images/photo_01.jpg";

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetUseTransparency(pdf, 0);

    SI32 oc1 = pdfCreateOCGA(pdf, "All", 0, 1, oiAll);
    SI32 oc2 = pdfCreateOCGA(pdf, "Text and Annotations", 0, 1, oiAll);
    SI32 oc3 = pdfCreateOCGA(pdf, "Images", 0, 1, oiAll);

    void* root = pdfAddLayerToDisplTreeA(pdf, nullptr, oc1, "A layer group with a title");
    void* grp  = pdfAddLayerToDisplTreeA(pdf, root, -1, "");
    pdfAddLayerToDisplTreeA(pdf, grp, oc2, "");
    pdfAddLayerToDisplTreeA(pdf, grp, oc3, "");

    pdfAppend(pdf);
    pdfBeginLayer(pdf, oc1);
    pdfBeginLayer(pdf, oc2);
        pdfSetFontA(pdf, "Helvetica", fsRegular, 12.0, 0, cp1252);
        const char* someText = "Some text with a link!!!";
        pdfSetFillColor(pdf, clBlue);
        pdfWriteTextA(pdf, 50.0, 50.0, someText);
        double tw = pdfGetTextWidthA(pdf, someText);
        pdfSetBorderStyle(pdf, bsUnderline);
        pdfSetStrokeColor(pdf, clBlue);
        SI32 annot = pdfWebLinkA(pdf, 50.0, 51.0, tw, 12.0, "www.lumaspdf.com");

        UI32 ocArray[2] = { (UI32)oc1, (UI32)oc2 };
        SI32 ocmd = pdfCreateOCMD(pdf, ovAllOn, ocArray, 2);
        pdfAddObjectToLayer(pdf, ocmd, ooAnnotation, annot);
    pdfEndLayer(pdf);

    pdfBeginLayer(pdf, oc3);
        pdfInsertImageExA(pdf, 50.0, 70.0, 300.0, 200.0, IMG, 1);
    pdfEndLayer(pdf);
    pdfEndLayer(pdf);

    pdfSetFillColor(pdf, clBlack);
    pdfWriteTextA(pdf, 50.0, 300.0, "This text is not part of a layer!");
    pdfEndPage(pdf);

    pdfSetPageMode(pdf, pmUseOC);

    if(pdfHaveOpenDoc(pdf) != 0){
        std::string outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){ pdfDeletePDF(pdf); return 1; }
        if(pdfCloseFile(pdf) != 0) printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
    }
    pdfDeletePDF(pdf);
    return 0;
}

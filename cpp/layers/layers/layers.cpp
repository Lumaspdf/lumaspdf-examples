// layers -- C++ port of examples\Vb6\layers\layers\layers.bas
// Three nested optional-content groups (layers) with text (+ web link) and an image.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

static const UI32 clBlue = 0xFF0000;
static const UI32 clBlack = 0x0;
static const char* IMG = LUMAS_REPO_ROOT "/examples/test_files/images/margarita-102572_640.jpg";

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

// The Delphi original passes `string` (UnicodeString), which binds to the
// WideString overload of every TPDF method used here, so the reference output
// routes all text through the engine's UTF-16 path (e.g. OCG /Name is written
// as a UTF-16BE string). Widen the ASCII paths built at runtime so the W
// exports can be called with them.
static std::basic_string<LWCHAR> W(const std::string& s){
    return std::basic_string<LWCHAR>(s.begin(), s.end());
}

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFW(pdf, (LWCHAR*)LUMAS_TEXT(""));

    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetUseTransparency(pdf, 0);

    SI32 oc1 = pdfCreateOCGW(pdf, (LWCHAR*)LUMAS_TEXT("All"), 1, 1, oiAll);
    SI32 oc2 = pdfCreateOCGW(pdf, (LWCHAR*)LUMAS_TEXT("Text and Annotations"), 1, 1, oiAll);
    SI32 oc3 = pdfCreateOCGW(pdf, (LWCHAR*)LUMAS_TEXT("Images"), 1, 1, oiAll);

    pdfAppend(pdf);
        pdfBeginLayer(pdf, oc1);
            pdfBeginLayer(pdf, oc2);
                pdfSetFontW(pdf, (LWCHAR*)LUMAS_TEXT("Helvetica"), fsRegular, 12.0, 0, cp1252);
                LWCHAR* someText = (LWCHAR*)LUMAS_TEXT("Some text with a link!!!");
                pdfSetFillColor(pdf, clBlue);
                pdfWriteTextW(pdf, 50.0, 50.0, someText);
                double tw = pdfGetTextWidthW(pdf, someText);
                pdfSetBorderStyle(pdf, bsUnderline);
                pdfSetStrokeColor(pdf, clBlue);
                SI32 annot = pdfWebLinkW(pdf, 50.0, 51.0, tw, 12.0, (LWCHAR*)LUMAS_TEXT("www.dynaforms.com"));

                UI32 ocArray[2] = { (UI32)oc1, (UI32)oc2 };
                SI32 ocmd = pdfCreateOCMD(pdf, ovAllOn, ocArray, 2);
                pdfAddObjectToLayer(pdf, ocmd, ooAnnotation, annot);
            pdfEndLayer(pdf);

            pdfBeginLayer(pdf, oc3);
                pdfInsertImageExW(pdf, 50.0, 70.0, 300.0, 200.0, (LWCHAR*)W(IMG).c_str(), 1);
            pdfEndLayer(pdf);
        pdfEndLayer(pdf);

        pdfSetFillColor(pdf, clBlack);
        pdfWriteTextW(pdf, 50.0, 300.0, (LWCHAR*)LUMAS_TEXT("This text is not part of a layer!"));
    pdfEndPage(pdf);

    pdfSetPageMode(pdf, pmUseOC);

    if(pdfHaveOpenDoc(pdf) != 0){
        std::string outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileW(pdf, (LWCHAR*)W(outFile).c_str()) == 0){ pdfDeletePDF(pdf); return 1; }
        if(pdfCloseFile(pdf) != 0) printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
    }
    pdfDeletePDF(pdf);
    return 0;
}

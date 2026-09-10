// personalize -- C++ port of examples\Vb6\personalize\personalize.bas
// Imports a tax form, fills in the fields and adds a web link.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>
#include <ctime>

#ifndef RGB
#define RGB(r,g,b) ((UI32)(((unsigned char)(r))|(((unsigned char)(g))<<8)|(((unsigned char)(b))<<16)))
#endif

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return -1; // break processing on error
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfCreateNewPDFA(pdf, "");

    pdfSetViewerPreferences(pdf, vpDisplayDocTitle, avNone);
    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    const char* inFile = LUMAS_REPO_ROOT "/sample_form.pdf";
    if(pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0){ pdfDeletePDF(pdf); return 1; }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);

    pdfEditPage(pdf, 1);
    pdfSetFontA(pdf, "Courier", fsBold, 14.0, 0, cp1252);
    pdfWriteTextA(pdf, 72.5, 748.5, "X");
    pdfWriteTextA(pdf, 74.0, 701.0, "Musterstadt");
    pdfWriteTextA(pdf, 74.0, 677.0, "252/1062/3323");
    pdfBeginContinueText(pdf, 74.0, 628.0);
    pdfSetLeading(pdf, 24.0);
    pdfSetCharacterSpacing(pdf, 5.8);
    pdfAddContinueTextA(pdf, "Mustermann");
    pdfAddContinueTextA(pdf, "Hermann");
    pdfAddContinueTextA(pdf, "22021963keineKaufmann");
    pdfAddContinueTextA(pdf, "Musterstra\xDF" "e 145");   // 0xDF = 'sharp s' in cp1252 (split ends the hex escape)
    pdfAddContinueTextA(pdf, "12345Musterstadt");
    pdfSetCharacterSpacing(pdf, 0.0);
    pdfSetFontA(pdf, "Courier", fsBold, 10.0, 0, cp1252);
    pdfSetLeading(pdf, 48.0);
    pdfAddContinueTextA(pdf, "04.05.1994");
    pdfSetFontA(pdf, "Courier", fsBold, 14.0, 0, cp1252);
    pdfSetCharacterSpacing(pdf, 5.8);
    pdfAddContinueTextA(pdf, "Sabine");
    pdfSetLeading(pdf, 47.5);
    pdfAddContinueTextA(pdf, "18121966 ev  Hausfrau");
    pdfEndContinueText(pdf);
    pdfWriteTextA(pdf, 72.5, 365.0, "X");
    pdfWriteTextA(pdf, 396.0, 365.0, "X");
    pdfBeginContinueText(pdf, 74.0, 316.0);
    pdfSetLeading(pdf, 24.0);
    pdfAddContinueTextA(pdf, "2346256780     76834560");
    pdfAddContinueTextA(pdf, "Sparkasse Musterstadt");
    pdfEndContinueText(pdf);
    pdfWriteTextA(pdf, 72.5, 269.0, "X");
    pdfSetCharacterSpacing(pdf, 0.0);
    pdfSetFontA(pdf, "Courier", fsNone, 10.0, 0, cp1252);

    char nowStr[64];
    time_t t = time(nullptr);
    struct tm* lt = localtime(&t);
    strftime(nowStr, sizeof(nowStr), "%d.%m.%Y %H:%M:%S", lt);
    pdfWriteTextA(pdf, 53.0, 48.0, nowStr);

    pdfSetFillColor(pdf, RGB(0xFF, 0x66, 0x66));
    pdfSetFontA(pdf, "Helvetica", fsBold, 22.0, 0, cp1252);
    pdfWriteTextA(pdf, 340.0, 70.0, "www.lumaspdf.com");
    pdfSetLineWidth(pdf, 0.0);
    pdfSetLinkHighlightMode(pdf, hmPush);
    pdfSetAnnotFlags(pdf, afReadOnly);
    pdfWebLinkA(pdf, 340.0, 64.0, 204.0, 22.0, "https://www.lumaspdf.com");
    pdfEndPage(pdf);

    std::string outFile = exeDir(argv[0]) + "/out.pdf";
    if(pdfHaveOpenDoc(pdf) != 0){
        pdfSetOnErrorProc(pdf, nullptr, nullptr); // silence errors while opening the output file
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){ pdfDeletePDF(pdf); return 1; }
        pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    }
    if(pdfCloseFile(pdf) != 0)
        printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
    pdfDeletePDF(pdf);
    return 0;
}

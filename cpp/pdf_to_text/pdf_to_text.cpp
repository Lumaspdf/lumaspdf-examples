// pdf_to_text -- C++ port of examples\Vb6\pdf_to_text\pdf_to_text.bas
// Imports a PDF and extracts each page's text (pdfSplitPageTextA) to out.txt.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

static const UI32 emNoFuncNames = 0x10000000; // not in the wrapper enum; from dynapdf.pas

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetErrorMode(pdf, emNoFuncNames);
    pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    std::string cmapDir = exeDir(argv[0]) + "/CMap";
    pdfSetCMapDirA(pdf, cmapDir.c_str(), lcmRecursive | lcmDelayed);

    if(pdfCreateNewPDFA(pdf, "") == 0){ pdfDeletePDF(pdf); return 1; }

    pdfSetImportFlags(pdf, ifContentOnly | ifImportAsPage);
    const char* inFile = LUMAS_REPO_ROOT "/dynapdf_help.pdf";
    if(pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0){ pdfFreePDF(pdf); pdfDeletePDF(pdf); return 1; }
    if(pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0){ pdfFreePDF(pdf); pdfDeletePDF(pdf); return 1; }
    pdfCloseImportFile(pdf);

    std::string outFile = exeDir(argv[0]) + "/out.txt";
    FILE* fp = fopen(outFile.c_str(), "w");
    if(!fp){ pdfFreePDF(pdf); pdfDeletePDF(pdf); return 1; }

    SI32 count = pdfGetPageCount(pdf);
    for(SI32 i = 1; i <= count; ++i){
        fprintf(fp, "----- Page %d -----\n", i);
        pdfEditPage(pdf, i);
        char* txt = pdfSplitPageTextA(pdf, i);
        fprintf(fp, "%s\n", txt ? txt : "");
        pdfEndPage(pdf);
    }

    fclose(fp);
    pdfFreePDF(pdf);
    printf("Text written to: %s\n", outFile.c_str());
    pdfDeletePDF(pdf);
    return 0;
}

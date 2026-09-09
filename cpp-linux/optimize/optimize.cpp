// optimize -- C++ port of examples\Vb6\optimize\optimize.bas
// Imports a PDF, runs Optimize() over it and writes the result.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static bool Optimize(PPDF pdf, const char* inFile, const char* outFile){
    pdfCreateNewPDFA(pdf, "");
    pdfSetDocInfoA(pdf, diProducer, "");   // keep the original producer

    pdfSetImportFlags(pdf, (ifImportAll | ifImportAsPage) & ~ifPieceInfo);
    pdfSetImportFlags2(pdf, if2UseProxy | if2DuplicateCheck | if2Normalize | if2NoResNameCheck);
    if(pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0){ pdfFreePDF(pdf); return false; }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);

    pdfOptimize(pdf, ofInMemory | ofNewLinkNames | ofDeleteInvPaths, nullptr);

    TPDFError e{};
    e.StructSize = sizeof(e);
    for(SI32 i = 0; i < pdfGetErrLogMessageCount(pdf); ++i){
        pdfGetErrLogMessage(pdf, i, &e);
        if(e.Msg) printf("%s\n", e.Msg);
    }

    if(pdfHaveOpenDoc(pdf) != 0){
        if(pdfOpenOutputFileA(pdf, outFile) == 0){ pdfFreePDF(pdf); return false; }
        return pdfCloseFile(pdf) != 0;
    }
    return false;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);

    std::string cmapDir = exeDir(argv[0]) + "/CMap";
    pdfSetCMapDirA(pdf, cmapDir.c_str(), lcmDelayed | lcmRecursive);

    std::string filePath = exeDir(argv[0]) + "/out.pdf";
    const char* inFile = LUMAS_REPO_ROOT "/sample_multipage.pdf";
    if(Optimize(pdf, inFile, filePath.c_str()))
        printf("PDF file \"%s\" successfully created!\n", filePath.c_str());
    pdfDeletePDF(pdf);
    return 0;
}

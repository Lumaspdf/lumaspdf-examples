// optimize -- C++ port of examples\Vb6\optimize\optimize.bas
// Imports a PDF, runs Optimize() over it and writes the result.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

// The Delphi original passes Delphi `string` (UnicodeString) to CreateNewPDF,
// SetDocInfo, SetCMapDir, OpenImportFile and OpenOutputFile, so those calls
// resolve to the WIDE overloads rather than the *A twins used here
// before. LWCHAR is wchar_t on Windows and char16_t elsewhere, so literals must
// use the header's own LUMAS_TEXT() macro -- a bare u"..." does not convert to
// LWCHAR* under MSVC and a bare L"..." is 4 bytes wide off Windows.
#define W_(s) ((LWCHAR*)LUMAS_TEXT(s))
static std::basic_string<LWCHAR> WS(const std::string& s){
    return std::basic_string<LWCHAR>(s.begin(), s.end());
}

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static bool Optimize(PPDF pdf, const std::string& inFile, const std::string& outFile){
    pdfCreateNewPDFW(pdf, W_(""));
    pdfSetDocInfoW(pdf, diProducer, W_(""));   // keep the original producer

    pdfSetImportFlags(pdf, (ifImportAll | ifImportAsPage) & ~ifPieceInfo);
    pdfSetImportFlags2(pdf, if2UseProxy | if2DuplicateCheck | if2Normalize | if2NoResNameCheck);
    if(pdfOpenImportFileW(pdf, (LWCHAR*)WS(inFile).c_str(), ptOpen, "") < 0){ pdfFreePDF(pdf); return false; }
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
        if(pdfOpenOutputFileW(pdf, (LWCHAR*)WS(outFile).c_str()) == 0){ pdfFreePDF(pdf); return false; }
        return pdfCloseFile(pdf) != 0;
    }
    return false;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);

    // The Delphi original resolves ExpandFileName('../../../Resource/CMap')
    // from its own exe directory, i.e. <repo>/Resource/CMap -- not a per-example
    // CMap folder. Neither path exists in this tree, so this only changes which
    // directory the engine is told to scan, but the port should name the same one
    // the reference names.
    std::string cmapDir = std::string(LUMAS_REPO_ROOT) + "/Resource/CMap";
    pdfSetCMapDirW(pdf, (LWCHAR*)WS(cmapDir).c_str(), lcmDelayed | lcmRecursive);

    std::string filePath = exeDir(argv[0]) + "/out.pdf";
    const char* inFile = LUMAS_REPO_ROOT "/sample_multipage.pdf";
    if(Optimize(pdf, inFile, filePath))
        printf("PDF file \"%s\" successfully created!\n", filePath.c_str());
    pdfDeletePDF(pdf);
    return 0;
}

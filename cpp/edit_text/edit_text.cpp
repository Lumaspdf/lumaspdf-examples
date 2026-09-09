// edit_text -- C++ port of examples\Vb6\edit_text\edit_text.bas
// Imports a PDF and uses the content parser to find/replace a string on each page.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <cstring>
#include <string>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfCreateNewPDFA(pdf, "");
    pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);

    const char* inFile = LUMAS_REPO_ROOT "/dynapdf_help.pdf";
    if(pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0){ pdfDeletePDF(pdf); return 1; }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);

    IPSR ctx = psrCreateParserContext(pdf, ofDefault, nullptr);
    const wchar_t* searchText = L"PDF";
    const wchar_t* replaceText = L"XDF";
    UI32 searchLen = (UI32)wcslen(searchText);
    UI32 replaceLen = (UI32)wcslen(replaceText);

    TContent content{};
    TTextSelection sel{};
    for(SI32 i = 1; i <= pdfGetPageCount(pdf); ++i){
        if(psrParsePage(pdf, ctx, nullptr, nullptr, i, cpfEnableTextSelection, nullptr, &content) != 0){
            PTextSelection last = nullptr;
            while(psrFindText(pdf, ctx, nullptr, stDefault, last, (LWCHAR*)searchText, searchLen, &sel) != 0){
                psrReplaceSelText(pdf, ctx, rtfDefault, &sel, (LWCHAR*)replaceText, replaceLen);
                last = &sel;
            }
            psrWriteToPage(pdf, ctx, ofDefault, nullptr);
        }
    }
    psrDeleteParserContext(&ctx);

    std::string outFile = exeDir(argv[0]) + "/out.pdf";
    if(pdfHaveOpenDoc(pdf) != 0){
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){ pdfDeletePDF(pdf); return 1; }
    }
    if(pdfCloseFile(pdf) != 0) printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
    pdfDeletePDF(pdf);
    return 0;
}

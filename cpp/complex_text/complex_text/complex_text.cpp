// complex_text -- C++ port of
//   examples\Vb6\complex_text\complex_text\complex_text.bas
// Complex text layout of a right-to-left (Pashto) text.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>
#include <vector>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static std::vector<wchar_t> GetFileBuffer(const std::string& fileName){
    std::vector<wchar_t> out;
    FILE* f = fopen(fileName.c_str(), "rb");
    if(!f) return out;
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    if(n > 0){
        // File is UTF-16LE (2-byte code units) on disk regardless of
        // platform; widen explicitly into native wchar_t instead of a raw
        // byte-for-byte fread -- wchar_t is 2 bytes on Windows (a no-op
        // widening) but 4 bytes on Linux/Unix, where a raw fread would pack
        // 2 source code units into every wchar_t element and corrupt the text.
        std::vector<unsigned short> raw(n / 2 + 1, 0);
        fread(raw.data(), 1, n, f);
        out.resize(raw.size(), 0);
        for (size_t i = 0; i < raw.size(); ++i) out[i] = (wchar_t)raw[i];
    } else {
        out.push_back(0);
    }
    fclose(f);
    return out;
}

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;   // We try to continue if an error occurs
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    pdfCreateNewPDFA(pdf, "");            // We create no PDF file yet

    std::vector<wchar_t> txt = GetFileBuffer(LUMAS_REPO_ROOT "/examples/test_files/pashto.txt");

    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetGStateFlags(pdf, gfComplexText, 0);   // Enable complex text layout
    pdfSetBidiMode(pdf, bmRightToLeft);

    pdfAppend(pdf);

    // The font must be loaded with cpUnicode.
    pdfSetFontW(pdf, (LWCHAR*)LUMAS_TEXT("Arial"), fsRegular, 10.0, 1, cpUnicode);
    pdfSetLeading(pdf, pdfGetTypoLeading(pdf));
    pdfWriteFTextExW(pdf, 50.0, 50.0, pdfGetPageWidth(pdf) - 100.0,
                     pdfGetPageHeight(pdf) - 100.0, taJustify, (LWCHAR*)txt.data());

    pdfEndPage(pdf);

    std::string outFile;
    if(pdfHaveOpenDoc(pdf) != 0){
        outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){
            pdfDeletePDF(pdf);
            return 0;
        }
    }
    if(pdfCloseFile(pdf) != 0)
        printf("PDF file \"%s\" successfully created!\n", outFile.c_str());

    pdfDeletePDF(pdf);
    return 0;
}

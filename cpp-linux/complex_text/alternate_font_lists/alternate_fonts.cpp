// alternate_fonts -- C++ port of
//   examples\Vb6\complex_text\alternate_font_lists\alternate_fonts.bas
// Complex text layout with an alternate font list to improve font substitution.
#include <lumaspdf.h>
#include "repo_root.h"
#include "apputil.h"   // RegisterHostFontDirs
#include <cstdio>
#include <string>
#include <vector>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

// Reads a file raw and returns its bytes as a UTF-16 (LWCHAR) buffer,
// null-terminated. Mirrors the Delphi/VB6 GetFileBuffer().
static std::vector<LWCHAR> GetFileBuffer(const std::string& fileName){
    // The file is UTF-16LE on disk, and UTF-16LE is EXACTLY what LWCHAR is --
    // 2 bytes on every platform (wchar_t under _WIN32, char16_t elsewhere; see
    // the LWCHAR note in lumaspdf.h). So a raw byte-for-byte read IS the
    // correct conversion, on Windows and on POSIX alike.
    //
    // THIS USED TO WIDEN EACH UNIT INTO A NATIVE wchar_t, and that is what
    // broke it off Windows. The widening itself was right for a 4-byte
    // wchar_t -- but the buffer is then handed to a "W" export as (LWCHAR*),
    // and LWCHAR is 2 bytes THERE TOO. The engine read each 4-byte element as
    // two UTF-16 units, the second always zero, so every string terminated
    // after its first character: all three complex_text examples emitted a
    // single <0000> Tj (.notdef) and produced byte-identical 4316-byte PDFs on
    // Linux and macOS, against 1301/3972/3972 glyphs on Windows.
    std::vector<LWCHAR> out;
    FILE* f = fopen(fileName.c_str(), "rb");
    if(!f) return out;
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    if(n > 0){
        out.assign((size_t)(n / 2) + 1, 0);          // +1 keeps it NUL-terminated
        fread(out.data(), 1, (size_t)n, f);
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
    // Alternate fonts, sorted alphabetically. Not guaranteed to be installed.
    // LUMAS_TEXT(), not L"..." -- lumaspdf.h says so explicitly ("do not write
    // L"..."; write LUMAS_TEXT(...)), and this array is why. An L"..."
    // literal is 4-byte units off Windows, so casting it to LWCHAR* (2 bytes)
    // handed pdfSetAltFontsW five names that each died after one character.
    const LWCHAR* fonts[5] = {
        LUMAS_TEXT("Malgun Gothic"),   // Korean
        LUMAS_TEXT("Mangal"),          // Hindi or Marathi
        LUMAS_TEXT("Nyala"),           // Amharic
        LUMAS_TEXT("Shonar Bangla"),   // Bengali
        LUMAS_TEXT("Shruti")           // Gujarati
    };
    const long ALT_FONT_COUNT = 5;

    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    pdfCreateNewPDFA(pdf, "");            // We create no PDF file yet
    // Register the machine's font directories. Without this the engine never
    // sees a host font off Windows and "Arial" resolves to the bundled
    // Liberation Sans, which has no Arabic coverage -- so this example's
    // Pashto text would render as .notdef boxes however the text is passed.
    RegisterHostFontDirs(pdf);

    std::vector<LWCHAR> txt = GetFileBuffer(LUMAS_REPO_ROOT "/multi_lang.txt");

    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetGStateFlags(pdf, gfComplexText, 0);   // Enable complex text layout

    SI32 altFonts = pdfCreateAltFontList(pdf);
    LWCHAR* ptrs[5];
    for(int i = 0; i < ALT_FONT_COUNT; i++) ptrs[i] = const_cast<LWCHAR*>(fonts[i]);   // types already match; no reinterpreting cast
    pdfSetAltFontsW(pdf, altFonts, ptrs, ALT_FONT_COUNT);

    pdfAppend(pdf);

    // The font must be loaded with cpUnicode.
    pdfSetFontA(pdf, "Arial", fsRegular, 10.0, 1, cpUnicode);
    pdfActivateAltFontList(pdf, altFonts, 1);

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

// stamps -- C++ port of examples\Vb6\annotations\stamps\stamps.bas
// A pre-defined "Approved" stamp rendered in English, German and French.
#include <lumaspdf.h>
#include <cstdio>
#include <string>

#define RGB_(r,g,b) ((UI32)((UI8)(r) | ((UI8)(g) << 8) | ((UI8)(b) << 16)))

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    return 0;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);

    // A pre-defined stamp is scaled to the given width. The language can be set right before creating the stamp.
    SI32 a = pdfStampAnnotA(pdf, rsApproved, 135.0, 50.0, 300.0, 10.0, "Test app", "Stamp Annotations", "The default language is English!");
    pdfSetAnnotColor(pdf, a, fcBorderColor, csDeviceRGB, RGB_(120, 190, 92));

    pdfSetLanguage(pdf, "DE");
    a = pdfStampAnnotA(pdf, rsApproved, 135.0, 150.0, 300.0, 10.0, "Test app", "Stamp Annotations", "The same stamp in German!");
    pdfSetAnnotColor(pdf, a, fcBorderColor, csDeviceRGB, RGB_(230, 65, 132));

    pdfSetLanguage(pdf, "FR");
    a = pdfStampAnnotA(pdf, rsApproved, 135.0, 250.0, 300.0, 10.0, "Test app", "Stamp Annotations", "The same stamp in French!");
    pdfSetAnnotColor(pdf, a, fcBorderColor, csDeviceRGB, RGB_(78, 157, 232));
    pdfEndPage(pdf);

    if(pdfHaveOpenDoc(pdf) != 0){
        std::string outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){
            pdfDeletePDF(pdf);
            return 0;
        }
        if(pdfCloseFile(pdf) != 0){
            printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
        }
    }

    pdfDeletePDF(pdf);
    return 0;
}

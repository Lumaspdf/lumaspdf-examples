// hello_world -- C++ port of examples\Vb6\hello_world\hello_world.bas
#include <lumaspdf.h>
#include <cstdio>
#include <string>
#include <ctime>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return -1;   // we break processing if an error occurs
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    if(pdfCreateNewPDFA(pdf, "") == 0){
        pdfDeletePDF(pdf);
        return 0;
    }
    pdfSetDocInfoA(pdf, diCreator, "Delphi Example project");
    pdfSetDocInfoA(pdf, diTitle, "My first PDF output");

    pdfAppend(pdf);
    pdfSetFontA(pdf, "Arial", fsItalic, 30.0, 1, cp1252);

    time_t t = time(nullptr);
    char nowbuf[64]; strftime(nowbuf, sizeof(nowbuf), "%Y-%m-%d %H:%M:%S", localtime(&t));
    std::string txt = std::string("My first PDF output...\r\r") + nowbuf;
    pdfWriteFTextA(pdf, taCenter, txt.c_str());
    pdfEndPage(pdf);

    std::string outFile;
    if(pdfHaveOpenDoc(pdf) != 0){
        pdfSetOnErrorProc(pdf, nullptr, nullptr);
        outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){
            pdfDeletePDF(pdf);
            return 0;
        }
        pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    }
    if(pdfCloseFile(pdf) != 0)
        printf("OK: %s\n", outFile.c_str());

    pdfDeletePDF(pdf);
    return 0;
}

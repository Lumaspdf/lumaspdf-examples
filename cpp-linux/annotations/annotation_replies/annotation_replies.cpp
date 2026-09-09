// annotation_replies -- C++ port of examples\Vb6\annotations\annotation_replies\annotation_replies.bas
// A square annotation with a reply, and a reply to that reply.
#include <lumaspdf.h>
#include <cstdio>
#include <string>


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
    // To see the reply click on the annotation
    SI32 annot = pdfSquareAnnotA(pdf, 50.0, 50.0, 200.0, 100.0, 3.0, NO_COLOR, 255, csDeviceRGB, "Jim", "Test", "Just test...");
    SI32 reply = pdfSetAnnotMigrationStateA(pdf, annot, asCreateReply, "Harry");
    pdfSetAnnotStringA(pdf, reply, asContent, "This is a reply!");

    reply = pdfSetAnnotMigrationStateA(pdf, reply, asCreateReply, "Jim");
    pdfSetAnnotStringA(pdf, reply, asContent, "This is a reply to a reply!");
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

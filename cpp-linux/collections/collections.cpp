// collections -- C++ port of examples\Vb6\collections\collections.bas
// Imports a cover page, creates a PDF portfolio (collection) and attaches
// three files to it.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static const char* TF = LUMAS_REPO_ROOT "/";

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;   // We try to continue if an error occurs
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfCreateNewPDFA(pdf, "");            // The output file is opened later
    pdfSetOnErrorProc(pdf, nullptr, ErrProc);

    // The page of this file is shown when opening the file with an older Acrobat.
    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    std::string cover = std::string(TF) + "collection_en.pdf";
    if(pdfOpenImportFileA(pdf, cover.c_str(), ptOpen, "") < 0){
        pdfDeletePDF(pdf);
        printf("Input file \"%s\" not found!\n", cover.c_str());
        return 0;
    }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);
    pdfCreateCollection(pdf, civTile);

    std::string taxform = std::string(TF) + "sample_form.pdf";
    std::string emf     = std::string(TF) + "sample_vector.emf";
    std::string txt     = std::string(TF) + "sample.txt";

    SI32 ef = pdfAttachFileA(pdf, taxform.c_str(), "A PDF file...", 1);
    pdfSetColDefFile(pdf, ef);            // Opened when viewing with Acrobat 8 or later
    pdfAttachFileA(pdf, emf.c_str(), "An EMF file...", 1);
    pdfAttachFileA(pdf, txt.c_str(), "A text file...", 1);

    std::string outFile;
    if(pdfHaveOpenDoc(pdf) != 0){
        outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){
            pdfDeletePDF(pdf);
            return 0;
        }
    }
    pdfCloseFile(pdf);
    printf("PDF Collection \"%s\" successfully created!\n", outFile.c_str());
    pdfDeletePDF(pdf);
    return 0;
}

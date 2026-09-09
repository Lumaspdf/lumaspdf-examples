// collections2 -- C++ port of examples\Vb6\collections2\collections2.bas
// Like collections, but adds sortable collection fields and per-item field
// values, then validates the collection.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static const char* TF = LUMAS_REPO_ROOT "/examples/test_files/";

// The Delphi original passes Delphi `string` (UnicodeString) to CreateNewPDF,
// OpenImportFile, CreateCollectionField, AttachFile and OpenOutputFile, so
// every one of those calls resolves to the WIDE overload rather than the *A
// twins used here before. (CreateColItemNumber has no W twin at all -- it stays
// ANSI here exactly as it is in the Delphi original.)
// LWCHAR is wchar_t on Windows and char16_t elsewhere, so literals must use the
// header's own LUMAS_TEXT() macro -- a bare u"..." does not convert to LWCHAR*
// under MSVC and a bare L"..." is 4 bytes wide off Windows.
#define W_(s) ((LWCHAR*)LUMAS_TEXT(s))
static std::basic_string<LWCHAR> WS(const std::string& s){
    return std::basic_string<LWCHAR>(s.begin(), s.end());
}

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;   // We try to continue if an error occurs
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfCreateNewPDFW(pdf, W_(""));            // The output file is opened later
    pdfSetOnErrorProc(pdf, nullptr, ErrProc);

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    std::string cover = std::string(TF) + "collection_en.pdf";
    if(pdfOpenImportFileW(pdf, (LWCHAR*)WS(cover).c_str(), ptOpen, "") < 0){
        pdfDeletePDF(pdf);
        printf("Input file \"%s\" not found!\n", cover.c_str());
        return 0;
    }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);
    pdfCreateCollection(pdf, civTile);

    // Add a user defined field Index so that we can sort in any order we want.
    SI32 ef = pdfCreateCollectionFieldW(pdf, cisCustomNumber, 0, W_("File index"), "Index", 0, 1);
    pdfSetColSortField(pdf, ef, 1);

    pdfCreateCollectionFieldW(pdf, cisFileName, 1, W_("File name"), "", 1, 1);
    pdfCreateCollectionFieldW(pdf, cisSize, 2, W_("File size"), "", 1, 0);
    pdfCreateCollectionFieldW(pdf, cisModDate, 3, W_("Modification date"), "", 1, 0);

    std::string taxform = std::string(TF) + "taxform.pdf";
    std::string emf     = std::string(TF) + "fulltest.emf";
    std::string txt     = std::string(TF) + "sample.txt";

    ef = pdfAttachFileW(pdf, (LWCHAR*)WS(taxform).c_str(), W_("A PDF file..."), 1);
    pdfSetColDefFile(pdf, ef);
    pdfCreateColItemNumber(pdf, ef, "Index", 0.0, "");

    ef = pdfAttachFileW(pdf, (LWCHAR*)WS(emf).c_str(), W_("An EMF file..."), 1);
    pdfCreateColItemNumber(pdf, ef, "Index", 1.0, "");

    ef = pdfAttachFileW(pdf, (LWCHAR*)WS(txt).c_str(), W_("A text file..."), 1);
    pdfCreateColItemNumber(pdf, ef, "Index", 2.0, "");

    // Let's check whether the collection is valid.
    pdfCheckCollection(pdf);

    std::string outFile;
    if(pdfHaveOpenDoc(pdf) != 0){
        outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileW(pdf, (LWCHAR*)WS(outFile).c_str()) == 0){
            pdfDeletePDF(pdf);
            return 0;
        }
    }
    pdfCloseFile(pdf);
    printf("PDF Collection \"%s\" successfully created!\n", outFile.c_str());
    pdfDeletePDF(pdf);
    return 0;
}

// merge_pdf -- C++ port of examples\Vb6\merge_pdf\merge_pdf.bas
// Generic merge of arbitrary PDF files (with handling for forms / PDF collections).
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static std::string ExtractFileName(const std::string& path){
    auto p = path.find_last_of("\\/");
    return p == std::string::npos ? path : path.substr(p + 1);
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);
        pdfSetFontA(pdf, "Helvetica", fsRegular, 14.0, 0, cp1252);
        pdfWriteFTextExA(pdf, 50.0, 50.0, pdfGetPageWidth(pdf) - 100.0, -1.0, taJustify,
            "The following pages were imported from different PDF files. LumasPDF adjusts the destinations of link annotations and bookmarks so that "
            "all destinations refer to the new page numbers after import.\r\r"
            "Entire PDF files can be easily merged with ImportPDFFile() but it is also possible to import only specific pages of an arbitrary number "
            "of PDF files. You can also add further pages or edit imported pages if necessary. An existing page can be opened for editing with EditPage().");
    pdfEndPage(pdf);

    bool first = true, haveXFA = false, isCollection = false;
    SI32 destPage = 1;

    std::string files[2] = { LUMAS_REPO_ROOT "/sample_invoice.pdf", LUMAS_REPO_ROOT "/sample_multipage.pdf" };

    for(int i = 0; i < 2; ++i){
        if(pdfOpenImportFileA(pdf, files[i].c_str(), ptOpen, "") < 0){ pdfDeletePDF(pdf); return 1; }
        if(first){
            first = false;
            haveXFA = (pdfGetInIsXFAForm(pdf) != 0);
            isCollection = (pdfGetInIsCollection(pdf) != 0);
            destPage = pdfImportPDFFile(pdf, destPage + 1, 1.0, 1.0);
            if(destPage < 0) break;
        } else {
            if(isCollection){
                if(pdfGetInIsCollection(pdf) != 0){
                    pdfSetImportFlags(pdf, ifEmbeddedFiles);
                    if(pdfImportCatalogObjects(pdf) == 0) break;
                } else {
                    pdfCloseImportFile(pdf);
                    pdfAttachFileA(pdf, files[i].c_str(), ExtractFileName(files[i]).c_str(), 1);
                }
            } else {
                if((pdfGetInIsCollection(pdf) != 0) ||
                   (((pdfGetInIsXFAForm(pdf) != 0) || (pdfGetInFieldCount(pdf) > 0)) &&
                    ((pdfGetFieldCount(pdf) > 0) || haveXFA))) break;
                pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
                pdfSetImportFlags2(pdf, if2UseProxy);
                destPage = pdfImportPDFFile(pdf, destPage + 1, 1.0, 1.0);
                if(destPage < 0) break;
            }
        }
        pdfCloseImportFile(pdf);
    }

    if(pdfHaveOpenDoc(pdf) != 0){
        std::string outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){ pdfDeletePDF(pdf); return 1; }
        if(pdfCloseFile(pdf) != 0) printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
    }
    pdfDeletePDF(pdf);
    return 0;
}

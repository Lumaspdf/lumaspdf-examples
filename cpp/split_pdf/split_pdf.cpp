// split_pdf -- C++ port of examples\Vb6\split_pdf\split_pdf.bas
// Opens one import file, keeps it open across CloseFile() via
// SetUseGlobalImpFiles, and writes each page into its own PDF.
#include "apputil.h"
#include <cstdio>

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(){
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);  // avoid conversion of pages to templates
    pdfSetImportFlags2(pdf, if2UseProxy);                  // reduces the memory usage

    const char* inFile = "license.pdf";
    if(pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0){
        pdfDeletePDF(pdf);
        return 0;
    }

    // Keeps the open import file from being closed when CloseFile() is called.
    pdfSetUseGlobalImpFiles(pdf, 1);

    const char* outDir = "out";
    CreateDirectoryA(outDir, 0);

    SI32 count = pdfGetInPageCount(pdf);
    for(SI32 i = 1; i <= count; i++){
        char outPath[512];
        sprintf(outPath, "%s\\page%04d.pdf", outDir, (int)i);
        pdfCreateNewPDFA(pdf, outPath);
        pdfAppend(pdf);
        pdfImportPageEx(pdf, i, 1.0, 1.0);
        pdfEndPage(pdf);
        pdfCloseFile(pdf);
    }

    // Always set the property back to false when finished.
    pdfSetUseGlobalImpFiles(pdf, 0);

    printf("Pages written to: %s\n", outDir);
    pdfDeletePDF(pdf);
    return 0;
}

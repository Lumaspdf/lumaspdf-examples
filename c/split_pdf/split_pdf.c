/* split_pdf -- C port of examples\Vb6\split_pdf
   Opens one import file, keeps it open across CloseFile() via
   SetUseGlobalImpFiles, and writes each page into its own PDF. */
#include <direct.h>
#include <stdio.h>
#include "lumaspdf.h"

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(void) {
    PPDF pdf = pdfNewPDF();
    SI32 i, count;
    char outPath[512];

    pdfSetOnErrorProc(pdf, 0, PDFError);

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    pdfSetImportFlags2(pdf, if2UseProxy);

    if (pdfOpenImportFileA(pdf, "license.pdf", ptOpen, "") < 0) {
        pdfDeletePDF(pdf); return 1;
    }

    pdfSetUseGlobalImpFiles(pdf, 1);

    _mkdir("out");

    count = pdfGetInPageCount(pdf);
    for (i = 1; i <= count; i++) {
        sprintf(outPath, "out\\page%04d.pdf", i);
        pdfCreateNewPDFA(pdf, outPath);
            pdfAppend(pdf);
                pdfImportPageEx(pdf, i, 1.0, 1.0);
            pdfEndPage(pdf);
        pdfCloseFile(pdf);
    }

    pdfSetUseGlobalImpFiles(pdf, 0);

    printf("Pages written to: out\n");
    pdfDeletePDF(pdf);
    return 0;
}

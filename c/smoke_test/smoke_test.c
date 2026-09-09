/* smoke_test -- C port of examples\Vb6\smoke_test
   Creates a PDF with text, a red rectangle and a bookmark. */
#include <stdio.h>
#include "lumaspdf.h"

int main(void) {
    PPDF pdf = pdfNewPDF();
    const char* outFile = "smoke_out.pdf";

    if (pdfCreateNewPDFA(pdf, outFile) == 0) {
        printf("CreateNewPDF failed\n");
        pdfDeletePDF(pdf); return 1;
    }

    pdfSetDocInfoA(pdf, diTitle, "LumasPdf example-mirror smoke test");
    pdfAppend(pdf);
    pdfSetFontA(pdf, "Arial", fsRegular, 24.0, 1, cp1252);
    pdfWriteTextA(pdf, 50, 700, "Examples run on LumasPdf.dll");
    pdfSetFillColor(pdf, 255);                 /* red (COLORREF, R in low byte) */
    pdfRectangle(pdf, 50, 500, 200, 100, fmFill);
    pdfAddBookmarkA(pdf, "First page", -1, 1, 0);
    pdfEndPage(pdf);

    if (pdfCloseFile(pdf) == 0) {
        printf("CloseFile failed\n");
        pdfDeletePDF(pdf); return 1;
    }

    printf("OK: %s\n", outFile);
    pdfDeletePDF(pdf);
    return 0;
}

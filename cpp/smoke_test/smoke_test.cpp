// smoke_test -- C++ mirror of examples\Vb6\smoke_test\smoke_test.bas
// Creates a PDF with text, a red rectangle and a bookmark via the flat pdf* API.
#include "apputil.h"

int main() {
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    const char* outFile = "smoke_out.pdf";

    if (pdfCreateNewPDFA(pdf, outFile) == 0) {
        printf("CreateNewPDF failed\n");
        pdfDeletePDF(pdf);
        return 0;
    }

    pdfSetDocInfoA(pdf, diTitle, "LumasPdf example-mirror smoke test");
    pdfAppend(pdf);
    pdfSetFontA(pdf, "Arial", fsRegular, 24.0, 1, cp1252);
    pdfWriteTextA(pdf, 50, 700, "Mirrored DynaPDF examples run on LumasPdf.dll");
    pdfSetFillColor(pdf, 255);                      // red (COLORREF, R in low byte)
    pdfRectangle(pdf, 50, 500, 200, 100, fmFill);
    pdfAddBookmarkA(pdf, "First page", -1, 1, 0);
    pdfEndPage(pdf);

    if (pdfCloseFile(pdf) == 0) {
        printf("CloseFile failed\n");
        pdfDeletePDF(pdf);
        return 0;
    }

    printf("OK: %s\n", outFile);
    pdfDeletePDF(pdf);
    return 0;
}

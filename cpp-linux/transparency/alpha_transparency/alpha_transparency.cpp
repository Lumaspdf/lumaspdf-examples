// alpha_transparency -- C++ mirror of
// examples\Vb6\transparency\alpha_transparency\alpha_transparency.bas
// Draws an image at fill alpha 0.5 and a second at the default alpha 1.0 using
// extended graphics states.
#include "apputil.h"

static const unsigned long clWhite = 0xFFFFFF;
static const unsigned long clBlack = 0x0;

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main() {
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfCreateNewPDFA(pdf, "");
    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetUseTransparency(pdf, 0); // Disable color key masking for images

    pdfAppend(pdf);
        pdfSetFontA(pdf, "Helvetica", fsRegular, 12.0, 0, cp1252);
        pdfWriteTextA(pdf, 50, 50, "Fill Alpha = 0.5");

        pdfRectangle(pdf, 50, 70, 110, 160, fmFill);
        pdfSetFillColor(pdf, clWhite);
        pdfWriteTextA(pdf, 55, 75, "Background");

        TPDFExtGState g;
        pdfInitExtGState(&g);
        g.FillAlpha = 0.5;
        int gs = pdfCreateExtGState(pdf, &g);
        pdfSetExtGState(pdf, gs);

        int img = pdfInsertImageExA(pdf, 60, 84, 200, 0, LUMAS_REPO_ROOT "/images/photo_02.jpg", 0);

        // Restore by creating a second state that reverts the change.
        g.FillAlpha = 1.0;
        gs = pdfCreateExtGState(pdf, &g);
        pdfSetExtGState(pdf, gs);

        pdfSetFillColor(pdf, clBlack);
        pdfWriteTextA(pdf, 340, 50, "Fill Alpha = 1.0 (default)");
        pdfRectangle(pdf, 340, 70, 110, 160, fmFill);
        pdfSetFillColor(pdf, clWhite);
        pdfWriteTextA(pdf, 345, 75, "Background");
        pdfPlaceImage(pdf, img, 350, 84, 200, 0);
    pdfEndPage(pdf);

    if (pdfHaveOpenDoc(pdf) != 0) {
        const char* outFile = "out.pdf";
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfDeletePDF(pdf); return 0; }
        if (pdfCloseFile(pdf) != 0)
            printf("PDF file \"%s\" successfully created!\n", outFile);
    }

    pdfDeletePDF(pdf);
    return 0;
}

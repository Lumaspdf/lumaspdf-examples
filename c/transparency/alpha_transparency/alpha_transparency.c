/* alpha_transparency -- C port of examples\Vb6\transparency\alpha_transparency
   Draws an image at fill alpha 0.5 and a second at the default alpha 1.0 using
   extended graphics states. */
#include <stdio.h>
#include "lumaspdf.h"

#define clWhite 0xFFFFFF
#define clBlack 0x0

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(void) {
    PPDF pdf;
    SI32 gs, img;
    TPDFExtGState g;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetUseTransparency(pdf, 0);

    pdfAppend(pdf);

    pdfSetFontA(pdf, "Helvetica", fsRegular, 12.0, 0, cp1252);
    pdfWriteTextA(pdf, 50.0, 50.0, "Fill Alpha = 0.5");

    pdfRectangle(pdf, 50.0, 70.0, 110.0, 160.0, fmFill);
    pdfSetFillColor(pdf, clWhite);
    pdfWriteTextA(pdf, 55.0, 75.0, "Background");

    pdfInitExtGState(&g);
    g.FillAlpha = 0.5f;
    gs = pdfCreateExtGState(pdf, &g);
    pdfSetExtGState(pdf, gs);

    img = pdfInsertImageExA(pdf, 60.0, 84.0, 200.0, 0.0, "../../../test_files/images/tree-frog-69813_640.jpg", 0);

    g.FillAlpha = 1.0f;
    gs = pdfCreateExtGState(pdf, &g);
    pdfSetExtGState(pdf, gs);

    pdfSetFillColor(pdf, clBlack);
    pdfWriteTextA(pdf, 340.0, 50.0, "Fill Alpha = 1.0 (default)");
    pdfRectangle(pdf, 340.0, 70.0, 110.0, 160.0, fmFill);
    pdfSetFillColor(pdf, clWhite);
    pdfWriteTextA(pdf, 345.0, 75.0, "Background");
    pdfPlaceImage(pdf, img, 350.0, 84.0, 200.0, 0.0);

    pdfEndPage(pdf);

    if (pdfHaveOpenDoc(pdf) != 0) {
        if (pdfOpenOutputFileA(pdf, "out.pdf") == 0) { pdfDeletePDF(pdf); return 1; }
        if (pdfCloseFile(pdf) != 0) printf("PDF file \"out.pdf\" successfully created!\n");
    }

    pdfDeletePDF(pdf);
    return 0;
}

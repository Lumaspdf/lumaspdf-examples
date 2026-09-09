/* softmask -- C port of examples\Vb6\transparency\softmask
   Creates a transparency group used as a luminosity soft mask (radial shading)
   and applies it to an image. */
#include <stdio.h>
#include "lumaspdf.h"

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(void) {
    PPDF pdf;
    SI32 gs, grp, sh;
    TPDFExtGState g;
    TPDFRect bbox;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetUseTransparency(pdf, 0);

    pdfAppend(pdf);

    pdfSetFontA(pdf, "Helvetica", fsRegular, 12.0, 0, cp1252);
    pdfWriteTextA(pdf, 50.0, 50.0, "Transparency effect with a soft mask.");

    pdfInsertImageExA(pdf, 50.0, 80.0, pdfGetPageWidth(pdf) - 100.0, 0.0, "../../../test_files/images/meadow-110719_640.jpg", 1);

    grp = pdfBeginTransparencyGroup(pdf, 0.0, 0.0, pdfGetPageWidth(pdf), pdfGetPageHeight(pdf), 1, 0, esDeviceGray, -1);
        pdfSetColorSpace(pdf, csDeviceGray);
        sh = pdfCreateRadialShading(pdf, 400.0, 230.0, 20.0, 400.0, 230.0, 150.0, 1.0, 255, 0, 1, 0);
        pdfApplyShading(pdf, sh);
        pdfComputeBBox(pdf, &bbox, cbfNone);
        pdfSetBBox(pdf, pbMediaBox, bbox.Left, bbox.Bottom, bbox.Right, bbox.Top);
    pdfEndTemplate(pdf);

    pdfInitExtGState(&g);
    g.SoftMask = pdfCreateSoftMask(pdf, grp, smtLuminosity, 0);
    gs = pdfCreateExtGState(pdf, &g);

    pdfSetExtGState(pdf, gs);
    pdfInsertImageExA(pdf, 220.0, 80.0, 500.0, 0.0, "../../../test_files/images/tree-frog-69813_640.jpg", 1);

    pdfInitExtGState(&g);
    g.SoftMaskNone = 1;
    gs = pdfCreateExtGState(pdf, &g);
    pdfSetExtGState(pdf, gs);

    pdfWriteTextA(pdf, 50.0, 400.0, "The soft mask is now deactivated.");
    pdfEndPage(pdf);

    if (pdfHaveOpenDoc(pdf) != 0) {
        if (pdfOpenOutputFileA(pdf, "out.pdf") == 0) { pdfDeletePDF(pdf); return 1; }
        if (pdfCloseFile(pdf) != 0) printf("PDF file \"out.pdf\" successfully created!\n");
    }

    pdfDeletePDF(pdf);
    return 0;
}

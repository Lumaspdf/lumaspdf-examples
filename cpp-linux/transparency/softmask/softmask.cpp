// softmask -- C++ mirror of examples\Vb6\transparency\softmask\softmask.bas
// Creates a transparency group used as a luminosity soft mask (radial shading)
// and applies it to an image.
#include "apputil.h"

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
    pdfSetUseTransparency(pdf, 0);

    pdfAppend(pdf);
        pdfSetFontA(pdf, "Helvetica", fsRegular, 12.0, 0, cp1252);
        pdfWriteTextA(pdf, 50, 50, "Transparency effect with a soft mask.");

        pdfInsertImageExA(pdf, 50, 80, pdfGetPageWidth(pdf) - 100, 0, LUMAS_REPO_ROOT "/images/photo_03.jpg", 1);

        // A soft-mask transparency group has no own coordinate system; create it
        // at full page size, then compute the real bounding box afterwards.
        int grp = pdfBeginTransparencyGroup(pdf, 0, 0, pdfGetPageWidth(pdf), pdfGetPageHeight(pdf), 1, 0, esDeviceGray, -1);
            pdfSetColorSpace(pdf, csDeviceGray);
            int sh = pdfCreateRadialShading(pdf, 400, 230, 20, 400, 230, 150, 1, 255, 0, 1, 0);
            pdfApplyShading(pdf, sh);
            TPDFRect bbox;
            pdfComputeBBox(pdf, &bbox, cbfNone);
            pdfSetBBox(pdf, pbMediaBox, bbox.Left, bbox.Bottom, bbox.Right, bbox.Top);
        pdfEndTemplate(pdf);

        TPDFExtGState g;
        pdfInitExtGState(&g);
        g.SoftMask = pdfCreateSoftMask(pdf, grp, smtLuminosity, 0);
        int gs = pdfCreateExtGState(pdf, &g);

        // Activate the mask and draw an image.
        pdfSetExtGState(pdf, gs);
        pdfInsertImageExA(pdf, 220, 80, 500, 0, LUMAS_REPO_ROOT "/images/photo_02.jpg", 1);

        // Deactivate the soft mask.
        pdfInitExtGState(&g);
        g.SoftMaskNone = 1;
        gs = pdfCreateExtGState(pdf, &g);
        pdfSetExtGState(pdf, gs);

        pdfWriteTextA(pdf, 50, 400, "The soft mask is now deactivated.");
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

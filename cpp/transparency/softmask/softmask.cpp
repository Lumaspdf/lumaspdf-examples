// softmask -- C++ mirror of examples\Vb6\transparency\softmask\softmask.bas
// Creates a transparency group used as a luminosity soft mask (radial shading)
// and applies it to an image.
#include "apputil.h"
#include <string>

// The Delphi original passes `string` (UnicodeString), which binds to the
// WideString overload of SetFont/WriteText/InsertImageEx/OpenOutputFile, so the
// reference routes all text through the engine's UTF-16 path. Widen the ASCII
// literals/paths so the W exports can be called with them.
static std::basic_string<LWCHAR> W(const std::string& s){
    return std::basic_string<LWCHAR>(s.begin(), s.end());
}

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main() {
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfCreateNewPDFW(pdf, (LWCHAR*)LUMAS_TEXT(""));
    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetUseTransparency(pdf, 0);

    pdfAppend(pdf);
        pdfSetFontW(pdf, (LWCHAR*)LUMAS_TEXT("Helvetica"), fsRegular, 12.0, 0, cp1252);
        pdfWriteTextW(pdf, 50, 50, (LWCHAR*)LUMAS_TEXT("Transparency effect with a soft mask."));

        pdfInsertImageExW(pdf, 50, 80, pdfGetPageWidth(pdf) - 100, 0, (LWCHAR*)LUMAS_TEXT("../../../test_files/images/meadow-110719_640.jpg"), 1);

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
        pdfInsertImageExW(pdf, 220, 80, 500, 0, (LWCHAR*)LUMAS_TEXT("../../../test_files/images/tree-frog-69813_640.jpg"), 1);

        // Deactivate the soft mask.
        pdfInitExtGState(&g);
        g.SoftMaskNone = 1;
        gs = pdfCreateExtGState(pdf, &g);
        pdfSetExtGState(pdf, gs);

        pdfWriteTextW(pdf, 50, 400, (LWCHAR*)LUMAS_TEXT("The soft mask is now deactivated."));
    pdfEndPage(pdf);

    if (pdfHaveOpenDoc(pdf) != 0) {
        const char* outFile = "out.pdf";
        if (pdfOpenOutputFileW(pdf, (LWCHAR*)W(outFile).c_str()) == 0) { pdfDeletePDF(pdf); return 0; }
        if (pdfCloseFile(pdf) != 0)
            printf("PDF file \"%s\" successfully created!\n", outFile);
    }

    pdfDeletePDF(pdf);
    return 0;
}

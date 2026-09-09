// alpha_transparency -- C++ mirror of
// examples\Vb6\transparency\alpha_transparency\alpha_transparency.bas
// Draws an image at fill alpha 0.5 and a second at the default alpha 1.0 using
// extended graphics states.
#include "apputil.h"
#include <string>

static const unsigned long clWhite = 0xFFFFFF;
static const unsigned long clBlack = 0x0;

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
    pdfSetUseTransparency(pdf, 0); // Disable color key masking for images

    pdfAppend(pdf);
        pdfSetFontW(pdf, (LWCHAR*)LUMAS_TEXT("Helvetica"), fsRegular, 12.0, 0, cp1252);
        pdfWriteTextW(pdf, 50, 50, (LWCHAR*)LUMAS_TEXT("Fill Alpha = 0.5"));

        pdfRectangle(pdf, 50, 70, 110, 160, fmFill);
        pdfSetFillColor(pdf, clWhite);
        pdfWriteTextW(pdf, 55, 75, (LWCHAR*)LUMAS_TEXT("Background"));

        TPDFExtGState g;
        pdfInitExtGState(&g);
        g.FillAlpha = 0.5;
        int gs = pdfCreateExtGState(pdf, &g);
        pdfSetExtGState(pdf, gs);

        int img = pdfInsertImageExW(pdf, 60, 84, 200, 0, (LWCHAR*)LUMAS_TEXT("../../../test_files/images/tree-frog-69813_640.jpg"), 0);

        // Restore by creating a second state that reverts the change.
        g.FillAlpha = 1.0;
        gs = pdfCreateExtGState(pdf, &g);
        pdfSetExtGState(pdf, gs);

        pdfSetFillColor(pdf, clBlack);
        pdfWriteTextW(pdf, 340, 50, (LWCHAR*)LUMAS_TEXT("Fill Alpha = 1.0 (default)"));
        pdfRectangle(pdf, 340, 70, 110, 160, fmFill);
        pdfSetFillColor(pdf, clWhite);
        pdfWriteTextW(pdf, 345, 75, (LWCHAR*)LUMAS_TEXT("Background"));
        pdfPlaceImage(pdf, img, 350, 84, 200, 0);
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

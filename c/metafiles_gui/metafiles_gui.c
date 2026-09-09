/* metafiles_gui -- C port of examples\Vb6\metafiles_gui\metafiles_gui.bas
 * Loads an EMF/WMF, places it centered on a page, writes out.pdf.
 * (The Delphi/VB6 interactive UI is dropped; conversion flags default mfDefault.) */
#include <stdio.h>
#include "lumaspdf.h"
#include "../_common.h"

#define MARGIN 10.0

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void PlaceEMFCentered(PPDF pdf, const char* mFile, double Width, double Height)
{
    double x, y, w, h, sx;
    TRectL r;
    pdfGetLogMetafileSizeA(pdf, mFile, &r);
    w = (double)(r.Right - r.Left);
    h = (double)(r.Bottom - r.Top);
    Width -= 2.0 * MARGIN;
    Height -= 2.0 * MARGIN;
    sx = Width / w;
    if (h * sx <= Height) {
        x = MARGIN; y = MARGIN;
        pdfInsertMetafileA(pdf, mFile, x, y, Width, 0.0);
    } else {
        sx = Height / h;
        w = w * sx;
        x = MARGIN + (Width - w) / 2.0;
        y = MARGIN;
        pdfInsertMetafileA(pdf, mFile, x, y, 0.0, Height);
    }
}

int main(int argc, char** argv)
{
    PPDF pdf;
    char dir[1024], inFile[1100], outFile[1100];
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfSetCompressionFilter(pdf, cfFlate);
    pdfSetJPEGQuality(pdf, 70);

    exedir(argv[0], dir, sizeof(dir));
    _snprintf(inFile, sizeof(inFile), "%s\\in.emf", dir);
    _snprintf(outFile, sizeof(outFile), "%s\\out.pdf", dir);

    if (pdfCreateNewPDFA(pdf, "") == 0) { pdfDeletePDF(pdf); return 1; }

    pdfSetCompressionLevel(pdf, clNone);
    pdfSetCompressionFilter(pdf, cfFlate);
    pdfSetColorSpace(pdf, csDeviceRGB);
    pdfSetMetaConvFlags(pdf, mfDefault);
    pdfSetPageCoords(pdf, pcTopDown);
    pdfAppend(pdf);
    pdfSetResolution(pdf, 300);
    pdfSetJPEGQuality(pdf, 70);
    PlaceEMFCentered(pdf, inFile, pdfGetPageWidth(pdf), pdfGetPageHeight(pdf));
    pdfEndPage(pdf);

    if (pdfHaveOpenDoc(pdf)) {
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfFreePDF(pdf); pdfDeletePDF(pdf); return 1; }
        if (pdfCloseFile(pdf)) printf("OK: %s\n", outFile);
    }
    pdfDeletePDF(pdf);
    return 0;
}

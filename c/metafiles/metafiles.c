/* metafiles -- C port of examples\Vb6\metafiles\metafiles.bas
 * Places three EMF metafiles centered/scaled to landscape pages with a red frame. */
#include <stdio.h>
#include "lumaspdf.h"
#include "../_common.h"

#define CLR_RED 255
#define MARGIN 10.0

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void PlaceEMFCentered(PPDF pdf, const char* MFile, double Width, double Height)
{
    double x, y, w, h, sx;
    TRectL r;

    pdfGetLogMetafileSizeA(pdf, MFile, &r);
    w = (double)(r.Right - r.Left);
    h = (double)(r.Bottom - r.Top);
    Width -= 2.0 * MARGIN;
    Height -= 2.0 * MARGIN;
    sx = Width / w;

    if (h * sx <= Height) {
        x = MARGIN;
        h = h * sx;
        y = (Height - h) / 2.0;
        pdfInsertMetafileA(pdf, MFile, x, y, Width, 0.0);
        pdfSetStrokeColor(pdf, CLR_RED);
        pdfRectangle(pdf, x, y, Width, h, fmStroke);
    } else {
        sx = Height / h;
        w = w * sx;
        x = (Width - w) / 2.0;
        y = MARGIN;
        pdfInsertMetafileA(pdf, MFile, x, y, 0.0, Height);
        pdfSetStrokeColor(pdf, CLR_RED);
        pdfRectangle(pdf, x, y, w, Height, fmStroke);
    }
}

int main(int argc, char** argv)
{
    PPDF pdf;
    char dir[1024], outFile[1100], f1[1100], f2[1100], f3[1100];
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    if (pdfCreateNewPDFA(pdf, "") == 0) { pdfDeletePDF(pdf); return 1; }
    pdfSetPageCoords(pdf, pcTopDown);
    exedir(argv[0], dir, sizeof(dir));
    _snprintf(f1, sizeof(f1), "%s\\coords.emf", dir);
    _snprintf(f2, sizeof(f2), "%s\\fulltest.emf", dir);
    _snprintf(f3, sizeof(f3), "%s\\gdi.emf", dir);
    _snprintf(outFile, sizeof(outFile), "%s\\out.pdf", dir);

    pdfAppend(pdf); pdfSetOrientationEx(pdf, 90);
    PlaceEMFCentered(pdf, f1, pdfGetPageWidth(pdf), pdfGetPageHeight(pdf));
    pdfEndPage(pdf);

    pdfAppend(pdf); pdfSetOrientationEx(pdf, 90);
    PlaceEMFCentered(pdf, f2, pdfGetPageWidth(pdf), pdfGetPageHeight(pdf));
    pdfEndPage(pdf);

    pdfAppend(pdf); pdfSetOrientationEx(pdf, 90);
    PlaceEMFCentered(pdf, f3, pdfGetPageWidth(pdf), pdfGetPageHeight(pdf));
    pdfEndPage(pdf);

    if (pdfHaveOpenDoc(pdf)) {
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfDeletePDF(pdf); return 1; }
    }
    if (pdfCloseFile(pdf))
        printf("PDF file \"%s\" successfully created!\n", outFile);
    pdfDeletePDF(pdf);
    return 0;
}

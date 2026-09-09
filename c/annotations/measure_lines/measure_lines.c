/* measure_lines -- C (x64) port of examples\Vb6\annotations\measure_lines.bas */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define clCream 15793151
#define clBlack 0

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void exedir(const char* a0, char* out, size_t n){char* s;strncpy(out,a0,n-1);out[n-1]=0;s=strrchr(out,'\\');if(!s)s=strrchr(out,'/');if(s)*s=0;else strcpy(out,".");}

int main(int argc, char** argv)
{
    SI32 a;
    double x, y, w, h;
    PPDF pdf;
    char dir[1024], outFile[1200], txt[64];
    TLineAnnotParms p;

    exedir(argv[0], dir, sizeof(dir));
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);

    w = 300.0;
    h = 100.0;
    x = pdfGetPageWidth(pdf) / 2;
    y = pdfGetPageHeight(pdf) / 2;

    pdfSaveGraphicState(pdf);

    pdfSetGStateFlags(pdf, gfRealTopDownCoords, 0);
    pdfRotateCoords(pdf, -30.0, x, y);

    x = -w / 2;
    y = -h / 2;

    pdfSetFillColor(pdf, clCream);
    pdfRectangle(pdf, x, y, w, h, fmFillStroke);

    _snprintf(txt, sizeof(txt), "%.1f", w);
    a = pdfLineAnnotA(pdf, x, y, x + w, y, 1.0, leClosedArrow, leClosedArrow, clBlack, clBlack, csDeviceRGB, "This is a measure line", "Measure Line", txt);

    memset(&p, 0, sizeof(p));
    p.StructSize = sizeof(p);
    p.Caption = 1;              /* Content of LineAnnot() is used as caption. */
    p.LeaderLineLen = 10.0f;
    p.LeaderLineExtend = 4.0f;
    p.LeaderLineOffset = 2.0f;
    pdfSetLineAnnotParms(pdf, a, -1, 0.0, &p);

    _snprintf(txt, sizeof(txt), "%.1f", h);
    a = pdfLineAnnotA(pdf, x, y + h, x, y, 1.0, leClosedArrow, leClosedArrow, clBlack, clBlack, csDeviceRGB, "This is a measure line", "Measure Line", txt);
    pdfSetLineAnnotParms(pdf, a, -1, 0.0, &p);

    pdfRestoreGraphicState(pdf);

    pdfEndPage(pdf);

    if (pdfHaveOpenDoc(pdf) != 0) {
        _snprintf(outFile, sizeof(outFile), "%s\\out.pdf", dir);
        if (pdfOpenOutputFileA(pdf, outFile) == 0) {
            pdfDeletePDF(pdf);
            return 0;
        }
        if (pdfCloseFile(pdf) != 0)
            printf("PDF file \"%s\" successfully created!\n", outFile);
    }

    pdfDeletePDF(pdf);
    return 0;
}

/* quad_points -- C (x64) port of examples\Vb6\annotations\quad_points.bas */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define clYellow 65535
#define clRed    255
#define clBlue   16711680

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void exedir(const char* a0, char* out, size_t n){char* s;strncpy(out,a0,n-1);out[n-1]=0;s=strrchr(out,'\\');if(!s)s=strrchr(out,'/');if(s)*s=0;else strcpy(out,".");}

static void IncY(TFltPoint* points, int n, float Value)
{
    int i;
    for (i = 0; i < n; i++)
        points[i].y += Value;
}

int main(int argc, char** argv)
{
    SI32 a;
    float d, w;
    PPDF pdf;
    char dir[1024], outFile[1200];
    const char* text;
    TFltPoint points[4];

    exedir(argv[0], dir, sizeof(dir));
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);

    pdfSaveGraphicState(pdf);

    pdfSetGStateFlags(pdf, gfRealTopDownCoords, 0);
    pdfRotateCoords(pdf, -30.0, 50.0, 200.0);

    text = "Some rotated text on a page...";
    pdfSetFontA(pdf, "Helvetica", fsRegular, 20.0, 0, cp1252);

    d = (float)pdfGetDescent(pdf);
    w = (float)pdfGetTextWidthA(pdf, text);

    pdfWriteTextA(pdf, 0.0, 0.0, text);
    a = pdfHighlightAnnotA(pdf, atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, "Test app", "Highligh Annotations", "This is a highlight annotation");
    points[0].x = 0.0f;  points[0].y = d;          /* Top left corner */
    points[1].x = w;     points[1].y = d;          /* Top right corner */
    points[2].x = 0.0f;  points[2].y = 20.0f + d;  /* Bottom left corner */
    points[3].x = w;     points[3].y = 20.0f + d;  /* Bottom right corner */
    pdfSetAnnotQuadPoints(pdf, a, &points[0], 4);

    pdfWriteTextA(pdf, 0.0, 30.0, text);
    a = pdfHighlightAnnotA(pdf, atSquiggly, 50.0, 80.0, w, 20.0, clRed, "Test app", "Squiggly Annotations", "This is a squiggly annotation");
    IncY(points, 4, 30.0f);
    pdfSetAnnotQuadPoints(pdf, a, &points[0], 4);

    pdfWriteTextA(pdf, 0.0, 60.0, text);
    a = pdfHighlightAnnotA(pdf, atStrikeOut, 50.0, 110.0, w, 20.0, clRed, "Test app", "Strikeout Annotations", "This is a strikeout annotation");
    IncY(points, 4, 30.0f);
    pdfSetAnnotQuadPoints(pdf, a, &points[0], 4);

    pdfWriteTextA(pdf, 0.0, 90.0, text);
    a = pdfHighlightAnnotA(pdf, atUnderline, 50.0, 140.0, w, 20.0, clRed, "Test app", "Underline Annotations", "This is a underline annotation");
    IncY(points, 4, 30.0f);
    pdfSetAnnotQuadPoints(pdf, a, &points[0], 4);

    text = "Link annotations support quad points too";
    w = (float)pdfGetTextWidthA(pdf, text);
    pdfWriteTextA(pdf, 0.0, 120.0, text);
    a = pdfWebLinkA(pdf, 0.0, 120.0, w, 20.0, "www.lumaspdf.com");
    pdfSetAnnotBorderWidth(pdf, a, 1.0);
    pdfSetAnnotColor(pdf, a, fcBorderColor, csDeviceRGB, clBlue);
    points[0].x = 0.0f;  points[0].y = 120.0f + d;  /* Top left corner */
    points[1].x = w;     points[1].y = 120.0f + d;  /* Top right corner */
    points[2].x = 0.0f;  points[2].y = 140.0f + d;  /* Bottom left corner */
    points[3].x = w;     points[3].y = 140.0f + d;  /* Bottom right corner */
    pdfSetAnnotQuadPoints(pdf, a, &points[0], 4);

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

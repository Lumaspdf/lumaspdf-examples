/* highlight_annotations -- C (x64) port of examples\Vb6\annotations\highlight_annotations.bas */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define clYellow 65535
#define clRed    255

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void exedir(const char* a0, char* out, size_t n){char* s;strncpy(out,a0,n-1);out[n-1]=0;s=strrchr(out,'\\');if(!s)s=strrchr(out,'/');if(s)*s=0;else strcpy(out,".");}

int main(int argc, char** argv)
{
    double d, w;
    PPDF pdf;
    char dir[1024], outFile[1200];
    const char* text = "Some text on a page...";

    exedir(argv[0], dir, sizeof(dir));
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);
    pdfSetFontA(pdf, "Helvetica", fsRegular, 20.0, 0, cp1252);

    d = pdfGetDescent(pdf);
    w = pdfGetTextWidthA(pdf, text);

    pdfWriteTextA(pdf, 50.0, 50.0, text);
    pdfHighlightAnnotA(pdf, atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, "Test app", "Highligh Annotations", "This is a highlight annotation");

    pdfWriteTextA(pdf, 50.0, 80.0, text);
    pdfHighlightAnnotA(pdf, atSquiggly, 50.0, 80.0 + d, w, 20.0, clRed, "Test app", "Squiggly Annotations", "This is a squiggly annotation");

    pdfWriteTextA(pdf, 50.0, 110.0, text);
    pdfHighlightAnnotA(pdf, atStrikeOut, 50.0, 110.0 + d, w, 20.0, clRed, "Test app", "Strikeout Annotations", "This is a strikeout annotation");

    pdfWriteTextA(pdf, 50.0, 140.0, text);
    pdfHighlightAnnotA(pdf, atUnderline, 50.0, 140.0 + d, w, 20.0, clRed, "Test app", "Underline Annotations", "This is a underline annotation");
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

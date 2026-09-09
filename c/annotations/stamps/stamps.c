/* stamps -- C (x64) port of examples\Vb6\annotations\stamps.bas */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define RGB(r,g,b) ((UI32)((UI32)(r) | ((UI32)(g) << 8) | ((UI32)(b) << 16)))

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
    PPDF pdf;
    char dir[1024], outFile[1200];

    exedir(argv[0], dir, sizeof(dir));
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);

    a = pdfStampAnnotA(pdf, rsApproved, 135.0, 50.0, 300.0, 10.0, "Test app", "Stamp Annotations", "The default language is English!");
    pdfSetAnnotColor(pdf, a, fcBorderColor, csDeviceRGB, RGB(120, 190, 92));

    pdfSetLanguage(pdf, "DE");
    a = pdfStampAnnotA(pdf, rsApproved, 135.0, 150.0, 300.0, 10.0, "Test app", "Stamp Annotations", "The same stamp in German!");
    pdfSetAnnotColor(pdf, a, fcBorderColor, csDeviceRGB, RGB(230, 65, 132));

    pdfSetLanguage(pdf, "FR");
    a = pdfStampAnnotA(pdf, rsApproved, 135.0, 250.0, 300.0, 10.0, "Test app", "Stamp Annotations", "The same stamp in French!");
    pdfSetAnnotColor(pdf, a, fcBorderColor, csDeviceRGB, RGB(78, 157, 232));
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

/* migration_states -- C (x64) port of examples\Vb6\annotations\migration_states.bas */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define NO_COLOR 0xFFFFFFF1u   /* transparent */

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void exedir(const char* a0, char* out, size_t n){char* s;strncpy(out,a0,n-1);out[n-1]=0;s=strrchr(out,'\\');if(!s)s=strrchr(out,'/');if(s)*s=0;else strcpy(out,".");}

int main(int argc, char** argv)
{
    SI32 annot, reply;
    PPDF pdf;
    char dir[1024], outFile[1200];

    exedir(argv[0], dir, sizeof(dir));
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);
    annot = pdfSquareAnnotA(pdf, 50.0, 50.0, 200.0, 100.0, 3.0, NO_COLOR, 255, csDeviceRGB, "Jim", "Test", "Just test...");
    reply = pdfSetAnnotMigrationStateA(pdf, annot, asCompleted, "Harry");
    pdfSetAnnotStringA(pdf, reply, asContent, "The state was set to Completed!");

    reply = pdfSetAnnotMigrationStateA(pdf, reply, asAccepted, "Jim");
    pdfSetAnnotStringA(pdf, reply, asContent, "The state was set to Accepted!");
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

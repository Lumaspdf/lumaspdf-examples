/* pdf_to_text -- C port of examples\Vb6\pdf_to_text\pdf_to_text.bas
 * Imports a PDF and writes each page's text to out.txt. */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"
#include "../_common.h"

#define emNoFuncNames 0x10000000 /* not in wrapper enum; from dynapdf.pas */

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(int argc, char** argv)
{
    PPDF pdf;
    char dir[1024], inFile[1100], outFile[1100], cmap[1100];
    SI32 i, count;
    FILE* f;
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetErrorMode(pdf, emNoFuncNames);
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    exedir(argv[0], dir, sizeof(dir));
    _snprintf(cmap, sizeof(cmap), "%s\\CMap", dir);
    pdfSetCMapDirA(pdf, cmap, lcmRecursive | lcmDelayed);

    if (pdfCreateNewPDFA(pdf, "") == 0) { pdfDeletePDF(pdf); return 1; }

    pdfSetImportFlags(pdf, ifContentOnly | ifImportAsPage);
    _snprintf(inFile, sizeof(inFile), "%s\\in.pdf", dir);
    if (pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0) { pdfFreePDF(pdf); pdfDeletePDF(pdf); return 1; }
    if (pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0) { pdfFreePDF(pdf); pdfDeletePDF(pdf); return 1; }
    pdfCloseImportFile(pdf);

    _snprintf(outFile, sizeof(outFile), "%s\\out.txt", dir);
    f = fopen(outFile, "w");
    if (!f) { pdfFreePDF(pdf); pdfDeletePDF(pdf); return 1; }

    count = pdfGetPageCount(pdf);
    for (i = 1; i <= count; i++) {
        char* txt;
        fprintf(f, "----- Page %d -----\n", i);
        pdfEditPage(pdf, i);
        txt = pdfSplitPageTextA(pdf, i);
        fprintf(f, "%s\n", txt ? txt : "");
        pdfEndPage(pdf);
    }
    fclose(f);
    pdfFreePDF(pdf);
    printf("Text written to: %s\n", outFile);
    pdfDeletePDF(pdf);
    return 0;
}

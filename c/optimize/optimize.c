/* optimize -- C port of examples\Vb6\optimize\optimize.bas
 * Imports a PDF, runs Optimize() and writes the result. */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"
#include "../_common.h"

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0; /* continue */
}

static int Optimize(PPDF pdf, const char* InFile, const char* OutFile)
{
    SI32 i, n;
    TPDFError e;

    pdfCreateNewPDFA(pdf, "");
    pdfSetDocInfoA(pdf, diProducer, ""); /* keep original producer */

    pdfSetImportFlags(pdf, (ifImportAll | ifImportAsPage) & ~ifPieceInfo);
    pdfSetImportFlags2(pdf, if2UseProxy | if2DuplicateCheck | if2Normalize | if2NoResNameCheck);
    if (pdfOpenImportFileA(pdf, InFile, ptOpen, "") < 0) { pdfFreePDF(pdf); return 0; }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);

    pdfOptimize(pdf, ofInMemory | ofNewLinkNames | ofDeleteInvPaths, 0);

    memset(&e, 0, sizeof(e));
    e.StructSize = sizeof(e);
    n = pdfGetErrLogMessageCount(pdf);
    for (i = 0; i < n; i++) {
        pdfGetErrLogMessage(pdf, i, &e);
        if (e.Msg) printf("%s\n", e.Msg);
    }

    if (pdfHaveOpenDoc(pdf)) {
        if (pdfOpenOutputFileA(pdf, OutFile) == 0) { pdfFreePDF(pdf); return 0; }
        return pdfCloseFile(pdf) != 0;
    }
    return 0;
}

int main(int argc, char** argv)
{
    PPDF pdf;
    char dir[1024], outFile[1100], inFile[1100], cmap[1100];
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);
    exedir(argv[0], dir, sizeof(dir));
    _snprintf(cmap, sizeof(cmap), "%s\\CMap", dir);
    pdfSetCMapDirA(pdf, cmap, lcmDelayed | lcmRecursive);

    _snprintf(outFile, sizeof(outFile), "%s\\out.pdf", dir);
    _snprintf(inFile, sizeof(inFile), "%s\\dynapdf_help.pdf", dir);
    if (Optimize(pdf, inFile, outFile))
        printf("PDF file \"%s\" successfully created!\n", outFile);
    pdfDeletePDF(pdf);
    return 0;
}

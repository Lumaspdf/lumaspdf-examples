/* ============================================================================
 *  collections -- C (x64/MSVC) port of examples\Vb6\collections\collections.bas
 *  Imports a cover page, creates a PDF portfolio (collection) and attaches
 *  three files to it.
 * ========================================================================= */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

static void exedir(const char* a0, char* out, size_t n) {
    char* s;
    strncpy(out, a0, n - 1); out[n - 1] = 0;
    s = strrchr(out, '\\'); if (!s) s = strrchr(out, '/');
    if (s) *s = 0; else strcpy(out, ".");
}

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    printf("%s\n", ErrMessage);
    return 0;
}

int main(int argc, char** argv) {
    SI32 ef;
    PPDF pdf;
    char dir[1024], outFile[1100];

    pdf = pdfNewPDF();
    pdfCreateNewPDFA(pdf, "");
    pdfSetOnErrorProc(pdf, 0, ErrProc);

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    if (pdfOpenImportFileA(pdf, "../../test_files/collection_en.pdf", ptOpen, "") < 0) {
        pdfDeletePDF(pdf);
        printf("Input file \"../../test_files/collection_en.pdf\" not found!\n");
        return 0;
    }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);
    pdfCreateCollection(pdf, civTile);

    ef = pdfAttachFileA(pdf, "../../test_files/taxform.pdf", "A PDF file...", 1);
    pdfSetColDefFile(pdf, ef);
    pdfAttachFileA(pdf, "../../test_files/fulltest.emf", "An EMF file...", 1);
    pdfAttachFileA(pdf, "../../test_files/sample.txt", "A text file...", 1);

    outFile[0] = 0;
    if (pdfHaveOpenDoc(pdf) != 0) {
        exedir(argv[0], dir, sizeof(dir));
        sprintf(outFile, "%s\\out.pdf", dir);
        if (pdfOpenOutputFileA(pdf, outFile) == 0) {
            pdfDeletePDF(pdf);
            return 0;
        }
    }
    pdfCloseFile(pdf);
    printf("PDF Collection \"%s\" successfully created!\n", outFile);
    pdfDeletePDF(pdf);
    (void)argc;
    return 0;
}

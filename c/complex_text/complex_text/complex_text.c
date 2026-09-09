/* ============================================================================
 *  complex_text -- C (x64) port of the VB6 mirror
 *  examples\Vb6\complex_text\complex_text\complex_text.bas
 *  Complex text layout of a right-to-left (Pashto) text loaded as UTF-16 and
 *  laid out with the wide version of WriteFTextEx().
 * ========================================================================== */
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include "lumaspdf.h"

#define TXT_FILE "E:\\LUMASPDFSDK\\examples\\test_files\\pashto.txt"

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    printf("%s\n", ErrMessage ? ErrMessage : "");
    return 0;
}

static void exedir(const char* a0, char* out, size_t n)
{
    char* s;
    strncpy(out, a0, n - 1); out[n - 1] = 0;
    s = strrchr(out, '\\'); if (!s) s = strrchr(out, '/');
    if (s) *s = 0; else strcpy(out, ".");
}

static LWCHAR* GetFileBuffer(const char* FileName)
{
    FILE* f; long n; char* b;
    f = fopen(FileName, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END); n = ftell(f); fseek(f, 0, SEEK_SET);
    if (n < 0) { fclose(f); return NULL; }
    b = (char*)malloc(n + 2);
    if (!b) { fclose(f); return NULL; }
    if (n > 0) fread(b, 1, n, f);
    fclose(f);
    b[n] = 0; b[n + 1] = 0;
    return (LWCHAR*)b;
}

int main(int argc, char** argv)
{
    PPDF pdf;
    LWCHAR* txt;
    char dir[1024], outFile[1200];

    exedir(argv[0], dir, sizeof(dir));

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    txt = GetFileBuffer(TXT_FILE);

    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetGStateFlags(pdf, gfComplexText, 0);
    pdfSetBidiMode(pdf, bmRightToLeft);

    pdfAppend(pdf);

    pdfSetFontA(pdf, "Arial", fsRegular, 10.0, 1, cpUnicode);
    pdfSetLeading(pdf, pdfGetTypoLeading(pdf));
    pdfWriteFTextExW(pdf, 50.0, 50.0,
                     pdfGetPageWidth(pdf) - 100.0,
                     pdfGetPageHeight(pdf) - 100.0, taJustify, txt);

    free(txt);
    pdfEndPage(pdf);

    outFile[0] = 0;
    if (pdfHaveOpenDoc(pdf) != 0) {
        sprintf(outFile, "%s\\out.pdf", dir);
        if (pdfOpenOutputFileA(pdf, outFile) == 0) {
            pdfDeletePDF(pdf);
            return 0;
        }
    }
    if (pdfCloseFile(pdf) != 0)
        printf("PDF file \"%s\" successfully created!\n", outFile);

    pdfDeletePDF(pdf);
    return 0;
}

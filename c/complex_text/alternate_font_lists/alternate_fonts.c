/* ============================================================================
 *  alternate_fonts -- C (x64) port of the VB6 mirror
 *  examples\Vb6\complex_text\alternate_font_lists\alternate_fonts.bas
 *  Complex text layout with an alternate font list to improve font
 *  substitution. Multi-language text loaded as UTF-16 and laid out with the
 *  wide version of WriteFTextEx().
 * ========================================================================== */
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include "lumaspdf.h"

#define TXT_FILE "E:\\LUMASPDFSDK\\examples\\test_files\\multi_lang.txt"

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    printf("%s\n", ErrMessage ? ErrMessage : "");
    return 0;   /* We try to continue if an error occurs */
}

static void exedir(const char* a0, char* out, size_t n)
{
    char* s;
    strncpy(out, a0, n - 1); out[n - 1] = 0;
    s = strrchr(out, '\\'); if (!s) s = strrchr(out, '/');
    if (s) *s = 0; else strcpy(out, ".");
}

/* Reads a file raw as UTF-16 (2 bytes per char), NUL terminated. */
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
    SI32 altFonts;
    char dir[1024], outFile[1200];
    /* Alternate fonts, sorted alphabetically. */
    LWCHAR* fonts[5] = {
        L"Malgun Gothic",   /* Korean */
        L"Mangal",          /* Hindi or Marathi */
        L"Nyala",           /* Amharic */
        L"Shonar Bangla",   /* Bengali */
        L"Shruti"           /* Gujarati */
    };

    exedir(argv[0], dir, sizeof(dir));

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");           /* We create no PDF file in this example */

    txt = GetFileBuffer(TXT_FILE);

    pdfSetPageCoords(pdf, pcTopDown);
    /* Enable complex text layout */
    pdfSetGStateFlags(pdf, gfComplexText, 0);

    altFonts = pdfCreateAltFontList(pdf);
    pdfSetAltFontsW(pdf, altFonts, fonts, 5);

    pdfAppend(pdf);

    /* The font must be loaded with cpUnicode. */
    pdfSetFontA(pdf, "Arial", fsRegular, 10.0, 1, cpUnicode);
    /* Activate the alternate font list */
    pdfActivateAltFontList(pdf, altFonts, 1);

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

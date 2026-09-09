/* edit_text -- C port of examples\Vb6\edit_text\edit_text.bas */
#include <stdio.h>
#include <string.h>
#include <wchar.h>
#include "lumaspdf.h"

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    printf("%s\n", ErrMessage);
    return 0;
}

static void exedir(const char* a0, char* out, size_t n)
{
    char* s;
    strncpy(out, a0, n - 1); out[n - 1] = 0;
    s = strrchr(out, '\\'); if (!s) s = strrchr(out, '/');
    if (s) *s = 0; else strcpy(out, ".");
}

int main(int argc, char** argv)
{
    PPDF pdf;
    IPSR ctx;
    SI32 i;
    char dir[1024], inFile[1100], outFile[1100];
    TContent content;
    TTextSelection sel;
    LWCHAR searchText[] = L"PDF";
    LWCHAR replaceText[] = L"XDF";

    exedir(argv[0], dir, sizeof(dir));
    (void)argc;

    pdf = pdfNewPDF();
    pdfCreateNewPDFA(pdf, "");
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);

    sprintf(inFile, "%s\\dynapdf_help.pdf", dir);
    if (pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0) { pdfDeletePDF(pdf); return 0; }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);

    ctx = psrCreateParserContext(pdf, ofDefault, 0);

    for (i = 1; i <= pdfGetPageCount(pdf); i++) {
        if (psrParsePage(pdf, ctx, 0, 0, i, cpfEnableTextSelection, 0, &content) != 0) {
            PTextSelection curr = 0;
            while (psrFindText(pdf, ctx, 0, stDefault, curr, searchText, (UI32)wcslen(searchText), &sel) != 0) {
                psrReplaceSelText(pdf, ctx, rtfDefault, &sel, replaceText, (UI32)wcslen(replaceText));
                curr = &sel;
            }
            psrWriteToPage(pdf, ctx, ofDefault, 0);
        }
    }
    psrDeleteParserContext(&ctx);

    if (pdfHaveOpenDoc(pdf) != 0) {
        sprintf(outFile, "%s\\out.pdf", dir);
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfDeletePDF(pdf); return 0; }
    }
    if (pdfCloseFile(pdf) != 0)
        printf("PDF file \"%s\" successfully created!\n", outFile);
    pdfDeletePDF(pdf);
    return 0;
}

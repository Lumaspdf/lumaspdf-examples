/* text_extraction3 -- C port of examples\Vb6\text_extraction3
   Imports a PDF and extracts its text page by page with pdfExtractText, then
   writes the result to out.txt as UTF-16LE (with BOM). */
#include <stdio.h>
#include <wchar.h>
#include "lumaspdf.h"

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void WritePageIdentifier(FILE* f, int PageNum) {
    wchar_t buf[96];
    if (PageNum > 1) { wchar_t nl[] = L"\r\n"; fwrite(nl, 2, 2, f); }
    swprintf(buf, 96, L"%%----------------------- Page %d -----------------------------\r\n", PageNum);
    fwrite(buf, 2, wcslen(buf), f);
}

int main(void) {
    PPDF pdf = pdfNewPDF();
    int i, cnt;
    FILE* f;
    unsigned char bom[2] = { 0xFF, 0xFE };
    LWCHAR* textPtr; UI32 textLen;

    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetCMapDirA(pdf, "CMap", lcmRecursive | lcmDelayed);

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    if (pdfOpenImportFileA(pdf, "in.pdf", ptOpen, "") < 0) { pdfDeletePDF(pdf); return 1; }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);

    pdfFlattenAnnots(pdf, affMarkupAnnots);
    pdfFlattenForm(pdf);

    f = fopen("out.txt", "wb");
    if (!f) { pdfDeletePDF(pdf); return 1; }
    fwrite(bom, 1, 2, f);

    cnt = pdfGetPageCount(pdf);
    for (i = 1; i <= cnt; i++) {
        WritePageIdentifier(f, i);
        textPtr = 0; textLen = 0;
        if (pdfExtractText(pdf, i, tefDeleteOverlappingText | tefSortTextX, 0, &textPtr, &textLen) != 0) {
            if (textLen > 0 && textPtr) fwrite(textPtr, 2, textLen, f);
        }
    }
    fclose(f);

    printf("Text successfully extracted to out.txt\n");
    pdfDeletePDF(pdf);
    return 0;
}

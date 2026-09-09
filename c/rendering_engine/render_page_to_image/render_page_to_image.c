/* render_page_to_image -- C port of
   examples\Vb6\rendering_engine\render_page_to_image
   Loads a PDF, imports the first page and renders it to a TIFF image file. */
#include <stdio.h>
#include "lumaspdf.h"

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
extern HDC __stdcall GetDC(HWND hWnd);
extern int __stdcall GetDeviceCaps(HDC hdc, int index);
extern int __stdcall ReleaseDC(HWND hWnd, HDC hdc);
#define HORZRES 8

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(void) {
    PPDF pdf = pdfNewPDF();
    HDC dc; int w;

    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    if (pdfOpenImportFileA(pdf, "../../../../sample_multipage.pdf", ptOpen, "") < 0) {
        pdfDeletePDF(pdf); return 1;
    }

    pdfAppend(pdf);
        pdfImportPageEx(pdf, 1, 1.0, 1.0);
    pdfEndPage(pdf);

    dc = GetDC(0);
    w = GetDeviceCaps(dc, HORZRES);
    ReleaseDC(0, dc);

    if (pdfRenderPageToImageA(pdf, 1, "out.tif", 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) != 0)
        printf("TIFF image \"out.tif\" successfully created!\n");

    pdfDeletePDF(pdf);
    return 0;
}

/* render_page -- C port of examples\Vb6\rendering_engine\render_page
   Loads a PDF, imports the first page and renders it to a TIFF image file.
   (The off-screen/on-screen rasterizer DC APIs are not in the flat wrapper;
   this mirrors the achievable core: render the page to an image file.) */
#include <stdio.h>
#include "lumaspdf.h"

/* Minimal Win32 decls (lumaspdf.h already typedefs HDC/HWND as size_t, so we
   cannot include windows.h here). */
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
    HDC dc; int w; SI32 pageCount;

    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfCreateNewPDFA(pdf, "");   /* We create no PDF file in this example */

    pdfSetCMapDirA(pdf, "..\\..\\..\\Resource\\CMap\\", lcmRecursive | lcmDelayed);

    if (pdfOpenImportFileA(pdf, "../../../../sample_multipage.pdf", ptOpen, "") < 0) {
        pdfDeletePDF(pdf); return 1;
    }

    pdfSetImportFlags(pdf, ifContentOnly);
    pdfImportCatalogObjects(pdf);
    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    pdfSetImportFlags2(pdf, if2UseProxy);

    pageCount = pdfGetInPageCount(pdf);
    if (pageCount < 1) { pdfDeletePDF(pdf); return 1; }

    pdfAppend(pdf);
        pdfImportPageEx(pdf, 1, 1.0, 1.0);
    pdfEndPage(pdf);

    if (pdfGetPageObject(pdf, 1) == 0) { pdfDeletePDF(pdf); return 1; }

    dc = GetDC(0);
    w = GetDeviceCaps(dc, HORZRES);
    ReleaseDC(0, dc);

    if (pdfRenderPageToImageA(pdf, 1, "render_page.tif", 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) != 0)
        printf("Rendered page 1 to render_page.tif\n");

    pdfDeletePDF(pdf);
    return 0;
}

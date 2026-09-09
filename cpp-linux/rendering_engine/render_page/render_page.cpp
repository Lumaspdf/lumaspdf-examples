// render_page -- C++ port of examples\Vb6\rendering_engine\render_page\render_page.bas
// Loads a PDF, imports the first page and renders it to a TIFF image file.
#include "apputil.h"

#ifndef HORZRES
#define HORZRES 8
#endif

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(){
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);
    pdfCreateNewPDFA(pdf, "");   // We create no PDF file in this example

    // Absolute path recommended. lcmDelayed loads the cmaps only if necessary.
    pdfSetCMapDirA(pdf, "../../../Resource/CMap/", lcmRecursive | lcmDelayed);

    if(pdfOpenImportFileA(pdf, LUMAS_REPO_ROOT "/sample_multipage.pdf", ptOpen, "") < 0){
        pdfDeletePDF(pdf);
        return 0;
    }

    // Import pages manually: only the output intent is needed for color management, then reset.
    pdfSetImportFlags(pdf, ifContentOnly);
    pdfImportCatalogObjects(pdf);
    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    pdfSetImportFlags2(pdf, if2UseProxy);

    SI32 pageCount = pdfGetInPageCount(pdf);
    if(pageCount < 1){ pdfDeletePDF(pdf); return 0; }

    pdfAppend(pdf);
    pdfImportPageEx(pdf, 1, 1.0, 1.0);
    pdfEndPage(pdf);

    if(pdfGetPageObject(pdf, 1) == 0){ pdfDeletePDF(pdf); return 0; }

    void* dc = GetDC(0);
    int w = GetDeviceCaps(dc, HORZRES);
    ReleaseDC(0, dc);

    const char* outFile = "render_page.tif";
    if(pdfRenderPageToImageA(pdf, 1, outFile, 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) != 0)
        printf("Rendered page 1 to %s\n", outFile);

    pdfDeletePDF(pdf);
    return 0;
}

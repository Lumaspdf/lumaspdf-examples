// render_page_to_image -- C++ port of
//   examples\Vb6\rendering_engine\render_page_to_image\render_page_to_image.bas
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

    // Import anything and don't convert pages to templates
    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    if(pdfOpenImportFileA(pdf, LUMAS_REPO_ROOT "/sample_multipage.pdf", ptOpen, "") < 0){
        pdfDeletePDF(pdf);
        return 0;
    }

    pdfAppend(pdf);
    pdfImportPageEx(pdf, 1, 1.0, 1.0);
    pdfEndPage(pdf);

    void* dc = GetDC(0);
    int w = GetDeviceCaps(dc, HORZRES);
    ReleaseDC(0, dc);

    const char* filePath = "out.tif";
    if(pdfRenderPageToImageA(pdf, 1, filePath, 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) != 0)
        printf("TIFF image \"%s\" successfully created!\n", filePath);

    pdfDeletePDF(pdf);
    return 0;
}

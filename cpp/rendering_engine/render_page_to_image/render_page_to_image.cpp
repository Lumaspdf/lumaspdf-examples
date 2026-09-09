// render_page_to_image -- C++ port of
//   examples\Vb6\rendering_engine\render_page_to_image\render_page_to_image.bas
// Loads a PDF, imports the first page and renders it to a TIFF image file.
#include "apputil.h"
#include <string>

#ifndef HORZRES
#define HORZRES 8
#endif

// The Delphi original's TPDF.CreateNewPDF / OpenImportFile / RenderPageToImage
// resolve to the UNICODE (*W) exports, so this port calls those too rather than
// the *A twins. LWCHAR is wchar_t on Windows and char16_t elsewhere -- hence
// basic_string<LWCHAR> and LUMAS_TEXT() instead of u"..." (rejected by MSVC) or
// L"..." (4 bytes wide, and therefore wrong, off Windows).
typedef std::basic_string<LWCHAR> ustring;
static ustring Widen(const char* s) { ustring o; while (*s) o.push_back((LWCHAR)(unsigned char)*s++); return o; }
static LWCHAR* W(ustring& s) { return const_cast<LWCHAR*>(s.c_str()); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(){
    ChdirToExe();
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, PDFError);
    ustring empty;
    pdfCreateNewPDFW(pdf, W(empty));   // We create no PDF file in this example

    // Import anything and don't convert pages to templates
    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    ustring inFile = Widen("../../../../dynapdf_help.pdf");
    if(pdfOpenImportFileW(pdf, W(inFile), ptOpen, "") < 0){
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
    ustring filePathW = Widen(filePath);
    if(pdfRenderPageToImageW(pdf, 1, W(filePathW), 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) != 0)
        printf("TIFF image \"%s\" successfully created!\n", filePath);

    pdfDeletePDF(pdf);
    return 0;
}

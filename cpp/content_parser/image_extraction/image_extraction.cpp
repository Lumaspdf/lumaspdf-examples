// image_extraction -- C++ port of
//   examples\Vb6\content_parser\image_extraction\image_extraction.bas
// Imports dynapdf_help.pdf and extracts every image into a multi-page TIFF by
// parsing each page's content stream. Templates and image objects are
// de-duplicated so each is handled once. The pdf handle is passed as the
// parser Data pointer.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>
#include <vector>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

// De-dup lists (Delphi used two TList of pointers).
static std::vector<void*> g_Images;
static std::vector<SI32>  g_Templates;

static bool FindImg(void* v){
    for(void* p : g_Images) if(p == v) return true;
    return false;
}
static bool FindTempl(SI32 v){
    for(SI32 p : g_Templates) if(p == v) return true;
    return false;
}

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;   // We try to continue if an error occurs
}

// ------------------------- parse callbacks -------------------------
static SI32 PDF_CALL parseBeginTemplate(void* Data, void* PDFObject, SI32 Handle, TPDFRect* BBox, PCTM Matrix){
    if(FindTempl(Handle))
        return 1;                 // Skip the template
    g_Templates.push_back(Handle);
    return 0;
}

static SI32 PDF_CALL parseInsertImage(void* Data, TPDFImage* Image){
    if(Image->InlineImage == 0){
        if(FindImg(Image->ObjectPtr)) return 0;   // Already handled?
        g_Images.push_back(Image->ObjectPtr);
    }
    // If an image cannot be decompressed we may get a compressed image here.
    if(Image->Filter != dfNone) return 0;
    // Note that Flate compression is no standard filter.
    if(Image->BitsPerPixel == 1)
        pdfAddImage((PPDF)Data, cfCCITT4, icNone, Image);
    else
        pdfAddImage((PPDF)Data, cfLZW, icNone, Image);
    return 0;
}

int main(int argc, char** argv){
    TPDFParseInterface stack{};
    stack.BeginTemplate = parseBeginTemplate;
    stack.InsertImage   = parseInsertImage;

    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    pdfCreateNewPDFA(pdf, "");            // We create no PDF file yet

    // We avoid the conversion of pages to templates.
    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    const char* inFile = LUMAS_REPO_ROOT "/dynapdf_help.pdf";
    if(pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0){
        printf("Input file \"dynapdf_help.pdf\" not found!\n");
        pdfDeletePDF(pdf);
        return 0;
    }
    if(pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0){
        pdfDeletePDF(pdf);
        return 0;
    }
    // Flatten form fields so that we can extract images of these objects too.
    pdfFlattenForm(pdf);

    std::string outFile = exeDir(argv[0]) + "/out.tif";

    // We create a multi-page TIFF in this example.
    if(pdfCreateImageA(pdf, outFile.c_str(), ifmTIFF) == 0){
        pdfDeletePDF(pdf);
        return 0;
    }
    for(SI32 i = 1; i <= pdfGetPageCount(pdf); i++){
        pdfEditPage(pdf, i);
        pdfParseContent(pdf, pdf, &stack, pfDecomprAllImages);
        pdfEndPage(pdf);
    }
    if(pdfCloseImage(pdf) != 0)
        printf("TIFF image \"%s\" successfully created!\n", outFile.c_str());

    pdfDeletePDF(pdf);
    return 0;
}

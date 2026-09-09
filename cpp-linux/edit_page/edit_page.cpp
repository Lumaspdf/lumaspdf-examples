// edit_page -- C++ port of examples\Vb6\edit_page\edit_page.bas
// Imports a rotated page, opens it for editing and writes a formatted text block.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0; // try to continue on error
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);

    const char* inFile = LUMAS_REPO_ROOT "/rotated_270.pdf";
    if(pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0){ pdfDeletePDF(pdf); return 1; }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);

    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetUseVisibleCoords(pdf, 1);

    pdfEditPage(pdf, 1);
        SI32 orientation = pdfGetOrientation(pdf);
        if(orientation != 0) pdfSetOrientationEx(pdf, orientation);
        pdfSetLeading(pdf, 14.0);
        SI32 f = pdfSetFontA(pdf, "Helvetica", fsRegular, 12.0, 0, cp1252);
        pdfSetListFont(pdf, f);

        // The bullet is code page 1252 char 144 (0x90) for the ANSI (A) export.
        std::string s =
            "It is not difficult to edit an imported page but two things must be considered:\r\r"
            "\\LI[20,\x90]\\LD[16]The page's orientation.\\EL#"
            "\\LI[20,\x90]\\LD[12]The coordinate origin. The coordinate origin can be taken from the crop box if present, or from the media box (Left and Bottom).\\EL#\r"
            "\\LD[12]Although it is possible to correct the coordinate origin manually, it is much easier to set the property SetUseVisibleCoords() to true. LumasPDF moves the zero point then automatically into the visible area of the page.\r\r"
            "The functions GetPageWidth() and GetPageHeight() return then also the logical width or height of the page depending on the orientation and whether a crop box is present.\r\r"
            "The handling of rotated pages is a bit more complicated since the orientation is just a property. That means there is no guarantee that the contents is rotated into the opposite direction like the contents in this page. Whether this is the case depends on the creator of the PDF file.\r\r"
            "However, by default it is probably best to assume that the contents is rotated. SetOrientationEx() rotates the coordinate system so that we can work with the page as if it was not rotated. If this produces a wrong result then don't call SetOrientationEx().\r\r"
            "Now you ask probably yourself whether it is possible to identify the orientation of the contents in a page. The answer is maybe. It is possible to parse a page with ParseContent() and to inspect the transformation matrices but this can produce wrong results especially if a page contains not much contents.";

        pdfWriteFTextExA(pdf, 50.0, 200.0, pdfGetPageWidth(pdf) - 100.0, -1.0, taJustify, s.c_str());
    pdfEndPage(pdf);

    if(pdfHaveOpenDoc(pdf) != 0){
        std::string outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){ pdfDeletePDF(pdf); return 1; }
        if(pdfCloseFile(pdf) != 0) printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
    }
    pdfDeletePDF(pdf);
    return 0;
}

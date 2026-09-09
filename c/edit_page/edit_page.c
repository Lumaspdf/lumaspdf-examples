/* edit_page -- C port of examples\Vb6\edit_page\edit_page.bas */
#include <stdio.h>
#include <string.h>
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
    SI32 f, orientation;
    char dir[1024], inFile[1100], outFile[1100];
    const char* s;

    exedir(argv[0], dir, sizeof(dir));
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);

    sprintf(inFile, "%s\\rotated_270.pdf", dir);
    if (pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0) { pdfDeletePDF(pdf); return 0; }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);
    pdfCloseImportFile(pdf);

    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetUseVisibleCoords(pdf, 1);

    pdfEditPage(pdf, 1);
        orientation = pdfGetOrientation(pdf);
        if (orientation != 0) pdfSetOrientationEx(pdf, orientation);
        pdfSetLeading(pdf, 14.0);
        f = pdfSetFontA(pdf, "Helvetica", fsRegular, 12.0, 0, cp1252);
        pdfSetListFont(pdf, f);

        /* ANSI export, bullet = code page 1252 char 144 = "\x90" */
        s = "It is not difficult to edit an imported page but two things must be considered:\r\r"
            "\\LI[20,\x90]\\LD[16]The page's orientation.\\EL#\\LI[20,\x90]\\LD[12]The coordinate origin. "
            "The coordinate origin can be taken from the crop box if present, or from the media box (Left and Bottom).\\EL#\r\\LD[12]"
            "Although it is possible to correct the coordinate origin manually, it is much easier to set the property SetUseVisibleCoords() to true. "
            "DynaPDF moves the zero point then automatically into the visible area of the page.\r\r"
            "The functions GetPageWidth() and GetPageHeight() return then also the logical width or height of the page depending on the orientation "
            "and whether a crop box is present.\r\r"
            "The handling of rotated pages is a bit more complicated since the orientation is just a property. That means there is no guarantee that "
            "the contents is rotated into the opposite direction like the contents in this page. Whether this is the case depends on the creator of the PDF file.\r\r"
            "However, by default it is probably best to assume that the contents is rotated. SetOrientationEx() rotates the coordinate system so that we "
            "can work with the page as if it was not rotated. If this produces a wrong result then don't call SetOrientationEx().\r\r"
            "Now you ask probably yourself whether it is possible to identify the orientation of the contents in a page. The answer is maybe. It is possible "
            "to parse a page with ParseContent() and to inspect the transformation matrices but this can produce wrong results especially if a page contains not much contents.";

        pdfWriteFTextExA(pdf, 50.0, 200.0, pdfGetPageWidth(pdf) - 100.0, -1.0, taJustify, s);
    pdfEndPage(pdf);

    if (pdfHaveOpenDoc(pdf) != 0) {
        sprintf(outFile, "%s\\out.pdf", dir);
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfDeletePDF(pdf); return 0; }
        if (pdfCloseFile(pdf) != 0)
            printf("PDF file \"%s\" successfully created!\n", outFile);
    }
    pdfDeletePDF(pdf);
    return 0;
}

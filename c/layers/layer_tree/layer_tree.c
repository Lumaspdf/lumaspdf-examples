/* layer_tree -- C port of examples\Vb6\layers\layer_tree\layer_tree.bas */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define clBlue  0xFF0000u
#define clBlack 0x0u

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
    SI32 annot, ocmd, oc1, oc2, oc3;
    void* root; void* grp;
    double tw;
    char dir[1024], outFile[1100];
    const char* someText = "Some text with a link!!!";
    UI32 ocArray[2];

    exedir(argv[0], dir, sizeof(dir));
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetUseTransparency(pdf, 0);

    oc1 = pdfCreateOCGA(pdf, "All", 0, 1, oiAll);
    oc2 = pdfCreateOCGA(pdf, "Text and Annotations", 0, 1, oiAll);
    oc3 = pdfCreateOCGA(pdf, "Images", 0, 1, oiAll);

    root = pdfAddLayerToDisplTreeA(pdf, 0, oc1, "A layer group with a title");
    grp = pdfAddLayerToDisplTreeA(pdf, root, -1, "");
    pdfAddLayerToDisplTreeA(pdf, grp, oc2, "");
    pdfAddLayerToDisplTreeA(pdf, grp, oc3, "");

    pdfAppend(pdf);
    pdfBeginLayer(pdf, oc1);
    pdfBeginLayer(pdf, oc2);
        pdfSetFontA(pdf, "Helvetica", fsRegular, 12.0, 0, cp1252);
        pdfSetFillColor(pdf, clBlue);
        pdfWriteTextA(pdf, 50.0, 50.0, someText);
        tw = pdfGetTextWidthA(pdf, someText);
        pdfSetBorderStyle(pdf, bsUnderline);
        pdfSetStrokeColor(pdf, clBlue);
        annot = pdfWebLinkA(pdf, 50.0, 51.0, tw, 12.0, "www.lumaspdf.com");

        ocArray[0] = (UI32)oc1;
        ocArray[1] = (UI32)oc2;
        ocmd = pdfCreateOCMD(pdf, ovAllOn, ocArray, 2);
        pdfAddObjectToLayer(pdf, ocmd, ooAnnotation, annot);
    pdfEndLayer(pdf);

    pdfBeginLayer(pdf, oc3);
        pdfInsertImageExA(pdf, 50.0, 70.0, 300.0, 200.0, "../../../test_files/images/margarita-102572_640.jpg", 1);
    pdfEndLayer(pdf);
    pdfEndLayer(pdf);

    pdfSetFillColor(pdf, clBlack);
    pdfWriteTextA(pdf, 50.0, 300.0, "This text is not part of a layer!");
    pdfEndPage(pdf);

    pdfSetPageMode(pdf, pmUseOC);

    if (pdfHaveOpenDoc(pdf) != 0) {
        sprintf(outFile, "%s\\out.pdf", dir);
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfDeletePDF(pdf); return 0; }
        if (pdfCloseFile(pdf) != 0)
            printf("PDF file \"%s\" successfully created!\n", outFile);
    }
    pdfDeletePDF(pdf);
    return 0;
}

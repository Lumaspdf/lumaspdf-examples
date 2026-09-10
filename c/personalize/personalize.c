/* personalize -- C port of examples\Vb6\personalize\personalize.bas
 * Imports a tax form, fills in the fields, adds a web link. */
#include <stdio.h>
#include <string.h>
#include <time.h>
#include "lumaspdf.h"
#include "../_common.h"

#define RGB_(r,g,b) ((UI32)((UI8)(r) | ((UI16)((UI8)(g))<<8) | ((UI32)((UI8)(b))<<16)))

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return -1;
}

int main(int argc, char** argv)
{
    PPDF pdf;
    char dir[1024], inFile[1100], outFile[1100], nowbuf[64];
    time_t t = time(NULL);
    struct tm* lt;
    (void)argc;

    pdf = pdfNewPDF();
    exedir(argv[0], dir, sizeof(dir));
    pdfCreateNewPDFA(pdf, "");

    pdfSetViewerPreferences(pdf, vpDisplayDocTitle, avNone);
    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    _snprintf(inFile, sizeof(inFile), "%s\\taxform.pdf", dir);
    if (pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0) { pdfDeletePDF(pdf); return 1; }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);

    pdfEditPage(pdf, 1);
    pdfSetFontA(pdf, "Courier", fsBold, 14.0, 0, cp1252);
    pdfWriteTextA(pdf, 72.5, 748.5, "X");
    pdfWriteTextA(pdf, 74.0, 701.0, "Musterstadt");
    pdfWriteTextA(pdf, 74.0, 677.0, "252/1062/3323");
    pdfBeginContinueText(pdf, 74.0, 628.0);
    pdfSetLeading(pdf, 24.0);
    pdfSetCharacterSpacing(pdf, 5.8);
    pdfAddContinueTextA(pdf, "Mustermann");
    pdfAddContinueTextA(pdf, "Hermann");
    pdfAddContinueTextA(pdf, "22021963keineKaufmann");
    pdfAddContinueTextA(pdf, "Musterstra\xDF" "e 145"); /* 0xDF = sharp s in cp1252 */
    pdfAddContinueTextA(pdf, "12345Musterstadt");
    pdfSetCharacterSpacing(pdf, 0.0);
    pdfSetFontA(pdf, "Courier", fsBold, 10.0, 0, cp1252);
    pdfSetLeading(pdf, 48.0);
    pdfAddContinueTextA(pdf, "04.05.1994");
    pdfSetFontA(pdf, "Courier", fsBold, 14.0, 0, cp1252);
    pdfSetCharacterSpacing(pdf, 5.8);
    pdfAddContinueTextA(pdf, "Sabine");
    pdfSetLeading(pdf, 47.5);
    pdfAddContinueTextA(pdf, "18121966 ev  Hausfrau");
    pdfEndContinueText(pdf);
    pdfWriteTextA(pdf, 72.5, 365.0, "X");
    pdfWriteTextA(pdf, 396.0, 365.0, "X");
    pdfBeginContinueText(pdf, 74.0, 316.0);
    pdfSetLeading(pdf, 24.0);
    pdfAddContinueTextA(pdf, "2346256780     76834560");
    pdfAddContinueTextA(pdf, "Sparkasse Musterstadt");
    pdfEndContinueText(pdf);
    pdfWriteTextA(pdf, 72.5, 269.0, "X");
    pdfSetCharacterSpacing(pdf, 0.0);
    pdfSetFontA(pdf, "Courier", fsNone, 10.0, 0, cp1252);
    lt = localtime(&t);
    strftime(nowbuf, sizeof(nowbuf), "%d.%m.%Y %H:%M:%S", lt);
    pdfWriteTextA(pdf, 53.0, 48.0, nowbuf);
    pdfSetFillColor(pdf, RGB_(0xFF, 0x66, 0x66));
    pdfSetFontA(pdf, "Helvetica", fsBold, 22.0, 0, cp1252);
    pdfWriteTextA(pdf, 340.0, 70.0, "www.lumaspdf.com");
    pdfSetLineWidth(pdf, 0.0);
    pdfSetLinkHighlightMode(pdf, hmPush);
    pdfSetAnnotFlags(pdf, afReadOnly);
    pdfWebLinkA(pdf, 340.0, 64.0, 204.0, 22.0, "https://www.lumaspdf.com");
    pdfEndPage(pdf);

    if (pdfHaveOpenDoc(pdf)) {
        pdfSetOnErrorProc(pdf, 0, NULL);
        _snprintf(outFile, sizeof(outFile), "%s\\out.pdf", dir);
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfDeletePDF(pdf); return 1; }
        pdfSetOnErrorProc(pdf, 0, ErrProc);
    }
    if (pdfCloseFile(pdf))
        printf("PDF file \"%s\" successfully created!\n", outFile);
    pdfDeletePDF(pdf);
    return 0;
}

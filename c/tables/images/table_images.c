/* table_images -- C port of examples\Vb6\tables\images\table_images
   Lays out every JPEG in test_files\images into a 4-column table (one image per
   cell, native image color space), draws it, then redraws with tfScaleToRect. */
#include <stdio.h>
#include <string.h>
#include <io.h>
#include "lumaspdf.h"

/* Table flags missing from the wrapper enum (from LumasPdf.pas): */
#define tfScaleToRect 0x8
#define tfUseImageCS  0x10

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(void) {
    PPDF pdf;
    ITBL tbl;
    const char* imgDir = "..\\..\\..\\..\\test_files\\images\\";
    char pattern[512], full[512];
    struct _finddata_t fd;
    intptr_t h;
    long long fullSize = 0;
    int i, rowNum;
    TPDFError err;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetResolution(pdf, 300);

    tbl = tblCreateTable(pdf, 100, 4, 500.0f, 125.0f);
    tblSetBoxProperty(tbl, -1, -1, tbpBorderWidth, 1.0f, 1.0f, 1.0f, 1.0f);
    tblSetBoxProperty(tbl, -1, -1, tbpCellPadding, 5.0f, 5.0f, 5.0f, 5.0f);
    tblSetGridWidth(tbl, 1.0f, 1.0f);
    tblSetFlags(tbl, -1, -1, tfUseImageCS);

    strcpy(pattern, imgDir); strcat(pattern, "*.jpg");
    h = _findfirst(pattern, &fd);
    if (h == -1) {
        printf("Test images not found!\n");
        tblDeleteTable(&tbl);
        pdfDeletePDF(pdf);
        return 1;
    }

    i = 1;
    fullSize = fd.size;
    rowNum = tblAddRow(tbl, 125.0f);
    strcpy(full, imgDir); strcat(full, fd.name);
    tblSetCellImageA(tbl, rowNum, 0, 1, coCenter, coCenter, 0.0f, 0.0f, full, 1);

    while (_findnext(h, &fd) == 0) {
        if (i == 4) { rowNum = tblAddRow(tbl, 100.0f); i = 0; }
        fullSize += fd.size;
        strcpy(full, imgDir); strcat(full, fd.name);
        tblSetCellImageA(tbl, rowNum, i, 1, coCenter, coCenter, 0.0f, 0.0f, full, 1);
        i++;
    }
    _findclose(h);

    pdfAppend(pdf);
    tblDrawTable(tbl, 50.0f, 50.0f, 742.0f);
    while (tblHaveMore(tbl) != 0) {
        pdfEndPage(pdf);
        if (fullSize > 104857600LL) pdfFlushPages(pdf, fpfDefault);
        pdfAppend(pdf);
        tblDrawTable(tbl, 50.0f, 50.0f, 742.0f);
    }
    pdfEndPage(pdf);

    /* Draw the same table again but this time with tfScaleToRect */
    tblSetFlags(tbl, -1, -1, tfScaleToRect | tfUseImageCS);
    pdfAppend(pdf);
    pdfSetFontA(pdf, "Arial", fsRegular, 12.0, 1, cp1252);
    pdfWriteTextA(pdf, 50.0, 50.0, "The same table but the flag tfScaleToRect was set.");
    tblDrawTable(tbl, 50.0f, 65.0f, 742.0f);
    while (tblHaveMore(tbl) != 0) {
        pdfEndPage(pdf);
        if (fullSize > 104857600LL) pdfFlushPages(pdf, fpfDefault);
        pdfAppend(pdf);
        tblDrawTable(tbl, 50.0f, 50.0f, 742.0f);
    }
    pdfEndPage(pdf);

    tblDeleteTable(&tbl);

    err.StructSize = sizeof(err);
    for (i = 0; i < pdfGetErrLogMessageCount(pdf); i++) {
        pdfGetErrLogMessage(pdf, i, &err);
        if (err.Msg) printf("%s\n", err.Msg);
    }

    if (pdfHaveOpenDoc(pdf) != 0) {
        if (pdfOpenOutputFileA(pdf, "out.pdf") == 0) { pdfDeletePDF(pdf); return 1; }
        if (pdfCloseFile(pdf) != 0) printf("Done: out.pdf\n");
    }

    pdfDeletePDF(pdf);
    return 0;
}

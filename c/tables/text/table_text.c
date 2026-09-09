/* table_text -- C port of examples\Vb6\tables\text\table_text
   Builds a 3x3 table demonstrating cell text alignment, draws it, then redraws
   it with a 90-degree cell orientation. */
#include <stdio.h>
#include "lumaspdf.h"

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(void) {
    PPDF pdf;
    ITBL tbl;
    int i, rowNum;
    TPDFError err;
    const char* txt = "The cell alignment can be set for text, images, and templates...";

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    tbl = tblCreateTable(pdf, 3, 3, 500.0f, 100.0f);
    tblSetBoxProperty(tbl, -1, -1, tbpBorderWidth, 1.0f, 1.0f, 1.0f, 1.0f);
    tblSetFontA(tbl, -1, -1, "Arial", fsRegular, 1, cp1252);
    tblSetFontA(tbl, -1, 1, "Arial", fsBold, 1, cp1252);
    tblSetGridWidth(tbl, 1.0f, 1.0f);

    rowNum = tblAddRow(tbl, -1.0f);
    tblSetCellTextA(tbl, rowNum, 0, taLeft, coTop, txt, (UI32)-1);
    tblSetCellTextA(tbl, rowNum, 1, taCenter, coTop, txt, (UI32)-1);
    tblSetCellTextA(tbl, rowNum, 2, taRight, coTop, txt, (UI32)-1);

    rowNum = tblAddRow(tbl, -1.0f);
    tblSetCellTextA(tbl, rowNum, 0, taLeft, coCenter, txt, (UI32)-1);
    tblSetCellTextA(tbl, rowNum, 1, taCenter, coCenter, txt, (UI32)-1);
    tblSetCellTextA(tbl, rowNum, 2, taRight, coCenter, txt, (UI32)-1);

    rowNum = tblAddRow(tbl, -1.0f);
    tblSetCellTextA(tbl, rowNum, 0, taLeft, coBottom, txt, (UI32)-1);
    tblSetCellTextA(tbl, rowNum, 1, taCenter, coBottom, txt, (UI32)-1);
    tblSetCellTextA(tbl, rowNum, 2, taRight, coBottom, txt, (UI32)-1);

    pdfAppend(pdf);
    tblDrawTable(tbl, 50.0f, 50.0f, 742.0f);
    while (tblHaveMore(tbl) != 0) {
        pdfEndPage(pdf);
        pdfAppend(pdf);
        tblDrawTable(tbl, 50.0f, 50.0f, 742.0f);
    }
    pdfEndPage(pdf);

    /* change the cell orientation to 90 degrees */
    tblSetCellOrientation(tbl, -1, -1, 90);
    pdfAppend(pdf);
    pdfSetFontA(pdf, "Arial", fsRegular, 12.0, 1, cp1252);
    pdfWriteTextA(pdf, 50.0, 50.0, "The same table but the cell orientation was changed to 90 degrees.");
    tblDrawTable(tbl, 50.0f, 65.0f, 742.0f);
    while (tblHaveMore(tbl) != 0) {
        pdfEndPage(pdf);
        pdfAppend(pdf);
        tblDrawTable(tbl, 50.0f, 50.0f, 737.0f);
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

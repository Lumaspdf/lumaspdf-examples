// table_text -- C++ mirror of examples\Vb6\tables\text\table_text.bas
// Builds a 3x3 table demonstrating cell text alignment, draws it, then redraws
// with a 90-degree cell orientation. Uses the flat tbl* exports.
#include "apputil.h"

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main() {
    ChdirToExe();
    unsigned long timeStart = GetTickCount();

    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");
    pdfSetPageCoords(pdf, pcTopDown);

    ITBL tbl = tblCreateTable(pdf, 3, 3, 500.0f, 100.0f);
    tblSetBoxProperty(tbl, -1, -1, tbpBorderWidth, 1, 1, 1, 1);
    tblSetFontA(tbl, -1, -1, "Arial", fsRegular, 1, cp1252);
    tblSetFontA(tbl, -1, 1, "Arial", fsBold, 1, cp1252);
    tblSetGridWidth(tbl, 1, 1);

    const char* txt = "The cell alignment can be set for text, images, and templates...";

    int rowNum = tblAddRow(tbl, -1.0f);
    tblSetCellTextA(tbl, rowNum, 0, taLeft,   coTop, txt, (UI32)strlen(txt));
    tblSetCellTextA(tbl, rowNum, 1, taCenter, coTop, txt, (UI32)strlen(txt));
    tblSetCellTextA(tbl, rowNum, 2, taRight,  coTop, txt, (UI32)strlen(txt));

    rowNum = tblAddRow(tbl, -1.0f);
    tblSetCellTextA(tbl, rowNum, 0, taLeft,   coCenter, txt, (UI32)strlen(txt));
    tblSetCellTextA(tbl, rowNum, 1, taCenter, coCenter, txt, (UI32)strlen(txt));
    tblSetCellTextA(tbl, rowNum, 2, taRight,  coCenter, txt, (UI32)strlen(txt));

    rowNum = tblAddRow(tbl, -1.0f);
    tblSetCellTextA(tbl, rowNum, 0, taLeft,   coBottom, txt, (UI32)strlen(txt));
    tblSetCellTextA(tbl, rowNum, 1, taCenter, coBottom, txt, (UI32)strlen(txt));
    tblSetCellTextA(tbl, rowNum, 2, taRight,  coBottom, txt, (UI32)strlen(txt));

    pdfAppend(pdf);
    tblDrawTable(tbl, 50, 50, 742);
    while (tblHaveMore(tbl) != 0) {
        pdfEndPage(pdf);
        pdfAppend(pdf);
        tblDrawTable(tbl, 50, 50, 742);
    }
    pdfEndPage(pdf);

    // Change the cell orientation to see what happens.
    tblSetCellOrientation(tbl, -1, -1, 90);
    pdfAppend(pdf);
    pdfSetFontA(pdf, "Arial", fsRegular, 12.0, 1, cp1252);
    pdfWriteTextA(pdf, 50, 50, "The same table but the cell orientation was changed to 90 degrees.");
    tblDrawTable(tbl, 50, 65, 742);
    while (tblHaveMore(tbl) != 0) {
        pdfEndPage(pdf);
        pdfAppend(pdf);
        tblDrawTable(tbl, 50, 50, 737);
    }
    pdfEndPage(pdf);

    tblDeleteTable(&tbl);

    TPDFError err; err.StructSize = sizeof(err);
    for (int n = 0; n < (int)pdfGetErrLogMessageCount(pdf); ++n) {
        pdfGetErrLogMessage(pdf, n, &err);
        if (err.Msg) printf("%s\n", err.Msg);
    }

    if (pdfHaveOpenDoc(pdf) != 0) {
        const char* outFile = "out.pdf";
        if (pdfOpenOutputFileA(pdf, outFile) == 0) { pdfDeletePDF(pdf); return 0; }
        if (pdfCloseFile(pdf) != 0) {
            timeStart = GetTickCount() - timeStart;
            printf("Processing time: %lu ms\n", timeStart);
        }
    }

    pdfDeletePDF(pdf);
    return 0;
}

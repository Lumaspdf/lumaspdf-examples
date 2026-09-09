// table_templates -- C++ mirror of examples\Vb6\tables\templates\table_templates.bas
// Imports every page of sample_multipage.pdf as a template, lays them out two per row
// (tfScaleToRect), then draws the table across as many output pages as needed.
#include "apputil.h"

// Table flag missing from the shared wrapper (from LumasPdf.pas):
static const int tfScaleToRect = 0x8;

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
    pdfSetImportFlags2(pdf, if2UseProxy);

    pdfOpenImportFileA(pdf, LUMAS_REPO_ROOT "/sample_multipage.pdf", ptOpen, "");

    int pageCount = pdfGetInPageCount(pdf);
    if (pageCount < 1) {
        printf("Help file not found!\n");
        pdfDeletePDF(pdf);
        return 0;
    }

    ITBL tbl = tblCreateTable(pdf, pageCount / 4 + 1, 2, 512.12f, 0.0f);
    tblSetBoxProperty(tbl, -1, -1, tbpBorderWidth, 1, 1, 1, 1);
    tblSetBoxProperty(tbl, -1, -1, tbpCellPadding, 5, 5, 5, 5);
    tblSetGridWidth(tbl, 1, 1);
    tblSetFlags(tbl, -1, -1, tfScaleToRect);

    pdfSetPageFormat(pdf, pfUS_Letter);

    int rowNum = 0;
    for (int i = 1; i <= pageCount; ++i) {
        int tmpl = pdfImportPage(pdf, i);
        if ((i & 1) != 0) rowNum = tblAddRow(tbl, 335.0f);
        tblSetCellTemplate(tbl, rowNum, (i - 1) & 1, 1, coCenter, coCenter, tmpl, 0, 0);
    }

    pdfAppend(pdf);
    tblDrawTable(tbl, 50, 50, 742);
    while (tblHaveMore(tbl) != 0) {
        pdfEndPage(pdf);
        pdfAppend(pdf);
        tblDrawTable(tbl, 50, 50, 742);
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

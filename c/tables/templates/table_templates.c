/* table_templates -- C port of examples\Vb6\tables\templates\table_templates
   Imports every page of dynapdf_help.pdf as a template and lays them out two
   per row in a table (tfScaleToRect), then draws across as many pages as needed. */
#include <stdio.h>
#include "lumaspdf.h"

#define tfScaleToRect 0x8

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

int main(void) {
    PPDF pdf;
    ITBL tbl;
    int i, pageCount, tmpl, rowNum;
    TPDFError err;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetImportFlags2(pdf, if2UseProxy);

    pdfOpenImportFileA(pdf, "..\\..\\..\\..\\dynapdf_help.pdf", ptOpen, "");

    pageCount = pdfGetInPageCount(pdf);
    if (pageCount < 1) {
        printf("Help file not found!\n");
        pdfDeletePDF(pdf);
        return 1;
    }

    tbl = tblCreateTable(pdf, pageCount / 4 + 1, 2, 512.12f, 0.0f);
    tblSetBoxProperty(tbl, -1, -1, tbpBorderWidth, 1.0f, 1.0f, 1.0f, 1.0f);
    tblSetBoxProperty(tbl, -1, -1, tbpCellPadding, 5.0f, 5.0f, 5.0f, 5.0f);
    tblSetGridWidth(tbl, 1.0f, 1.0f);
    tblSetFlags(tbl, -1, -1, tfScaleToRect);

    pdfSetPageFormat(pdf, pfUS_Letter);

    rowNum = 0;
    for (i = 1; i <= pageCount; i++) {
        tmpl = pdfImportPage(pdf, i);
        if ((i & 1) != 0) rowNum = tblAddRow(tbl, 335.0f);
        tblSetCellTemplate(tbl, rowNum, (i - 1) & 1, 1, coCenter, coCenter, tmpl, 0.0f, 0.0f);
    }

    pdfAppend(pdf);
    tblDrawTable(tbl, 50.0f, 50.0f, 742.0f);
    while (tblHaveMore(tbl) != 0) {
        pdfEndPage(pdf);
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

/* probe_test -- C port of examples\Vb6\probe_test\probe_test.bas
 * Step-by-step probe of the TPDF flow + TPDFTable (tbl* exports). */
#include <stdio.h>
#include "lumaspdf.h"
#include "../_common.h"

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrType;
    printf("ERR %d: %s\n", ErrCode, ErrMessage ? ErrMessage : "");
    return 0;
}

int main(int argc, char** argv)
{
    PPDF pdf;
    ITBL tbl;
    SI32 r;
    char dir[1024], outFile[1100];
    (void)argc;

    pdf = pdfNewPDF();
    printf("Create ok\n");
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    printf("CreateNewPDF('') = %d\n", pdfCreateNewPDFA(pdf, ""));
    printf("SetPageCoords = %d\n", pdfSetPageCoords(pdf, pcTopDown));
    printf("Append = %d\n", pdfAppend(pdf));
    printf("SetFont = %d\n", pdfSetFontA(pdf, "Arial", fsRegular, 12.0, 1, cp1252));
    printf("WriteText = %d\n", pdfWriteTextA(pdf, 50, 50, "probe"));

    tbl = tblCreateTable(pdf, 3, 3, 500.0f, 100.0f);
    printf("Table created\n");
    r = tblAddRow(tbl, -1.0f);
    printf("AddRow = %d\n", r);
    printf("SetCellText = %d\n", tblSetCellTextA(tbl, r, 0, taLeft, coTop, "cell", (UI32)-1));
    printf("DrawTable = %f\n", tblDrawTable(tbl, 50.0f, 80.0f, 700.0f));
    printf("HaveMore = %d\n", tblHaveMore(tbl));
    tblDeleteTable(&tbl);

    printf("EndPage = %d\n", pdfEndPage(pdf));
    printf("GetPageCount = %d\n", pdfGetPageCount(pdf));
    printf("HaveOpenDoc = %d\n", pdfHaveOpenDoc(pdf));
    exedir(argv[0], dir, sizeof(dir));
    _snprintf(outFile, sizeof(outFile), "%s\\probe_out.pdf", dir);
    printf("OpenOutputFile = %d\n", pdfOpenOutputFileA(pdf, outFile));
    printf("CloseFile = %d\n", pdfCloseFile(pdf));
    pdfDeletePDF(pdf);
    return 0;
}

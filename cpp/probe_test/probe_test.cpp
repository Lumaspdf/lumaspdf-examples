// probe_test -- C++ port of examples\Vb6\probe_test\probe_test.bas
// Step-by-step probe of the TPDF flow (in-memory CreateNewPDF + OpenOutputFile + TPDFTable).
#include <lumaspdf.h>
#include <cstdio>
#include <string>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    printf("ERR %d: %s\n", ErrCode, ErrMessage ? ErrMessage : "");
    return 0;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    printf("Create ok\n");
    pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    printf("CreateNewPDF('') = %d\n", pdfCreateNewPDFA(pdf, ""));
    printf("SetPageCoords = %d\n", pdfSetPageCoords(pdf, pcTopDown));
    printf("Append = %d\n", pdfAppend(pdf));
    printf("SetFont = %d\n", pdfSetFontA(pdf, "Arial", fsRegular, 12.0, 1, cp1252));
    printf("WriteText = %d\n", pdfWriteTextA(pdf, 50, 50, "probe"));

    ITBL tbl = tblCreateTable(pdf, 3, 3, 500.0f, 100.0f);
    printf("Table created\n");
    SI32 r = tblAddRow(tbl, -1.0f);
    printf("AddRow = %d\n", r);
    printf("SetCellText = %d\n", tblSetCellTextA(tbl, r, 0, taLeft, coTop, "cell", (UI32)-1));
    printf("DrawTable = %f\n", tblDrawTable(tbl, 50.0f, 80.0f, 700.0f));
    printf("HaveMore = %d\n", tblHaveMore(tbl));
    tblDeleteTable(&tbl);

    printf("EndPage = %d\n", pdfEndPage(pdf));
    printf("GetPageCount = %d\n", pdfGetPageCount(pdf));
    printf("HaveOpenDoc = %d\n", pdfHaveOpenDoc(pdf));
    std::string outFile = exeDir(argv[0]) + "/probe_out.pdf";
    printf("OpenOutputFile = %d\n", pdfOpenOutputFileA(pdf, outFile.c_str()));
    printf("CloseFile = %d\n", pdfCloseFile(pdf));
    pdfDeletePDF(pdf);
    return 0;
}

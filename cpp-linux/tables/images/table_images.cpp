// table_images -- C++ mirror of examples\Vb6\tables\images\table_images.bas
// Lays out every JPEG in test_files\images into a 4-column table, draws it, then
// redraws with tfScaleToRect. Uses the flat tbl* exports.
#include "apputil.h"
#include <string>
#include <vector>
#include <algorithm>   // std::sort -- see the ordering note below
#include <filesystem>

namespace fs = std::filesystem;

// Table flags missing from the shared wrapper (from dynapdf.pas):
static const int tfScaleToRect = 0x8;
static const int tfUseImageCS  = 0x10;

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType) {
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0; // try to continue
}

int main() {
    ChdirToExe();
    unsigned long timeStart = GetTickCount();

    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");
    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetResolution(pdf, 300);

    ITBL tbl = tblCreateTable(pdf, 100, 4, 500.0f, 125.0f);
    tblSetBoxProperty(tbl, -1, -1, tbpBorderWidth, 1, 1, 1, 1);
    tblSetBoxProperty(tbl, -1, -1, tbpCellPadding, 5, 5, 5, 5);
    tblSetGridWidth(tbl, 1, 1);
    tblSetFlags(tbl, -1, -1, tfUseImageCS);

    std::string imgDir = std::string(LUMAS_REPO_ROOT) + "/images/";
    std::vector<std::string> files;
    long long fullSize = 0;
    std::error_code ec;
    if (fs::exists(imgDir, ec)) {
        for (auto& e : fs::directory_iterator(imgDir, ec)) {
            std::string ext = e.path().extension().string();
            if (ext == ".jpg" || ext == ".JPG") {
                files.push_back(e.path().string());
                fullSize += (long long)e.file_size(ec);
            }
        }
    }
    // fs::directory_iterator yields ENTRIES IN NO DEFINED ORDER, and the order
    // differs per filesystem: the same run put a given photo at /Im1 on macOS
    // (APFS) and /Im4 on Linux (overlayfs), so two correct runs produced PDFs
    // that differed in content for no real reason. Sorting makes the output
    // deterministic and cross-platform comparable, which is the whole point of
    // being able to diff these examples between hosts.
    std::sort(files.begin(), files.end());

    if (files.empty()) {
        printf("Test images not found!\n");
        tblDeleteTable(&tbl);
        pdfDeletePDF(pdf);
        return 0;
    }

    int i = 0;
    int rowNum = tblAddRow(tbl, 125.0f);
    for (size_t k = 0; k < files.size(); ++k) {
        if (i == 4) { rowNum = tblAddRow(tbl, 100.0f); i = 0; }
        tblSetCellImageA(tbl, rowNum, i, 1, coCenter, coCenter, 0, 0, files[k].c_str(), 1);
        ++i;
    }

    pdfAppend(pdf);
    tblDrawTable(tbl, 50, 50, 742);
    while (tblHaveMore(tbl) != 0) {
        pdfEndPage(pdf);
        if (fullSize > 104857600LL) pdfFlushPages(pdf, fpfDefault);
        pdfAppend(pdf);
        tblDrawTable(tbl, 50, 50, 742);
    }
    pdfEndPage(pdf);

    // Draw the same table again but with the flag tfScaleToRect.
    tblSetFlags(tbl, -1, -1, tfScaleToRect | tfUseImageCS);
    pdfAppend(pdf);
    pdfSetFontA(pdf, "Arial", fsRegular, 12.0, 1, cp1252);
    pdfWriteTextA(pdf, 50, 50, "The same table but the flag tfScaleToRect was set.");
    tblDrawTable(tbl, 50, 65, 742);
    while (tblHaveMore(tbl) != 0) {
        pdfEndPage(pdf);
        if (fullSize > 104857600LL) pdfFlushPages(pdf, fpfDefault);
        pdfAppend(pdf);
        tblDrawTable(tbl, 50, 50, 742);
    }
    pdfEndPage(pdf);

    tblDeleteTable(&tbl);

    // A table stores errors and warnings in the error log.
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

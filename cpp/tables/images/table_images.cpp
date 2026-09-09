// table_images -- C++ mirror of examples\Vb6\tables\images\table_images.bas
// Lays out every JPEG in test_files\images into a 4-column table, draws it, then
// redraws with tfScaleToRect. Uses the flat tbl* exports.
#include "apputil.h"
#include <string>
#include <vector>
#include <filesystem>

namespace fs = std::filesystem;

// The Delphi original calls TPDF.SetCellImage / SetFont / WriteText /
// OpenOutputFile, which are the UNICODE overloads (*W) -- so this port uses the
// *W exports too, not the *A ones. LWCHAR is wchar_t on Windows and char16_t
// elsewhere, so every wide buffer is spelled basic_string<LWCHAR> and widened
// at runtime; a u"..." literal would not compile with MSVC (where LWCHAR is
// wchar_t) and an L"..." one would be 4 bytes wide, and wrong, off Windows.
typedef std::basic_string<LWCHAR> ustring;
static ustring Widen(const std::string& s) { return ustring(s.begin(), s.end()); }
static LWCHAR* W(ustring& s) { return const_cast<LWCHAR*>(s.c_str()); }

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
    ustring empty;
    pdfCreateNewPDFW(pdf, W(empty));
    pdfSetPageCoords(pdf, pcTopDown);
    pdfSetResolution(pdf, 300);

    ITBL tbl = tblCreateTable(pdf, 100, 4, 500.0f, 125.0f);
    tblSetBoxProperty(tbl, -1, -1, tbpBorderWidth, 1, 1, 1, 1);
    tblSetBoxProperty(tbl, -1, -1, tbpCellPadding, 5, 5, 5, 5);
    tblSetGridWidth(tbl, 1, 1);
    tblSetFlags(tbl, -1, -1, tfUseImageCS);

    std::string imgDir = "..\\..\\..\\test_files\\images\\";
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
        ustring imgW = Widen(files[k]);
        tblSetCellImageW(tbl, rowNum, i, 1, coCenter, coCenter, 0, 0, W(imgW), 1);
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
    ustring fontW = Widen("Arial");
    ustring msgW  = Widen("The same table but the flag tfScaleToRect was set.");
    pdfSetFontW(pdf, W(fontW), fsRegular, 12.0, 1, cp1252);
    pdfWriteTextW(pdf, 50, 50, W(msgW));
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
        ustring outFile = Widen("out.pdf");
        if (pdfOpenOutputFileW(pdf, W(outFile)) == 0) { pdfDeletePDF(pdf); return 0; }
        if (pdfCloseFile(pdf) != 0) {
            timeStart = GetTickCount() - timeStart;
            printf("Processing time: %lu ms\n", timeStart);
        }
    }

    pdfDeletePDF(pdf);
    return 0;
}

// bookmarks -- C++ port of examples\Vb6\bookmarks\bookmarks.bas
#include <lumaspdf.h>
#include <cstdio>
#include <string>

// VCL TColor values (COLORREF, R in low byte) used by SetBookmarkStyle.
static const long clRed    = 0x0000FF;
static const long clGreen  = 0x008000;
static const long clBlue   = 0xFF0000;
static const long clMaroon = 0x000080;

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;   // We try to continue if an error occurs
}

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

int main(int argc, char** argv){
    SI32 act, lnk, f, bmk, root;
    double x, y;

    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfSetPageHeight(pdf, 500.0);
    pdfSetPageWidth(pdf, 800.0);

    pdfAppend(pdf);
        f = pdfSetFontA(pdf, "Helvetica", fsRegular, 20, 0, cp1252);
        pdfWriteTextA(pdf, 50, 50, "Bookmark destination type dtFit");
        root = pdfAddBookmarkA(pdf, "DestType dtFit", -1, 1, 1);
        pdfSetBookmarkDest(pdf, root, dtFit, 0, 0, 0, 0);
        pdfSetBookmarkStyle(pdf, root, fsItalic, clRed);
    pdfEndPage(pdf);

    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteTextA(pdf, 50, 50, "Bookmark destination type dtXY_Zoom");
        pdfWriteTextA(pdf, 50, 70, "Zoom factor 3, Top position 50 (TopDown coordinates)");
        bmk = pdfAddBookmarkA(pdf, "DestType: dtXY_Zoom, zoom factor 3", root, 2, 0);
        pdfSetBookmarkDest(pdf, bmk, dtXY_Zoom, 50, 50, 3, 0);
        pdfSetBookmarkStyle(pdf, bmk, fsBold, clMaroon);
    pdfEndPage(pdf);

    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteTextA(pdf, 50, 50, "Bookmark destination type dtXY_Zoom");
        pdfWriteTextA(pdf, 50, 70, "Zoom factor 0.5, Top position 50 (TopDown coordinates)");
        bmk = pdfAddBookmarkA(pdf, "DestType: dtXY_Zoom, zoom factor 0.5", root, 3, 0);
        pdfSetBookmarkDest(pdf, bmk, dtXY_Zoom, 50, 50, 0.5, 0);
        pdfSetBookmarkStyle(pdf, bmk, fsBold | fsItalic, clGreen);
    pdfEndPage(pdf);

    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteTextA(pdf, 50, 50, "Bookmark destination type dtXY_Zoom");
        pdfWriteTextA(pdf, 50, 70, "Zoom factor not defined (unchanged), Top position 50 (TopDown coordinates)");
        bmk = pdfAddBookmarkA(pdf, "DestType: dtXY_Zoom, zoom factor unchanged", root, 4, 0);
        pdfSetBookmarkDest(pdf, bmk, dtXY_Zoom, 50, 50, 0, 0);
        pdfSetBookmarkStyle(pdf, bmk, fsRegular, clBlue);
    pdfEndPage(pdf);

    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteTextA(pdf, 50, 50, "Bookmark destination type dtFitH_Top");
        pdfWriteTextA(pdf, 50, 70, "Top position 50 (TopDown coordinates)");
        bmk = pdfAddBookmarkA(pdf, "DestType: dtFitH_Top (50)", root, 5, 0);
        pdfSetBookmarkDest(pdf, bmk, dtFitH_Top, 50, 0, 0, 0);
        pdfSetBookmarkStyle(pdf, bmk, fsRegular, 0xFF8080);
        pdfWriteTextA(pdf, 50, 200, "Bookmark destination type dtFitH_Top");
        pdfWriteTextA(pdf, 50, 220, "Top position 200 (TopDown coordinates)");
        bmk = pdfAddBookmarkA(pdf, "DestType dtFitH_Top (200)", root, 5, 0);
        pdfSetBookmarkDest(pdf, bmk, dtFitH_Top, 200, 0, 0, 0);
        pdfSetBookmarkStyle(pdf, bmk, fsRegular, 0xC08080);
    pdfEndPage(pdf);

    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteTextA(pdf, 200, 50, "Bookmark destination type dtFitV_Left");
        pdfWriteTextA(pdf, 200, 70, "Left position 200. FitV has no effect if the width of the page");
        pdfWriteTextA(pdf, 200, 90, "is not greater as the height.");
        bmk = pdfAddBookmarkA(pdf, "DestType: dtFitV_Left (200)", root, 6, 0);
        pdfSetBookmarkDest(pdf, bmk, dtFitV_Left, 200, 0, 0, 0);
        pdfSetBookmarkStyle(pdf, bmk, fsRegular, 0x808FFF);
    pdfEndPage(pdf);

    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteTextA(pdf, 50, 50, "Bookmark destination type dtFit_Rect");
        x = (pdfGetPageWidth(pdf) - 90.0) / 2.0;
        y = (pdfGetPageHeight(pdf) - 65.0) / 2.0;

        pdfWriteFTextExA(pdf, x, y, 90.0, -1, taCenter, "We zoom into the rectangle");
        pdfRectangle(pdf, x, y, 90.0, 65.0, fmStroke);

        pdfSetLinkHighlightMode(pdf, hmInvert);
        lnk = pdfPageLink(pdf, x, y, 90, 65, 7);
        act = pdfCreateGoToAction(pdf, dtFit_Rect, 7, x - 5.0, y - 5.0, x + 100.0, y + 70.0);
        pdfAddActionToObj(pdf, otPageLink, oeOnMouseUp, act, lnk);

        bmk = pdfAddBookmarkA(pdf, "DestType: dtFit_Rect", -1, 7, 0);
        pdfAddActionToObj(pdf, otBookmark, oeOnMouseUp, act, bmk);
        pdfSetBookmarkStyle(pdf, bmk, fsRegular, 0x80FF);
    pdfEndPage(pdf);

    pdfSetPageFormat(pdf, pfDIN_A4);
    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteFTextExA(pdf, 50.0, 50.0, pdfGetPageWidth(pdf) - 100.0, -1.0, taLeft, "Destination type dtFit. This variant scales the page so that both sides fit into the viewer window.");
    pdfEndPage(pdf);

    root = pdfAddBookmarkA(pdf, "DestType dtFit", -1, 8, 0);
    pdfSetBookmarkDest(pdf, root, dtFit, 0, 0, 0, 0);

    bmk = pdfAddBookmarkA(pdf, "DestType: dtXY_Zoom, zoom factor 3", root, 2, 0);
    pdfSetBookmarkDest(pdf, bmk, dtXY_Zoom, 50, 50, 3, 0);
    pdfSetBookmarkStyle(pdf, bmk, fsBold, clMaroon);

    pdfSetPageLayout(pdf, plOneColumn);

    if(pdfHaveOpenDoc(pdf) != 0){
        std::string outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){
            pdfDeletePDF(pdf);
            return 0;
        }
        if(pdfCloseFile(pdf) != 0)
            printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
    }
    pdfDeletePDF(pdf);
    return 0;
}

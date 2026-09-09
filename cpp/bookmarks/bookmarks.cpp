// bookmarks -- C++ port of examples\Vb6\bookmarks\bookmarks.bas
#include <lumaspdf.h>
#include <cstdio>
#include <string>

// The Delphi original passes Delphi `string` (UnicodeString) to SetFont,
// WriteText, WriteFTextEx, AddBookmark and OpenOutputFile, so every one of
// those calls resolves to the WIDE overload. The *A twins used here before
// kept the text in WinAnsi and never reached the engine's Unicode pipeline --
// visible in the output as the missing Type0/Identity-H fallback font for the
// two WriteFTextEx blocks (the Delphi reference is 20,682 bytes with an /F2
// PMVDKQ+ArialMT; this file was 2,943 bytes with /Helvetica only). LWCHAR is
// wchar_t on Windows and char16_t elsewhere, so literals must use the header's
// own LUMAS_TEXT() macro: a bare u"..." does not convert to LWCHAR* under MSVC
// and a bare L"..." is 4 bytes wide off Windows.
#define W_(s) ((LWCHAR*)LUMAS_TEXT(s))
static std::basic_string<LWCHAR> WS(const std::string& s){
    return std::basic_string<LWCHAR>(s.begin(), s.end());
}

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
    pdfCreateNewPDFW(pdf, W_(""));

    pdfSetPageCoords(pdf, pcTopDown);

    pdfSetPageHeight(pdf, 500.0);
    pdfSetPageWidth(pdf, 800.0);

    pdfAppend(pdf);
        f = pdfSetFontW(pdf, W_("Helvetica"), fsRegular, 20, 0, cp1252);
        pdfWriteTextW(pdf, 50, 50, W_("Bookmark destination type dtFit"));
        root = pdfAddBookmarkW(pdf, W_("DestType dtFit"), -1, 1, 1);
        pdfSetBookmarkDest(pdf, root, dtFit, 0, 0, 0, 0);
        pdfSetBookmarkStyle(pdf, root, fsItalic, clRed);
    pdfEndPage(pdf);

    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteTextW(pdf, 50, 50, W_("Bookmark destination type dtXY_Zoom"));
        pdfWriteTextW(pdf, 50, 70, W_("Zoom factor 3, Top position 50 (TopDown coordinates)"));
        bmk = pdfAddBookmarkW(pdf, W_("DestType: dtXY_Zoom, zoom factor 3"), root, 2, 0);
        pdfSetBookmarkDest(pdf, bmk, dtXY_Zoom, 50, 50, 3, 0);
        pdfSetBookmarkStyle(pdf, bmk, fsBold, clMaroon);
    pdfEndPage(pdf);

    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteTextW(pdf, 50, 50, W_("Bookmark destination type dtXY_Zoom"));
        pdfWriteTextW(pdf, 50, 70, W_("Zoom factor 0.5, Top position 50 (TopDown coordinates)"));
        bmk = pdfAddBookmarkW(pdf, W_("DestType: dtXY_Zoom, zoom factor 0.5"), root, 3, 0);
        pdfSetBookmarkDest(pdf, bmk, dtXY_Zoom, 50, 50, 0.5, 0);
        pdfSetBookmarkStyle(pdf, bmk, fsBold | fsItalic, clGreen);
    pdfEndPage(pdf);

    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteTextW(pdf, 50, 50, W_("Bookmark destination type dtXY_Zoom"));
        pdfWriteTextW(pdf, 50, 70, W_("Zoom factor not defined (unchanged), Top position 50 (TopDown coordinates)"));
        bmk = pdfAddBookmarkW(pdf, W_("DestType: dtXY_Zoom, zoom factor unchanged"), root, 4, 0);
        pdfSetBookmarkDest(pdf, bmk, dtXY_Zoom, 50, 50, 0, 0);
        pdfSetBookmarkStyle(pdf, bmk, fsRegular, clBlue);
    pdfEndPage(pdf);

    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteTextW(pdf, 50, 50, W_("Bookmark destination type dtFitH_Top"));
        pdfWriteTextW(pdf, 50, 70, W_("Top position 50 (TopDown coordinates)"));
        bmk = pdfAddBookmarkW(pdf, W_("DestType: dtFitH_Top (50)"), root, 5, 0);
        pdfSetBookmarkDest(pdf, bmk, dtFitH_Top, 50, 0, 0, 0);
        pdfSetBookmarkStyle(pdf, bmk, fsRegular, 0xFF8080);
        pdfWriteTextW(pdf, 50, 200, W_("Bookmark destination type dtFitH_Top"));
        pdfWriteTextW(pdf, 50, 220, W_("Top position 200 (TopDown coordinates)"));
        bmk = pdfAddBookmarkW(pdf, W_("DestType dtFitH_Top (200)"), root, 5, 0);
        pdfSetBookmarkDest(pdf, bmk, dtFitH_Top, 200, 0, 0, 0);
        pdfSetBookmarkStyle(pdf, bmk, fsRegular, 0xC08080);
    pdfEndPage(pdf);

    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteTextW(pdf, 200, 50, W_("Bookmark destination type dtFitV_Left"));
        pdfWriteTextW(pdf, 200, 70, W_("Left position 200. FitV has no effect if the width of the page"));
        pdfWriteTextW(pdf, 200, 90, W_("is not greater as the height."));
        bmk = pdfAddBookmarkW(pdf, W_("DestType: dtFitV_Left (200)"), root, 6, 0);
        pdfSetBookmarkDest(pdf, bmk, dtFitV_Left, 200, 0, 0, 0);
        pdfSetBookmarkStyle(pdf, bmk, fsRegular, 0x808FFF);
    pdfEndPage(pdf);

    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteTextW(pdf, 50, 50, W_("Bookmark destination type dtFit_Rect"));
        x = (pdfGetPageWidth(pdf) - 90.0) / 2.0;
        y = (pdfGetPageHeight(pdf) - 65.0) / 2.0;

        pdfWriteFTextExW(pdf, x, y, 90.0, -1, taCenter, W_("We zoom into the rectangle"));
        pdfRectangle(pdf, x, y, 90.0, 65.0, fmStroke);

        pdfSetLinkHighlightMode(pdf, hmInvert);
        lnk = pdfPageLink(pdf, x, y, 90, 65, 7);
        act = pdfCreateGoToAction(pdf, dtFit_Rect, 7, x - 5.0, y - 5.0, x + 100.0, y + 70.0);
        pdfAddActionToObj(pdf, otPageLink, oeOnMouseUp, act, lnk);

        bmk = pdfAddBookmarkW(pdf, W_("DestType: dtFit_Rect"), -1, 7, 0);
        pdfAddActionToObj(pdf, otBookmark, oeOnMouseUp, act, bmk);
        pdfSetBookmarkStyle(pdf, bmk, fsRegular, 0x80FF);
    pdfEndPage(pdf);

    pdfSetPageFormat(pdf, pfDIN_A4);
    pdfAppend(pdf);
        pdfChangeFont(pdf, f);
        pdfWriteFTextExW(pdf, 50.0, 50.0, pdfGetPageWidth(pdf) - 100.0, -1.0, taLeft, W_("Destination type dtFit. This variant scales the page so that both sides fit into the viewer window."));
    pdfEndPage(pdf);

    root = pdfAddBookmarkW(pdf, W_("DestType dtFit"), -1, 8, 0);
    pdfSetBookmarkDest(pdf, root, dtFit, 0, 0, 0, 0);

    bmk = pdfAddBookmarkW(pdf, W_("DestType: dtXY_Zoom, zoom factor 3"), root, 2, 0);
    pdfSetBookmarkDest(pdf, bmk, dtXY_Zoom, 50, 50, 3, 0);
    pdfSetBookmarkStyle(pdf, bmk, fsBold, clMaroon);

    pdfSetPageLayout(pdf, plOneColumn);

    if(pdfHaveOpenDoc(pdf) != 0){
        std::string outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileW(pdf, (LWCHAR*)WS(outFile).c_str()) == 0){
            pdfDeletePDF(pdf);
            return 0;
        }
        if(pdfCloseFile(pdf) != 0)
            printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
    }
    pdfDeletePDF(pdf);
    return 0;
}

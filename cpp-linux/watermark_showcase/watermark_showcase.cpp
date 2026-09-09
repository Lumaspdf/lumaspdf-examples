// watermark_showcase -- the user-defined watermark API, feature by feature.
//
// One watermark configuration is active per document (pdfSetWatermarkText
// creates+enables it, pdfSetWatermark*Property refine it, pdfResetWatermark
// clears it); it is stamped onto the selected pages when the file is closed.
// So each capability below gets its own small PDF:
//
//   wm_1_diagonal.pdf   classic CONFIDENTIAL: fit to the page diagonal,
//                       auto angle, low opacity, under the content
//   wm_2_anchored.pdf   corner tag: anchor + offset + no rotation
//   wm_3_styled.pdf     outline + shadow + custom font, color and blend
//   wm_4_tiled.pdf      grid tiling with spacing across the whole page
//   wm_5_stamp.pdf      rounded-rect APPROVED stamp (shape behind text)
//   wm_6_pages.pdf      [page]/[pages] placeholders, odd pages only,
//                       starting at page 2
//
// Colors are 0xBBGGRR (COLORREF order, like the rest of the API).
#include <lumaspdf.h>
#include <cstdio>
#include <string>

static SI32 PDF_CALL PDFError(void*, SI32, const char* msg, SI32) {
    if (msg) std::printf("  engine: %s\n", msg);
    return 0;
}

static PPDF NewDoc(const std::string& file, int pages) {
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFA(pdf, file.c_str());
    pdfSetDocInfoA(pdf, diTitle, ("Watermark showcase: " + file).c_str());
    for (int i = 1; i <= pages; ++i) {
        pdfAppend(pdf);
        pdfSetFontA(pdf, "Helvetica", fsRegular, 14.0, 1, cp1252);
        char line[64];
        std::snprintf(line, sizeof line, "Body content, page %d", i);
        pdfWriteTextA(pdf, 50.0, 760.0, line);
        pdfEndPage(pdf);
    }
    return pdf;                          // watermark config goes in BEFORE close
}

static void Close(PPDF pdf, const char* name) {
    if (pdfCloseFile(pdf)) std::printf("wrote %s\n", name);
    else                   std::printf("FAILED %s\n", name);
    pdfDeletePDF(pdf);
}

int main() {
    // 1 -- the classic: diagonal CONFIDENTIAL under the page content --------
    PPDF pdf = NewDoc("wm_1_diagonal.pdf", 1);
    pdfSetWatermarkTextA(pdf, (char*)"C O N F I D E N T I A L",
                         0.0,          // FontSize 0 -> use fit mode below
                         0x0000CC,     // dark red (BBGGRR)
                         45.0,         // diagonal angle (fit mode scales, it does not rotate)
                         0.08);        // opacity
    pdfSetWatermarkIntProperty(pdf, wmpFitMode, wmfPageDiagonal);
    pdfSetWatermarkIntProperty(pdf, wmpLayer, wmlUnder);      // behind content
    pdfSetWatermarkDblProperty(pdf, wmpMargin, 90.0);   // keep clear of the corners
    Close(pdf, "wm_1_diagonal.pdf");

    // 2 -- anchored corner tag, no rotation ---------------------------------
    pdf = NewDoc("wm_2_anchored.pdf", 1);
    pdfSetWatermarkTextA(pdf, (char*)"INTERNAL USE ONLY", 11.0, 0x555555, 0.0, 0.9);
    pdfSetWatermarkIntProperty(pdf, wmpAnchor, wmaBottomRight);
    pdfSetWatermarkDblProperty(pdf, wmpOffsetX, -18.0);       // in from the corner
    pdfSetWatermarkDblProperty(pdf, wmpOffsetY, 18.0);
    Close(pdf, "wm_2_anchored.pdf");

    // 3 -- typography: font, outline, shadow, blend -------------------------
    pdf = NewDoc("wm_3_styled.pdf", 1);
    pdfSetWatermarkTextA(pdf, (char*)"DRAFT", 96.0, 0xFF9933, 30.0, 0.5);
    pdfSetWatermarkStrPropertyA(pdf, wmpFontName, (char*)"Helvetica");
    pdfSetWatermarkIntProperty(pdf, wmpFontStyle, fsBold);
    pdfSetWatermarkIntProperty(pdf, wmpOutlineEnabled, 1);
    pdfSetWatermarkDblProperty(pdf, wmpOutlineWidth, 1.2);
    pdfSetWatermarkClrProperty(pdf, wmpOutlineColor, wmcsCurrent, 0x883311);
    pdfSetWatermarkIntProperty(pdf, wmpShadowEnabled, 1);
    pdfSetWatermarkDblProperty(pdf, wmpShadowDistance, 3.0);
    pdfSetWatermarkDblProperty(pdf, wmpShadowOpacity, 0.35);
    Close(pdf, "wm_3_styled.pdf");

    // 4 -- tiling: repeat in a grid across the page -------------------------
    pdf = NewDoc("wm_4_tiled.pdf", 1);
    pdfSetWatermarkTextA(pdf, (char*)"SAMPLE", 18.0, 0x999999, 45.0, 0.15);
    pdfSetWatermarkIntProperty(pdf, wmpTileMode, wmtGrid);
    pdfSetWatermarkDblProperty(pdf, wmpTileSpacingX, 140.0);
    pdfSetWatermarkDblProperty(pdf, wmpTileSpacingY, 110.0);
    Close(pdf, "wm_4_tiled.pdf");

    // 5 -- stamp: rounded-rect shape behind the text ------------------------
    pdf = NewDoc("wm_5_stamp.pdf", 1);
    pdfSetWatermarkTextA(pdf, (char*)"APPROVED", 28.0, 0x009900, 0.0, 0.9);
    pdfSetWatermarkIntProperty(pdf, wmpShape, wmsRoundRect);
    pdfSetWatermarkIntProperty(pdf, wmpShapeStrokeEnabled, 1);
    pdfSetWatermarkDblProperty(pdf, wmpShapeLineWidth, 2.0);
    pdfSetWatermarkClrProperty(pdf, wmpShapeStrokeColor, wmcsCurrent, 0x009900);
    pdfSetWatermarkDblProperty(pdf, wmpShapeCornerRadius, 10.0);
    pdfSetWatermarkDblProperty(pdf, wmpShapePadding, 12.0);
    pdfSetWatermarkIntProperty(pdf, wmpAnchor, wmaTopRight);
    pdfSetWatermarkDblProperty(pdf, wmpAngle, 12.0);
    Close(pdf, "wm_5_stamp.pdf");

    // 6 -- per-page text and page selection ---------------------------------
    pdf = NewDoc("wm_6_pages.pdf", 4);
    pdfSetWatermarkTextA(pdf, (char*)"Copy [page] of [pages]", 16.0, 0x336699, 0.0, 0.8);
    pdfSetWatermarkIntProperty(pdf, wmpAnchor, wmaBottomCenter);
    pdfSetWatermarkIntProperty(pdf, wmpFirstPage, 2);         // skip page 1
    pdfSetWatermarkIntProperty(pdf, wmpPageParity, wmrEven);  // even pages only
    Close(pdf, "wm_6_pages.pdf");

    std::printf("watermark showcase: 6 PDFs written\n");
    return 0;
}

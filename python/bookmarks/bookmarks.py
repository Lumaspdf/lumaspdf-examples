# ============================================================================
#  bookmarks -- Python (ctypes) port of examples\Vb6\bookmarks\bookmarks.bas
#  Demonstrates the various bookmark destination types plus a page link with a
#  GoTo action.
# ============================================================================
import os
import sys
# the wrapper lives at <root>/wrappers/python (source checkout) or beside
# the example tree (shipped package) -- find it without a hard-coded path
_d = os.path.dirname(os.path.abspath(__file__))
for _ in range(6):
    for _c in (os.path.join(_d, 'wrappers', 'python'), _d):
        if os.path.isfile(os.path.join(_c, 'lumaspdf.py')):
            sys.path.insert(0, _c)
            break
    else:
        _d = os.path.dirname(_d)
        continue
    break
import lumaspdf as L

# VCL TColor values (COLORREF, R in low byte) used by SetBookmarkStyle.
clRed = 0xFF
clGreen = 0x8000
clBlue = 0xFF0000
clMaroon = 0x80


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0  # try to continue on error


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")  # output file opened later

    L.pdfSetPageCoords(pdf, L.pcTopDown)
    L.pdfSetPageHeight(pdf, 500.0)
    L.pdfSetPageWidth(pdf, 800.0)

    L.pdfAppend(pdf)
    f = L.pdfSetFontA(pdf, b"Helvetica", L.fsRegular, 20.0, 0, L.cp1252)
    L.pdfWriteTextA(pdf, 50, 50, b"Bookmark destination type dtFit")
    root = L.pdfAddBookmarkA(pdf, b"DestType dtFit", -1, 1, 1)
    L.pdfSetBookmarkDest(pdf, root, L.dtFit, 0, 0, 0, 0)
    L.pdfSetBookmarkStyle(pdf, root, L.fsItalic, clRed)
    L.pdfEndPage(pdf)

    L.pdfAppend(pdf)
    L.pdfChangeFont(pdf, f)
    L.pdfWriteTextA(pdf, 50, 50, b"Bookmark destination type dtXY_Zoom")
    L.pdfWriteTextA(pdf, 50, 70, b"Zoom factor 3, Top position 50 (TopDown coordinates)")
    bmk = L.pdfAddBookmarkA(pdf, b"DestType: dtXY_Zoom, zoom factor 3", root, 2, 0)
    L.pdfSetBookmarkDest(pdf, bmk, L.dtXY_Zoom, 50, 50, 3, 0)
    L.pdfSetBookmarkStyle(pdf, bmk, L.fsBold, clMaroon)
    L.pdfEndPage(pdf)

    L.pdfAppend(pdf)
    L.pdfChangeFont(pdf, f)
    L.pdfWriteTextA(pdf, 50, 50, b"Bookmark destination type dtXY_Zoom")
    L.pdfWriteTextA(pdf, 50, 70, b"Zoom factor 0.5, Top position 50 (TopDown coordinates)")
    bmk = L.pdfAddBookmarkA(pdf, b"DestType: dtXY_Zoom, zoom factor 0.5", root, 3, 0)
    L.pdfSetBookmarkDest(pdf, bmk, L.dtXY_Zoom, 50, 50, 0.5, 0)
    L.pdfSetBookmarkStyle(pdf, bmk, L.fsBold | L.fsItalic, clGreen)
    L.pdfEndPage(pdf)

    L.pdfAppend(pdf)
    L.pdfChangeFont(pdf, f)
    L.pdfWriteTextA(pdf, 50, 50, b"Bookmark destination type dtXY_Zoom")
    L.pdfWriteTextA(pdf, 50, 70, b"Zoom factor not defined (unchanged), Top position 50 (TopDown coordinates)")
    bmk = L.pdfAddBookmarkA(pdf, b"DestType: dtXY_Zoom, zoom factor unchanged", root, 4, 0)
    L.pdfSetBookmarkDest(pdf, bmk, L.dtXY_Zoom, 50, 50, 0, 0)
    L.pdfSetBookmarkStyle(pdf, bmk, L.fsRegular, clBlue)
    L.pdfEndPage(pdf)

    L.pdfAppend(pdf)
    L.pdfChangeFont(pdf, f)
    L.pdfWriteTextA(pdf, 50, 50, b"Bookmark destination type dtFitH_Top")
    L.pdfWriteTextA(pdf, 50, 70, b"Top position 50 (TopDown coordinates)")
    bmk = L.pdfAddBookmarkA(pdf, b"DestType: dtFitH_Top (50)", root, 5, 0)
    L.pdfSetBookmarkDest(pdf, bmk, L.dtFitH_Top, 50, 0, 0, 0)
    L.pdfSetBookmarkStyle(pdf, bmk, L.fsRegular, 0xFF8080)
    L.pdfWriteTextA(pdf, 50, 200, b"Bookmark destination type dtFitH_Top")
    L.pdfWriteTextA(pdf, 50, 220, b"Top position 200 (TopDown coordinates)")
    bmk = L.pdfAddBookmarkA(pdf, b"DestType dtFitH_Top (200)", root, 5, 0)
    L.pdfSetBookmarkDest(pdf, bmk, L.dtFitH_Top, 200, 0, 0, 0)
    L.pdfSetBookmarkStyle(pdf, bmk, L.fsRegular, 0xC08080)
    L.pdfEndPage(pdf)

    L.pdfAppend(pdf)
    L.pdfChangeFont(pdf, f)
    L.pdfWriteTextA(pdf, 200, 50, b"Bookmark destination type dtFitV_Left")
    L.pdfWriteTextA(pdf, 200, 70, b"Left position 200. FitV has no effect if the width of the page")
    L.pdfWriteTextA(pdf, 200, 90, b"is not greater as the height.")
    bmk = L.pdfAddBookmarkA(pdf, b"DestType: dtFitV_Left (200)", root, 6, 0)
    L.pdfSetBookmarkDest(pdf, bmk, L.dtFitV_Left, 200, 0, 0, 0)
    L.pdfSetBookmarkStyle(pdf, bmk, L.fsRegular, 0x808FFF)
    L.pdfEndPage(pdf)

    L.pdfAppend(pdf)
    L.pdfChangeFont(pdf, f)
    L.pdfWriteTextA(pdf, 50, 50, b"Bookmark destination type dtFit_Rect")
    x = (L.pdfGetPageWidth(pdf) - 90.0) / 2.0
    y = (L.pdfGetPageHeight(pdf) - 65.0) / 2.0

    L.pdfWriteFTextExA(pdf, x, y, 90.0, -1, L.taCenter, b"We zoom into the rectangle")
    L.pdfRectangle(pdf, x, y, 90.0, 65.0, L.fmStroke)

    # A page link with a GoTo action that zooms into the rectangle.
    L.pdfSetLinkHighlightMode(pdf, L.hmInvert)
    lnk = L.pdfPageLink(pdf, x, y, 90, 65, 7)
    act = L.pdfCreateGoToAction(pdf, L.dtFit_Rect, 7, x - 5.0, y - 5.0, x + 100.0, y + 70.0)
    L.pdfAddActionToObj(pdf, L.otPageLink, L.oeOnMouseUp, act, lnk)

    bmk = L.pdfAddBookmarkA(pdf, b"DestType: dtFit_Rect", -1, 7, 0)
    L.pdfAddActionToObj(pdf, L.otBookmark, L.oeOnMouseUp, act, bmk)
    L.pdfSetBookmarkStyle(pdf, bmk, L.fsRegular, 0x80FF)
    L.pdfEndPage(pdf)

    L.pdfSetPageFormat(pdf, L.pfDIN_A4)
    L.pdfAppend(pdf)
    L.pdfChangeFont(pdf, f)
    L.pdfWriteFTextExA(pdf, 50.0, 50.0, L.pdfGetPageWidth(pdf) - 100.0, -1.0, L.taLeft,
                       b"Destination type dtFit. This variant scales the page so that both sides fit into the viewer window.")
    L.pdfEndPage(pdf)

    root = L.pdfAddBookmarkA(pdf, b"DestType dtFit", -1, 8, 0)
    L.pdfSetBookmarkDest(pdf, root, L.dtFit, 0, 0, 0, 0)

    bmk = L.pdfAddBookmarkA(pdf, b"DestType: dtXY_Zoom, zoom factor 3", root, 2, 0)
    L.pdfSetBookmarkDest(pdf, bmk, L.dtXY_Zoom, 50, 50, 3, 0)
    L.pdfSetBookmarkStyle(pdf, bmk, L.fsBold, clMaroon)

    L.pdfSetPageLayout(pdf, L.plOneColumn)

    out_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out.pdf")
    if L.pdfHaveOpenDoc(pdf) != 0:
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
        if L.pdfCloseFile(pdf) != 0:
            print('PDF file "' + out_file + '" successfully created!')
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

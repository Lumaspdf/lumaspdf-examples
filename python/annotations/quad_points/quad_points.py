# ============================================================================
#  quad_points -- Python (ctypes) port of
#  examples\Vb6\annotations\quad_points\quad_points.bas
#  Highlight and link annotations rotated with the coordinate system by
#  setting their quad points explicitly.
# ============================================================================
import os
import sys
import ctypes
import os, sys
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

clYellow = 65535
clRed = 255
clBlue = 16711680


def inc_y(points, value):
    for i in range(len(points)):
        points[i].y = points[i].y + value


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    return 0


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")

    L.pdfSetPageCoords(pdf, L.pcTopDown)

    L.pdfAppend(pdf)

    L.pdfSaveGraphicState(pdf)

    L.pdfSetGStateFlags(pdf, L.gfRealTopDownCoords, 0)  # This simplifies the handling a little bit.
    L.pdfRotateCoords(pdf, -30.0, 50.0, 200.0)

    text = b"Some rotated text on a page..."
    L.pdfSetFontA(pdf, b"Helvetica", L.fsRegular, 20.0, 0, L.cp1252)

    d = L.pdfGetDescent(pdf)
    w = L.pdfGetTextWidthA(pdf, text)

    points = (L.TFltPoint * 4)()

    # Highlight annotations do not consider coordinate transformations made on a page.
    # To get such annotations rotated we must set the annotation's quad points.
    L.pdfWriteTextA(pdf, 0.0, 0.0, text)
    a = L.pdfHighlightAnnotA(pdf, L.atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, b"Test app", b"Highligh Annotations", b"This is a highlight annotation")
    # Consider the unusual order of the points!
    points[0].x = 0.0;  points[0].y = d          # Top left corner
    points[1].x = w;    points[1].y = d          # Top right corner
    points[2].x = 0.0;  points[2].y = 20.0 + d   # Bottom left corner
    points[3].x = w;    points[3].y = 20.0 + d   # Bottom right corner
    L.pdfSetAnnotQuadPoints(pdf, a, ctypes.byref(points), 4)

    L.pdfWriteTextA(pdf, 0.0, 30.0, text)
    a = L.pdfHighlightAnnotA(pdf, L.atSquiggly, 50.0, 80.0, w, 20.0, clRed, b"Test app", b"Squiggly Annotations", b"This is a squiggly annotation")
    inc_y(points, 30.0)
    L.pdfSetAnnotQuadPoints(pdf, a, ctypes.byref(points), 4)

    L.pdfWriteTextA(pdf, 0.0, 60.0, text)
    a = L.pdfHighlightAnnotA(pdf, L.atStrikeOut, 50.0, 110.0, w, 20.0, clRed, b"Test app", b"Strikeout Annotations", b"This is a strikeout annotation")
    inc_y(points, 30.0)
    L.pdfSetAnnotQuadPoints(pdf, a, ctypes.byref(points), 4)

    L.pdfWriteTextA(pdf, 0.0, 90.0, text)
    a = L.pdfHighlightAnnotA(pdf, L.atUnderline, 50.0, 140.0, w, 20.0, clRed, b"Test app", b"Underline Annotations", b"This is a underline annotation")
    inc_y(points, 30.0)
    L.pdfSetAnnotQuadPoints(pdf, a, ctypes.byref(points), 4)

    text = b"Link annotations support quad points too"
    w = L.pdfGetTextWidthA(pdf, text)
    L.pdfWriteTextA(pdf, 0.0, 120.0, text)
    # Link annotations support quad points too.
    a = L.pdfWebLinkA(pdf, 0.0, 120.0, w, 20.0, b"www.dynaforms.com")
    L.pdfSetAnnotBorderWidth(pdf, a, 1.0)
    L.pdfSetAnnotColor(pdf, a, L.fcBorderColor, L.csDeviceRGB, clBlue)
    points[0].x = 0.0;  points[0].y = 120.0 + d   # Top left corner
    points[1].x = w;    points[1].y = 120.0 + d   # Top right corner
    points[2].x = 0.0;  points[2].y = 140.0 + d   # Bottom left corner
    points[3].x = w;    points[3].y = 140.0 + d   # Bottom right corner
    L.pdfSetAnnotQuadPoints(pdf, a, ctypes.byref(points), 4)

    L.pdfRestoreGraphicState(pdf)

    L.pdfEndPage(pdf)

    if L.pdfHaveOpenDoc(pdf) != 0:
        out_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out.pdf")
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
        if L.pdfCloseFile(pdf) != 0:
            print('PDF file "' + out_file + '" successfully created!')

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

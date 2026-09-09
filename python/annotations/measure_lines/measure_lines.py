# ============================================================================
#  measure_lines -- Python (ctypes) port of
#  examples\Vb6\annotations\measure_lines\measure_lines.bas
#  Two dimension/measure line annotations on a rotated rectangle, configured
#  through a TLineAnnotParms record.
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

clCream = 15793151
clBlack = 0


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    return 0


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")

    L.pdfSetPageCoords(pdf, L.pcTopDown)

    L.pdfAppend(pdf)

    w = 300.0
    h = 100.0
    x = L.pdfGetPageWidth(pdf) / 2
    y = L.pdfGetPageHeight(pdf) / 2

    # Save the graphics state because the coordinate system will be rotated.
    L.pdfSaveGraphicState(pdf)

    L.pdfSetGStateFlags(pdf, L.gfRealTopDownCoords, 0)  # This simplifies the handling a little bit.
    L.pdfRotateCoords(pdf, -30.0, x, y)

    x = -w / 2
    y = -h / 2

    L.pdfSetFillColor(pdf, clCream)
    L.pdfRectangle(pdf, x, y, w, h, L.fmFillStroke)

    txt = ("%.1f" % w).encode("latin-1")
    a = L.pdfLineAnnotA(pdf, x, y, x + w, y, 1.0, L.leClosedArrow, L.leClosedArrow, clBlack, clBlack, L.csDeviceRGB, b"This is a measure line", b"Measure Line", txt)

    p = L.TLineAnnotParms()
    p.StructSize = ctypes.sizeof(L.TLineAnnotParms)
    p.Caption = 1              # The parameter Content of LineAnnot() is used as caption.
    p.LeaderLineLen = 10.0
    p.LeaderLineExtend = 4.0   # Try different values to understand what these parameters change.
    p.LeaderLineOffset = 2.0
    L.pdfSetLineAnnotParms(pdf, a, -1, 0.0, ctypes.byref(p))

    txt = ("%.1f" % h).encode("latin-1")
    a = L.pdfLineAnnotA(pdf, x, y + h, x, y, 1.0, L.leClosedArrow, L.leClosedArrow, clBlack, clBlack, L.csDeviceRGB, b"This is a measure line", b"Measure Line", txt)
    # The parameters are exactly the same as above
    L.pdfSetLineAnnotParms(pdf, a, -1, 0.0, ctypes.byref(p))

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

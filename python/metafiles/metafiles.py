# ============================================================================
#  metafiles -- Python (ctypes) port of examples\Vb6\metafiles\metafiles.bas
#  Places three EMF metafiles, each centered and scaled to a landscape page,
#  with a red frame around them.
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

CLR_RED = 255
MARGIN = 10.0


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0


def place_emf_centered(pdf, mfile, width, height):
    r = L.TRectL()
    L.pdfGetLogMetafileSizeA(pdf, mfile.encode("latin-1"), r)
    w = r.Right - r.Left
    h = r.Bottom - r.Top
    width = width - 2.0 * MARGIN
    height = height - 2.0 * MARGIN
    sx = width / w

    if h * sx <= height:
        x = MARGIN
        h = h * sx
        y = (height - h) / 2.0
        L.pdfInsertMetafileA(pdf, mfile.encode("latin-1"), x, y, width, 0.0)
        L.pdfSetStrokeColor(pdf, CLR_RED)
        L.pdfRectangle(pdf, x, y, width, h, L.fmStroke)
    else:
        sx = height / h
        w = w * sx
        x = (width - w) / 2.0
        y = MARGIN
        L.pdfInsertMetafileA(pdf, mfile.encode("latin-1"), x, y, 0.0, height)
        L.pdfSetStrokeColor(pdf, CLR_RED)
        L.pdfRectangle(pdf, x, y, w, height, L.fmStroke)


def main():
    here = os.path.dirname(os.path.abspath(__file__))

    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    if L.pdfCreateNewPDFA(pdf, b"") == 0:
        L.pdfDeletePDF(pdf)
        return

    L.pdfSetPageCoords(pdf, L.pcTopDown)

    for name in ("coords.emf", "fulltest.emf", "gdi.emf"):
        L.pdfAppend(pdf)
        L.pdfSetOrientationEx(pdf, 90)
        place_emf_centered(pdf, os.path.join(here, name),
                           L.pdfGetPageWidth(pdf), L.pdfGetPageHeight(pdf))
        L.pdfEndPage(pdf)

    if L.pdfHaveOpenDoc(pdf) != 0:
        out_file = os.path.join(here, "out.pdf")
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
        if L.pdfCloseFile(pdf) != 0:
            print('PDF file "' + out_file + '" successfully created!')
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

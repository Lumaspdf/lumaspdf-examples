import sys, os, ctypes
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

# alpha_transparency -- Python (ctypes) port of the VB6 mirror.
# Draws an image at fill alpha 0.5 and a second at the default alpha 1.0
# using extended graphics states.

HERE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.join(HERE, "..", "..", "..", "test_files", "images", "tree-frog-69813_640.jpg")

clWhite = 0xFFFFFF
clBlack = 0x000000


def _err(data, code, msg, typ):
    if msg:
        print(msg.decode('latin-1', 'replace'))
    return 0


_cb = L.TErrorProc(_err)  # keep global ref


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, _cb)
    L.pdfCreateNewPDFA(pdf, b"")

    L.pdfSetPageCoords(pdf, L.pcTopDown)
    L.pdfSetUseTransparency(pdf, 0)  # disable color key masking for images

    L.pdfAppend(pdf)

    L.pdfSetFontA(pdf, b"Helvetica", L.fsRegular, 12.0, 0, L.cp1252)
    L.pdfWriteTextA(pdf, 50.0, 50.0, b"Fill Alpha = 0.5")

    L.pdfRectangle(pdf, 50.0, 70.0, 110.0, 160.0, L.fmFill)
    L.pdfSetFillColor(pdf, clWhite)
    L.pdfWriteTextA(pdf, 55.0, 75.0, b"Background")

    g = L.TPDFExtGState()
    L.pdfInitExtGState(ctypes.byref(g))
    g.FillAlpha = 0.5
    gs = L.pdfCreateExtGState(pdf, ctypes.byref(g))
    L.pdfSetExtGState(pdf, gs)

    img = L.pdfInsertImageExA(pdf, 60.0, 84.0, 200.0, 0.0, IMG.encode('latin-1'), 0)

    # Restore by creating a second state that undoes the change and activate it.
    g.FillAlpha = 1.0
    gs = L.pdfCreateExtGState(pdf, ctypes.byref(g))
    L.pdfSetExtGState(pdf, gs)

    L.pdfSetFillColor(pdf, clBlack)
    L.pdfWriteTextA(pdf, 340.0, 50.0, b"Fill Alpha = 1.0 (default)")
    L.pdfRectangle(pdf, 340.0, 70.0, 110.0, 160.0, L.fmFill)
    L.pdfSetFillColor(pdf, clWhite)
    L.pdfWriteTextA(pdf, 345.0, 75.0, b"Background")
    L.pdfPlaceImage(pdf, img, 350.0, 84.0, 200.0, 0.0)

    L.pdfEndPage(pdf)

    if L.pdfHaveOpenDoc(pdf) != 0:
        outFile = os.path.join(HERE, "out.pdf")
        if L.pdfOpenOutputFileA(pdf, outFile.encode('latin-1')) == 0:
            L.pdfDeletePDF(pdf)
            return
        if L.pdfCloseFile(pdf) != 0:
            print('PDF file "' + outFile + '" successfully created!')

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

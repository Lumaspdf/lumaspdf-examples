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

# softmask -- Python (ctypes) port of the VB6 mirror.
# Creates a transparency group used as a luminosity soft mask (radial
# shading) and applies it to an image.

HERE = os.path.dirname(os.path.abspath(__file__))
IMG_MEADOW = os.path.join(HERE, "..", "..", "..", "test_files", "images", "meadow-110719_640.jpg")
IMG_FROG = os.path.join(HERE, "..", "..", "..", "test_files", "images", "tree-frog-69813_640.jpg")


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
    L.pdfWriteTextA(pdf, 50.0, 50.0, b"Transparency effect with a soft mask.")

    L.pdfInsertImageExA(pdf, 50.0, 80.0, L.pdfGetPageWidth(pdf) - 100.0, 0.0,
                        IMG_MEADOW.encode('latin-1'), 1)

    # A group used as a soft mask has no own coordinate system. Create it in
    # full page size to avoid coordinate issues; the real bbox is computed after.
    grp = L.pdfBeginTransparencyGroup(pdf, 0.0, 0.0, L.pdfGetPageWidth(pdf),
                                      L.pdfGetPageHeight(pdf), 1, 0, L.esDeviceGray, -1)
    L.pdfSetColorSpace(pdf, L.csDeviceGray)
    sh = L.pdfCreateRadialShading(pdf, 400.0, 230.0, 20.0, 400.0, 230.0, 150.0,
                                  1.0, 255, 0, 1, 0)
    L.pdfApplyShading(pdf, sh)
    bbox = L.TPDFRect()
    L.pdfComputeBBox(pdf, ctypes.byref(bbox), L.cbfNone)
    L.pdfSetBBox(pdf, L.pbMediaBox, bbox.Left, bbox.Bottom, bbox.Right, bbox.Top)
    L.pdfEndTemplate(pdf)

    g = L.TPDFExtGState()
    L.pdfInitExtGState(ctypes.byref(g))
    g.SoftMask = L.pdfCreateSoftMask(pdf, grp, L.smtLuminosity, 0)
    gs = L.pdfCreateExtGState(pdf, ctypes.byref(g))

    L.pdfSetExtGState(pdf, gs)
    L.pdfInsertImageExA(pdf, 220.0, 80.0, 500.0, 0.0, IMG_FROG.encode('latin-1'), 1)

    # Deactivate the soft mask.
    L.pdfInitExtGState(ctypes.byref(g))
    g.SoftMaskNone = 1
    gs = L.pdfCreateExtGState(pdf, ctypes.byref(g))
    L.pdfSetExtGState(pdf, gs)

    L.pdfWriteTextA(pdf, 50.0, 400.0, b"The soft mask is now deactivated.")
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

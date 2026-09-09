# ============================================================================
#  metafiles_gui -- Python (ctypes) port of examples\Vb6\metafiles_gui\metafiles_gui.bas
#  The Delphi original was a Forms application (metafile viewer/converter); the
#  PDF logic lived in the tbConvertClick handler. Reproduced here as a plain
#  main(): loads an EMF/WMF file, places it centered on a page, writes out.pdf.
#  The interactive UI and preview-flag checkboxes are dropped (flags = mfDefault).
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

MARGIN = 10.0


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0


def place_emf_centered(pdf, mfile, width, height):
    r = L.TRectL()
    L.pdfGetLogMetafileSize(pdf, mfile.encode("latin-1"), r)
    w = r.Right - r.Left
    h = r.Bottom - r.Top
    width = width - 2.0 * MARGIN
    height = height - 2.0 * MARGIN
    sx = width / w
    if h * sx <= height:
        x = MARGIN
        y = MARGIN
        L.pdfInsertMetafile(pdf, mfile.encode("latin-1"), x, y, width, 0.0)
    else:
        sx = height / h
        w = w * sx
        x = MARGIN + (width - w) / 2.0
        y = MARGIN
        L.pdfInsertMetafile(pdf, mfile.encode("latin-1"), x, y, 0.0, height)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    in_file = os.path.join(here, "in.emf")
    out_file = os.path.join(here, "out.pdf")

    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    # We use flate compression for better transparency support.
    L.pdfSetCompressionFilter(pdf, L.cfFlate)
    L.pdfSetJPEGQuality(pdf, 70)

    if L.pdfCreateNewPDFA(pdf, b"") == 0:
        L.pdfDeletePDF(pdf)
        return

    L.pdfSetCompressionLevel(pdf, L.clNone)     # "compress" checkbox default off
    L.pdfSetCompressionFilter(pdf, L.cfFlate)   # "JPEG" checkbox default off
    L.pdfSetColorSpace(pdf, L.csDeviceRGB)      # "CMYK" checkbox default off
    L.pdfSetMetaConvFlags(pdf, L.mfDefault)     # no preview flags selected
    L.pdfSetPageCoords(pdf, L.pcTopDown)
    L.pdfAppend(pdf)
    L.pdfSetResolution(pdf, 300)
    L.pdfSetJPEGQuality(pdf, 70)
    place_emf_centered(pdf, in_file, L.pdfGetPageWidth(pdf), L.pdfGetPageHeight(pdf))
    L.pdfEndPage(pdf)

    if L.pdfHaveOpenDoc(pdf) != 0:
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfFreePDF(pdf)
            L.pdfDeletePDF(pdf)
            return
        if L.pdfCloseFile(pdf) != 0:
            print("OK: " + out_file)

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

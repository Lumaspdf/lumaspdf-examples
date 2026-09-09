import sys, os, ctypes
import os, sys


def _here(name):
    """A fixture that ships with the examples, found without a
    hard-coded path: walk up looking for test_files/."""
    d = os.path.dirname(os.path.abspath(__file__))
    for _ in range(6):
        c = os.path.join(d, 'test_files', name)
        if os.path.isfile(c):
            return c
        d = os.path.dirname(d)
    return name

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

# ============================================================================
#  render_page -- Python (ctypes) port of examples\Vb6\rendering_engine\render_page
#  Load the PDF, import the first page, and render it to a TIFF image file
#  via pdfRenderPageToImage (the flat "render this page" export).
# ============================================================================

HERE = os.path.dirname(os.path.abspath(__file__))
SRC_PDF = _here('dynapdf_help.pdf')
CMAP_DIR = _here('')

ERRPROC = ctypes.WINFUNCTYPE(ctypes.c_int32, ctypes.c_void_p, ctypes.c_int32,
                             ctypes.c_char_p, ctypes.c_int32)


def _pdferr(data, code, msg, typ):
    if msg:
        print(msg.decode('latin-1', 'replace'))
    return 0


_errcb = ERRPROC(_pdferr)


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, _errcb)
    L.pdfCreateNewPDFA(pdf, b"")   # We create no PDF file in this example

    # Absolute CMap path. lcmDelayed loads the cmaps only if necessary.
    L.pdfSetCMapDirA(pdf, CMAP_DIR.encode('latin-1'), L.lcmRecursive | L.lcmDelayed)

    if L.pdfOpenImportFileA(pdf, SRC_PDF.encode('latin-1'), L.ptOpen, b"") < 0:
        L.pdfDeletePDF(pdf)
        return

    # Import pages manually: only the output intent is needed for color mgmt, then reset.
    L.pdfSetImportFlags(pdf, L.ifContentOnly)
    L.pdfImportCatalogObjects(pdf)
    L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage)  # don't convert pages to templates
    L.pdfSetImportFlags2(pdf, L.if2UseProxy)                    # reduces memory usage

    pageCount = L.pdfGetInPageCount(pdf)
    if pageCount < 1:
        L.pdfDeletePDF(pdf)
        return

    # We render only the first page in this example.
    L.pdfAppend(pdf)
    L.pdfImportPageEx(pdf, 1, 1.0, 1.0)
    L.pdfEndPage(pdf)

    # Confirm the page object exists (as the GUI viewer does before rendering).
    if L.pdfGetPageObject(pdf, 1) == 0:
        L.pdfDeletePDF(pdf)
        return

    dc = ctypes.windll.user32.GetDC(0)
    w = ctypes.windll.gdi32.GetDeviceCaps(dc, 8)  # HORZRES
    ctypes.windll.user32.ReleaseDC(0, dc)

    outFile = os.path.join(HERE, "render_page.tif")
    if L.pdfRenderPageToImageA(pdf, 1, outFile.encode('latin-1'), 0, w, 0,
                               L.rfDefault, L.pxfRGB, L.cfLZW, L.ifmTIFF) != 0:
        print("Rendered page 1 to " + outFile)

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

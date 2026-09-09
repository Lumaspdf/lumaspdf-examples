# ============================================================================
#  layers -- Python (ctypes) port of examples\Vb6\layers\layers\layers.bas
#  Creates three nested optional-content groups (layers) and places text (with a
#  web link) and an image into them.
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

clBlue = 0xFF0000
clBlack = 0x0
IMG = r"test_files\images\margarita-102572_640.jpg"


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0


def main():
    here = os.path.dirname(os.path.abspath(__file__))

    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")

    L.pdfSetPageCoords(pdf, L.pcTopDown)
    L.pdfSetUseTransparency(pdf, 0)

    oc1 = L.pdfCreateOCGA(pdf, b"All", 1, 1, L.oiAll)
    oc2 = L.pdfCreateOCGA(pdf, b"Text and Annotations", 1, 1, L.oiAll)
    oc3 = L.pdfCreateOCGA(pdf, b"Images", 1, 1, L.oiAll)

    L.pdfAppend(pdf)
    L.pdfBeginLayer(pdf, oc1)
    L.pdfBeginLayer(pdf, oc2)
    L.pdfSetFontA(pdf, b"Helvetica", L.fsRegular, 12.0, 0, L.cp1252)
    some_text = b"Some text with a link!!!"
    L.pdfSetFillColor(pdf, clBlue)
    L.pdfWriteTextA(pdf, 50.0, 50.0, some_text)
    tw = L.pdfGetTextWidthA(pdf, some_text)
    L.pdfSetBorderStyle(pdf, L.bsUnderline)
    L.pdfSetStrokeColor(pdf, clBlue)
    annot = L.pdfWebLinkA(pdf, 50.0, 51.0, tw, 12.0, b"www.dynaforms.com")

    oc_array = (ctypes.c_int32 * 2)(oc1, oc2)
    ocmd = L.pdfCreateOCMD(pdf, L.ovAllOn, ctypes.cast(oc_array, ctypes.c_void_p), 2)
    L.pdfAddObjectToLayer(pdf, ocmd, L.ooAnnotation, annot)
    L.pdfEndLayer(pdf)

    L.pdfBeginLayer(pdf, oc3)
    L.pdfInsertImageExA(pdf, 50.0, 70.0, 300.0, 200.0, IMG.encode("latin-1"), 1)
    L.pdfEndLayer(pdf)
    L.pdfEndLayer(pdf)

    L.pdfSetFillColor(pdf, clBlack)
    L.pdfWriteTextA(pdf, 50.0, 300.0, b"This text is not part of a layer!")
    L.pdfEndPage(pdf)

    L.pdfSetPageMode(pdf, L.pmUseOC)

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

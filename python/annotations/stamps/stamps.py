# ============================================================================
#  stamps -- Python (ctypes) port of examples\Vb6\annotations\stamps\stamps.bas
#  A pre-defined "Approved" stamp rendered in English, German and French.
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


def RGB(r, g, b):
    return r | (g << 8) | (b << 16)


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    return 0


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")

    L.pdfSetPageCoords(pdf, L.pcTopDown)

    L.pdfAppend(pdf)

    # A pre-defined stamp is scaled to the given width. The language can be set right before creating the stamp.
    a = L.pdfStampAnnotA(pdf, L.rsApproved, 135.0, 50.0, 300.0, 10.0, b"Test app", b"Stamp Annotations", b"The default language is English!")
    L.pdfSetAnnotColor(pdf, a, L.fcBorderColor, L.csDeviceRGB, RGB(120, 190, 92))

    L.pdfSetLanguage(pdf, b"DE")
    a = L.pdfStampAnnotA(pdf, L.rsApproved, 135.0, 150.0, 300.0, 10.0, b"Test app", b"Stamp Annotations", b"The same stamp in German!")
    L.pdfSetAnnotColor(pdf, a, L.fcBorderColor, L.csDeviceRGB, RGB(230, 65, 132))

    L.pdfSetLanguage(pdf, b"FR")
    a = L.pdfStampAnnotA(pdf, L.rsApproved, 135.0, 250.0, 300.0, 10.0, b"Test app", b"Stamp Annotations", b"The same stamp in French!")
    L.pdfSetAnnotColor(pdf, a, L.fcBorderColor, L.csDeviceRGB, RGB(78, 157, 232))
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

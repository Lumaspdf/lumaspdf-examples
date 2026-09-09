# ============================================================================
#  highlight_annotations -- Python (ctypes) port of
#  examples\Vb6\annotations\highlight_annotations\highlight_annotations.bas
#  Highlight / squiggly / strikeout / underline annotations over text.
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

clYellow = 65535
clRed = 255


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    return 0


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")

    L.pdfSetPageCoords(pdf, L.pcTopDown)

    L.pdfAppend(pdf)
    text = b"Some text on a page..."
    L.pdfSetFontA(pdf, b"Helvetica", L.fsRegular, 20.0, 0, L.cp1252)

    d = L.pdfGetDescent(pdf)
    w = L.pdfGetTextWidthA(pdf, text)

    L.pdfWriteTextA(pdf, 50.0, 50.0, text)
    L.pdfHighlightAnnotA(pdf, L.atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, b"Test app", b"Highligh Annotations", b"This is a highlight annotation")

    L.pdfWriteTextA(pdf, 50.0, 80.0, text)
    L.pdfHighlightAnnotA(pdf, L.atSquiggly, 50.0, 80.0 + d, w, 20.0, clRed, b"Test app", b"Squiggly Annotations", b"This is a squiggly annotation")

    L.pdfWriteTextA(pdf, 50.0, 110.0, text)
    L.pdfHighlightAnnotA(pdf, L.atStrikeOut, 50.0, 110.0 + d, w, 20.0, clRed, b"Test app", b"Strikeout Annotations", b"This is a strikeout annotation")

    L.pdfWriteTextA(pdf, 50.0, 140.0, text)
    L.pdfHighlightAnnotA(pdf, L.atUnderline, 50.0, 140.0 + d, w, 20.0, clRed, b"Test app", b"Underline Annotations", b"This is a underline annotation")
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

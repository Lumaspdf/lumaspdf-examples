# ============================================================================
#  complex_text -- Python (ctypes) port of
#  examples\Vb6\complex_text\complex_text\complex_text.bas
#  Complex text layout of a right-to-left (Pashto) text. The text is loaded as
#  UTF-16 and laid out with the wide version of WriteFTextEx().
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

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, "..", "..", "..", "test_files")


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0  # try to continue on error


def get_file_buffer(filename):
    try:
        with open(filename, "rb") as fh:
            data = fh.read()
    except OSError:
        return ""
    return data.decode("utf-16-le", "replace")


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfCreateNewPDFA(pdf, b"")  # output opened later

    txt = get_file_buffer(os.path.join(TEST, "pashto.txt"))

    L.pdfSetPageCoords(pdf, L.pcTopDown)
    # Enable complex text layout
    L.pdfSetGStateFlags(pdf, L.gfComplexText, 0)
    L.pdfSetBidiMode(pdf, L.bmRightToLeft)

    L.pdfAppend(pdf)

    # The font must be loaded with cpUnicode.
    L.pdfSetFontA(pdf, b"Arial", L.fsRegular, 10.0, 1, L.cpUnicode)
    L.pdfSetLeading(pdf, L.pdfGetTypoLeading(pdf))
    L.pdfWriteFTextExW(pdf, 50.0, 50.0, L.pdfGetPageWidth(pdf) - 100.0,
                       L.pdfGetPageHeight(pdf) - 100.0, L.taJustify, txt)

    L.pdfEndPage(pdf)

    out_file = os.path.join(HERE, "out.pdf")
    if L.pdfHaveOpenDoc(pdf) != 0:
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
    if L.pdfCloseFile(pdf) != 0:
        print('PDF file "' + out_file + '" successfully created!')
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

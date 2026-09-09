# ============================================================================
#  pdf_to_text -- Python (ctypes) port of examples\Vb6\pdf_to_text\pdf_to_text.bas
#  Imports a PDF and extracts the text of every page (pdfSplitPageTextA) to out.txt.
# ============================================================================
import os
import sys


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

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURE = _here('dynapdf_help.pdf')

emNoFuncNames = 0x10000000  # not in the wrapper enum; from dynapdf.pas


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0  # try to continue on error


def cstr(p):
    if not p:
        return ""
    import ctypes
    return ctypes.cast(p, ctypes.c_char_p).value.decode("latin-1", "replace")


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetErrorMode(pdf, emNoFuncNames)  # do not print function names in errors
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    # External cmaps should always be loaded when extracting text.
    L.pdfSetCMapDirA(pdf, os.path.join(HERE, "CMap").encode("latin-1"), L.lcmRecursive | L.lcmDelayed)

    # We do not produce a PDF file here.
    if L.pdfCreateNewPDFA(pdf, b"") == 0:
        L.pdfDeletePDF(pdf)
        return

    # Import the page contents only (anything else is ignored for text extraction).
    L.pdfSetImportFlags(pdf, L.ifContentOnly | L.ifImportAsPage)
    in_file = FIXTURE
    if L.pdfOpenImportFileA(pdf, in_file.encode("latin-1"), L.ptOpen, b"") < 0:
        L.pdfFreePDF(pdf)
        L.pdfDeletePDF(pdf)
        return
    if L.pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0:
        L.pdfFreePDF(pdf)
        L.pdfDeletePDF(pdf)
        return
    L.pdfCloseImportFile(pdf)

    out_file = os.path.join(HERE, "out.txt")
    with open(out_file, "w", encoding="latin-1", errors="replace") as f:
        count = L.pdfGetPageCount(pdf)
        for i in range(1, count + 1):
            f.write("----- Page %d -----\n" % i)
            L.pdfEditPage(pdf, i)
            f.write(cstr(L.pdfSplitPageTextA(pdf, i)) + "\n")
            L.pdfEndPage(pdf)

    L.pdfFreePDF(pdf)
    print("Text written to: " + out_file)
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

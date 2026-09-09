# ============================================================================
#  optimize -- Python (ctypes) port of examples\Vb6\optimize\optimize.bas
#  Imports a PDF, runs Optimize() over it and writes the result.
# ============================================================================
import os
import sys
import ctypes
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

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURE = _here('dynapdf_help.pdf')


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return 0  # return zero to continue


def optimize(pdf, in_file, out_file):
    L.pdfCreateNewPDFA(pdf, b"")              # output file opened later
    L.pdfSetDocInfoA(pdf, L.diProducer, b"")  # keep the original producer

    # ifImportAsPage avoids converting pages to templates; drop the piece info dictionary.
    L.pdfSetImportFlags(pdf, (L.ifImportAll | L.ifImportAsPage) & ~L.ifPieceInfo)
    # if2UseProxy reduces memory usage; duplicate check + normalize recommended.
    L.pdfSetImportFlags2(pdf, L.if2UseProxy | L.if2DuplicateCheck | L.if2Normalize | L.if2NoResNameCheck)
    if L.pdfOpenImportFileA(pdf, in_file.encode("latin-1"), L.ptOpen, b"") < 0:
        L.pdfFreePDF(pdf)
        return False
    L.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
    L.pdfCloseImportFile(pdf)

    L.pdfOptimize(pdf, L.ofInMemory | L.ofNewLinkNames | L.ofDeleteInvPaths, None)

    e = L.TPDFError()
    e.StructSize = ctypes.sizeof(L.TPDFError)
    for i in range(L.pdfGetErrLogMessageCount(pdf)):
        L.pdfGetErrLogMessage(pdf, i, e)
        if e.Msg:
            print(ctypes.cast(e.Msg, ctypes.c_char_p).value.decode("latin-1", "replace"))

    if L.pdfHaveOpenDoc(pdf) != 0:
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfFreePDF(pdf)
            return False
        return L.pdfCloseFile(pdf) != 0
    return False


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    L.pdfSetCMapDirA(pdf, os.path.join(HERE, "CMap").encode("latin-1"), L.lcmDelayed | L.lcmRecursive)

    out_file = os.path.join(HERE, "out.pdf")
    in_file = FIXTURE
    if optimize(pdf, in_file, out_file):
        print('PDF file "' + out_file + '" successfully created!')
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

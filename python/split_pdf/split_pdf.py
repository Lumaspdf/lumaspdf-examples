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

# split_pdf -- port of examples\Vb6\split_pdf\split_pdf.bas
# Opens one import file, keeps it open across CloseFile() via
# SetUseGlobalImpFiles, and writes each page into its own PDF.

HERE = os.path.dirname(os.path.abspath(__file__))

ERRPROC = ctypes.WINFUNCTYPE(ctypes.c_int32, ctypes.c_void_p, ctypes.c_int32,
                             ctypes.c_char_p, ctypes.c_int32)


def _err(data, code, msg, typ):
    if msg:
        print(msg.decode("latin-1", "replace"))
    return 0


_cb = ERRPROC(_err)


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, _cb)

    L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage)  # keep pages as pages
    L.pdfSetImportFlags2(pdf, L.if2UseProxy)                    # reduce memory usage

    in_file = os.path.join(HERE, "license.pdf")
    if L.pdfOpenImportFileA(pdf, in_file.encode("latin-1"), L.ptOpen, b"") < 0:
        L.pdfDeletePDF(pdf)
        return

    # Keep the open import file from being closed when CloseFile() is called.
    L.pdfSetUseGlobalImpFiles(pdf, 1)

    out_dir = os.path.join(HERE, "out")
    os.makedirs(out_dir, exist_ok=True)

    count = L.pdfGetInPageCount(pdf)
    for i in range(1, count + 1):
        out_path = os.path.join(out_dir, "page%04d.pdf" % i)
        L.pdfCreateNewPDFA(pdf, out_path.encode("latin-1"))
        L.pdfAppend(pdf)
        L.pdfImportPageEx(pdf, i, 1.0, 1.0)
        L.pdfEndPage(pdf)
        L.pdfCloseFile(pdf)

    # Always set the property back to false when finished.
    L.pdfSetUseGlobalImpFiles(pdf, 0)

    print("Pages written to: " + out_dir)
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

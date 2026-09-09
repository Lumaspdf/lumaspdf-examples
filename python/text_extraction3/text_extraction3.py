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

# text_extraction3 -- Python (ctypes) port of the VB6 mirror.
# Imports a PDF and extracts its text page by page with pdfExtractText,
# writing the result to out.txt as UTF-16LE (with BOM).

HERE = os.path.dirname(os.path.abspath(__file__))


def _err(data, code, msg, typ):
    if msg:
        print(msg.decode('latin-1', 'replace'))
    return 0


_cb = L.TErrorProc(_err)  # keep global ref


def main():
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, _cb)
    L.pdfCreateNewPDFA(pdf, b"")

    L.pdfSetCMapDirA(pdf, os.path.join(HERE, "CMap").encode('latin-1'),
                     L.lcmRecursive | L.lcmDelayed)

    L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage)

    inFile = os.path.join(HERE, "in.pdf")
    if L.pdfOpenImportFileA(pdf, inFile.encode('latin-1'), L.ptOpen, b"") < 0:
        L.pdfDeletePDF(pdf)
        return
    L.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
    L.pdfCloseImportFile(pdf)

    L.pdfFlattenAnnots(pdf, L.affMarkupAnnots)
    L.pdfFlattenForm(pdf)

    outFile = os.path.join(HERE, "out.txt")
    f = open(outFile, "wb")
    f.write(bytes((255, 254)))  # UTF-16LE BOM

    cnt = L.pdfGetPageCount(pdf)
    for i in range(1, cnt + 1):
        if i > 1:
            f.write("\r\n".encode('utf-16-le'))
        f.write(("%%----------------------- Page %d -----------------------------\r\n" % i).encode('utf-16-le'))

        textPtr = ctypes.c_void_p(0)
        textLen = ctypes.c_uint32(0)
        # Not recommended to sort text on the y-axis - it sometimes causes strange results.
        if L.pdfExtractText(pdf, i, L.tefDeleteOverlappingText | L.tefSortTextX, 0,
                            ctypes.byref(textPtr), ctypes.byref(textLen)) != 0:
            if textLen.value > 0 and textPtr.value:
                f.write(ctypes.string_at(textPtr.value, textLen.value * 2))
    f.close()

    print("Text successfully extracted to " + outFile)
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

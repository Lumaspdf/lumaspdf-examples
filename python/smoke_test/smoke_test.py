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

# smoke_test -- port of examples\Vb6\smoke_test\smoke_test.bas
# End-to-end proof the flat LumasPdf API drives the engine: creates a PDF with
# text, a red rectangle and a bookmark.

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    pdf = L.pdfNewPDF()
    out_file = os.path.join(HERE, "smoke_out.pdf")

    if L.pdfCreateNewPDFA(pdf, out_file.encode("latin-1")) == 0:
        print("CreateNewPDF failed")
        L.pdfDeletePDF(pdf)
        return

    L.pdfSetDocInfoA(pdf, L.diTitle, b"LumasPdf example-mirror smoke test")
    L.pdfAppend(pdf)
    L.pdfSetFontA(pdf, b"Arial", L.fsRegular, 24.0, 1, L.cp1252)
    L.pdfWriteTextA(pdf, 50, 700, b"Mirrored DynaPDF examples run on LumasPdf.dll")
    L.pdfSetFillColor(pdf, 255)                    # red (COLORREF, R in low byte)
    L.pdfRectangle(pdf, 50, 500, 200, 100, L.fmFill)
    L.pdfAddBookmarkA(pdf, b"First page", -1, 1, 0)
    L.pdfEndPage(pdf)

    if L.pdfCloseFile(pdf) == 0:
        print("CloseFile failed")
        L.pdfDeletePDF(pdf)
        return

    print("OK: " + out_file)
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

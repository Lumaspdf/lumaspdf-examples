# ============================================================================
#  hello_world -- Python (ctypes) port of examples\Vb6\hello_world\hello_world.bas
#  Writes out.pdf with a single centered line of text.
# ============================================================================
import os
import sys
import datetime
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


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return -1  # break processing on error


def main():
    cr = chr(13)
    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    if L.pdfCreateNewPDFA(pdf, b"") == 0:  # output file opened later
        L.pdfDeletePDF(pdf)
        return
    L.pdfSetDocInfoA(pdf, L.diCreator, b"Delphi Example project")
    L.pdfSetDocInfoA(pdf, L.diTitle, b"My first PDF output")

    L.pdfAppend(pdf)
    L.pdfSetFontA(pdf, b"Arial", L.fsItalic, 30.0, 1, L.cp1252)
    txt = ("My first PDF output..." + cr + cr + str(datetime.datetime.now()))
    L.pdfWriteFTextA(pdf, L.taCenter, txt.encode("latin-1", "replace"))
    L.pdfEndPage(pdf)

    out_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out.pdf")
    if L.pdfHaveOpenDoc(pdf) != 0:
        L.pdfSetOnErrorProc(pdf, 0, L.TErrorProc(0))
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
        L.pdfSetOnErrorProc(pdf, 0, err_proc)
    if L.pdfCloseFile(pdf) != 0:
        print("OK: " + out_file)

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

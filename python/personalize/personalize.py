# ============================================================================
#  personalize -- Python (ctypes) port of examples\Vb6\personalize\personalize.bas
#  Imports a tax form, fills in the fields, adds a web link, writes out.pdf.
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

HERE = os.path.dirname(os.path.abspath(__file__))


def rgb(r, g, b):
    return r | (g << 8) | (b << 16)


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    if errmsg:
        print(errmsg.decode("latin-1", "replace"))
    return -1  # break processing on error


def a(s):
    return s.encode("latin-1", "replace")


def main():
    pdf = L.pdfNewPDF()
    L.pdfCreateNewPDFA(pdf, b"")  # output file opened later

    L.pdfSetViewerPreferences(pdf, L.vpDisplayDocTitle, L.avNone)
    L.pdfSetImportFlags(pdf, L.ifImportAll | L.ifImportAsPage)
    taxform = os.path.join(HERE, "taxform.pdf")
    if L.pdfOpenImportFileA(pdf, taxform.encode("latin-1"), L.ptOpen, b"") < 0:
        L.pdfDeletePDF(pdf)
        return
    L.pdfImportPDFFile(pdf, 1, 1.0, 1.0)

    L.pdfEditPage(pdf, 1)
    L.pdfSetFontA(pdf, b"Courier", L.fsBold, 14.0, 0, L.cp1252)
    L.pdfWriteTextA(pdf, 72.5, 748.5, a("X"))
    L.pdfWriteTextA(pdf, 74.0, 701.0, a("Musterstadt"))
    L.pdfWriteTextA(pdf, 74.0, 677.0, a("252/1062/3323"))
    L.pdfBeginContinueText(pdf, 74.0, 628.0)
    L.pdfSetLeading(pdf, 24.0)
    L.pdfSetCharacterSpacing(pdf, 5.8)
    L.pdfAddContinueTextA(pdf, a("Mustermann"))
    L.pdfAddContinueTextA(pdf, a("Hermann"))
    L.pdfAddContinueTextA(pdf, a("22021963keineKaufmann"))
    L.pdfAddContinueTextA(pdf, a("Musterstra" + chr(223) + "e 145"))  # 223 = sharp s in cp1252
    L.pdfAddContinueTextA(pdf, a("12345Musterstadt"))
    L.pdfSetCharacterSpacing(pdf, 0.0)
    L.pdfSetFontA(pdf, b"Courier", L.fsBold, 10.0, 0, L.cp1252)
    L.pdfSetLeading(pdf, 48.0)
    L.pdfAddContinueTextA(pdf, a("04.05.1994"))
    L.pdfSetFontA(pdf, b"Courier", L.fsBold, 14.0, 0, L.cp1252)
    L.pdfSetCharacterSpacing(pdf, 5.8)
    L.pdfAddContinueTextA(pdf, a("Sabine"))
    L.pdfSetLeading(pdf, 47.5)
    L.pdfAddContinueTextA(pdf, a("18121966 ev  Hausfrau"))
    L.pdfEndContinueText(pdf)
    L.pdfWriteTextA(pdf, 72.5, 365.0, a("X"))
    L.pdfWriteTextA(pdf, 396.0, 365.0, a("X"))
    L.pdfBeginContinueText(pdf, 74.0, 316.0)
    L.pdfSetLeading(pdf, 24.0)
    L.pdfAddContinueTextA(pdf, a("2346256780     76834560"))
    L.pdfAddContinueTextA(pdf, a("Sparkasse Musterstadt"))
    L.pdfEndContinueText(pdf)
    L.pdfWriteTextA(pdf, 72.5, 269.0, a("X"))
    L.pdfSetCharacterSpacing(pdf, 0.0)
    L.pdfSetFontA(pdf, b"Courier", L.fsNone, 10.0, 0, L.cp1252)
    L.pdfWriteTextA(pdf, 53.0, 48.0, a(str(datetime.datetime.now())))
    L.pdfSetFillColor(pdf, rgb(0xFF, 0x66, 0x66))
    L.pdfSetFontA(pdf, b"Helvetica", L.fsBold, 22.0, 0, L.cp1252)
    L.pdfWriteTextA(pdf, 340.0, 70.0, a("www.lumaspdf.com"))
    L.pdfSetLineWidth(pdf, 0.0)
    L.pdfSetLinkHighlightMode(pdf, L.hmPush)
    L.pdfSetAnnotFlags(pdf, L.afReadOnly)
    L.pdfWebLinkA(pdf, 340.0, 64.0, 204.0, 22.0, a("https://www.lumaspdf.com"))
    L.pdfEndPage(pdf)

    out_file = os.path.join(HERE, "out.pdf")
    if L.pdfHaveOpenDoc(pdf) != 0:
        L.pdfSetOnErrorProc(pdf, 0, L.TErrorProc(0))  # silence errors while opening output
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
        L.pdfSetOnErrorProc(pdf, 0, err_proc)
    if L.pdfCloseFile(pdf) != 0:
        print('PDF file "' + out_file + '" successfully created!')
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

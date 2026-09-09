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

# text_formatting -- Python (ctypes) port of the VB6 mirror.
# Lays out sample.txt into N columns using a page-break callback and
# writes out.pdf. The column count (form combo default) is a constant (3).

HERE = os.path.dirname(os.path.abspath(__file__))


class TOutRect:
    PosX = 0.0
    PosY = 0.0
    Width_ = 0.0
    Height_ = 0.0
    Distance = 0.0
    Column = 0
    ColCount = 0


gRect = TOutRect()
gPDF = 0


def _err(data, code, msg, typ):
    if msg:
        print(msg.decode('latin-1', 'replace'))
    return -1  # we break processing if an error occurred


_ecb = L.TErrorProc(_err)  # keep global ref


def _on_page_break(data, lastPosX, lastPosY, pageBreak):
    L.pdfSetPageCoords(gPDF, L.pcTopDown)
    gRect.Column += 1
    if (pageBreak == 0) and (gRect.Column < gRect.ColCount):
        x = gRect.PosX + gRect.Column * (gRect.Width_ + gRect.Distance)
        L.pdfSetTextRect(gPDF, x, gRect.PosY, gRect.Width_, gRect.Height_)
        return 0
    else:
        L.pdfEndPage(gPDF)
        L.pdfAppend(gPDF)
        L.pdfSetTextRect(gPDF, gRect.PosX, gRect.PosY, gRect.Width_, gRect.Height_)
        gRect.Column = 0
        return 0


_pbcb = L.TOnPageBreakProc(_on_page_break)  # keep global ref


def main():
    global gPDF

    fText = b""
    try:
        with open(os.path.join(HERE, "sample.txt"), "rb") as fh:
            fText = fh.read()  # sample.txt is an ANSI text file
    except OSError:
        pass

    gPDF = L.pdfNewPDF()
    L.pdfSetOnErrorProc(gPDF, 0, _ecb)
    L.pdfSetDocInfoA(gPDF, L.diCreator, b"C++ test app")
    L.pdfSetDocInfoA(gPDF, L.diSubject, b"Multi-column text")
    L.pdfSetDocInfoA(gPDF, L.diTitle, b"Multi-column text")
    L.pdfSetPageCoords(gPDF, L.pcTopDown)

    if L.pdfCreateNewPDFA(gPDF, b"") == 0:
        L.pdfDeletePDF(gPDF)
        return

    gRect.ColCount = 3
    gRect.Column = 0
    gRect.Distance = 10.0
    gRect.PosX = 50.0
    gRect.PosY = 50.0
    gRect.Height_ = L.pdfGetPageHeight(gPDF) - 100.0
    gRect.Width_ = (L.pdfGetPageWidth(gPDF) - 100.0 - (gRect.ColCount - 1) * gRect.Distance) / gRect.ColCount

    L.pdfSetOnPageBreakProc(gPDF, 0, _pbcb)
    L.pdfAppend(gPDF)
    L.pdfSetTextRect(gPDF, gRect.PosX, gRect.PosY, gRect.Width_, gRect.Height_)
    L.pdfSetFontA(gPDF, b"Arial", L.fsNone, 9.0, 1, L.cp1252)
    L.pdfWriteFTextA(gPDF, L.taJustify, fText)

    L.pdfEndPage(gPDF)
    outFile = os.path.join(HERE, "out.pdf")
    if L.pdfHaveOpenDoc(gPDF) != 0:
        L.pdfSetOnErrorProc(gPDF, 0, ctypes.cast(None, L.TErrorProc))
        if L.pdfOpenOutputFileA(gPDF, outFile.encode('latin-1')) == 0:
            L.pdfDeletePDF(gPDF)
            return
        L.pdfSetOnErrorProc(gPDF, 0, _ecb)
    if L.pdfCloseFile(gPDF) != 0:
        print("OK: " + outFile)

    L.pdfDeletePDF(gPDF)


if __name__ == "__main__":
    main()

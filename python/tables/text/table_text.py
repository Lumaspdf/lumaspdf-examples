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

# table_text -- port of examples\Vb6\tables\text\table_text.bas
# Builds a 3x3 table demonstrating cell text alignment, draws it, then redraws
# it with a 90-degree cell orientation. Uses the flat tbl* exports.

HERE = os.path.dirname(os.path.abspath(__file__))

ERRPROC = ctypes.WINFUNCTYPE(ctypes.c_int32, ctypes.c_void_p, ctypes.c_int32,
                             ctypes.c_char_p, ctypes.c_int32)


def _err(data, code, msg, typ):
    if msg:
        print(msg.decode("latin-1", "replace"))
    return 0


_cb = ERRPROC(_err)


def _ptr_to_ansi(p):
    if not p:
        return ""
    return ctypes.cast(p, ctypes.c_char_p).value.decode("latin-1", "replace")


def main():
    import time
    t0 = time.perf_counter()

    pdf = L.pdfNewPDF()
    L.pdfSetOnErrorProc(pdf, 0, _cb)

    L.pdfCreateNewPDFA(pdf, b"")
    L.pdfSetPageCoords(pdf, L.pcTopDown)

    tbl = L.tblCreateTable(pdf, 3, 3, 500.0, 100.0)
    L.tblSetBoxProperty(tbl, -1, -1, L.tbpBorderWidth, 1.0, 1.0, 1.0, 1.0)
    L.tblSetFontA(tbl, -1, -1, b"Arial", L.fsRegular, 1, L.cp1252)
    L.tblSetFontA(tbl, -1, 1, b"Arial", L.fsBold, 1, L.cp1252)
    L.tblSetGridWidth(tbl, 1.0, 1.0)

    txt = b"The cell alignment can be set for text, images, and templates..."

    # -1.0 means use the default row height as specified in CreateTable().
    rowNum = L.tblAddRow(tbl, -1.0)
    L.tblSetCellTextA(tbl, rowNum, 0, L.taLeft, L.coTop, txt, len(txt))
    L.tblSetCellTextA(tbl, rowNum, 1, L.taCenter, L.coTop, txt, len(txt))
    L.tblSetCellTextA(tbl, rowNum, 2, L.taRight, L.coTop, txt, len(txt))

    rowNum = L.tblAddRow(tbl, -1.0)
    L.tblSetCellTextA(tbl, rowNum, 0, L.taLeft, L.coCenter, txt, len(txt))
    L.tblSetCellTextA(tbl, rowNum, 1, L.taCenter, L.coCenter, txt, len(txt))
    L.tblSetCellTextA(tbl, rowNum, 2, L.taRight, L.coCenter, txt, len(txt))

    rowNum = L.tblAddRow(tbl, -1.0)
    L.tblSetCellTextA(tbl, rowNum, 0, L.taLeft, L.coBottom, txt, len(txt))
    L.tblSetCellTextA(tbl, rowNum, 1, L.taCenter, L.coBottom, txt, len(txt))
    L.tblSetCellTextA(tbl, rowNum, 2, L.taRight, L.coBottom, txt, len(txt))

    # Draw the table now
    L.pdfAppend(pdf)
    L.tblDrawTable(tbl, 50.0, 50.0, 742.0)
    while L.tblHaveMore(tbl) != 0:
        L.pdfEndPage(pdf)
        L.pdfAppend(pdf)
        L.tblDrawTable(tbl, 50.0, 50.0, 742.0)
    L.pdfEndPage(pdf)

    # Change the cell orientation to see what happens...
    L.tblSetCellOrientation(tbl, -1, -1, 90)
    L.pdfAppend(pdf)
    L.pdfSetFontA(pdf, b"Arial", L.fsRegular, 12.0, 1, L.cp1252)
    L.pdfWriteTextA(pdf, 50.0, 50.0,
                    b"The same table but the cell orientation was changed to 90 degrees.")

    L.tblDrawTable(tbl, 50.0, 65.0, 742.0)
    while L.tblHaveMore(tbl) != 0:
        L.pdfEndPage(pdf)
        L.pdfAppend(pdf)
        L.tblDrawTable(tbl, 50.0, 50.0, 737.0)
    L.pdfEndPage(pdf)

    _th = ctypes.c_void_p(tbl)
    L.tblDeleteTable(ctypes.byref(_th))    # frees the table

    # A table stores errors and warnings in the error log
    err = L.TPDFError()
    err.StructSize = ctypes.sizeof(err)
    for i in range(L.pdfGetErrLogMessageCount(pdf)):
        L.pdfGetErrLogMessage(pdf, i, ctypes.byref(err))
        print(_ptr_to_ansi(err.Msg))

    # No fatal error occurred?
    if L.pdfHaveOpenDoc(pdf) != 0:
        out_file = os.path.join(HERE, "out.pdf")
        if L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")) == 0:
            L.pdfDeletePDF(pdf)
            return
        if L.pdfCloseFile(pdf) != 0:
            print("Processing time: %d ms" % int((time.perf_counter() - t0) * 1000))

    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

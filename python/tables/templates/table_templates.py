import sys, os, ctypes
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

# table_templates -- port of examples\Vb6\tables\templates\table_templates.bas
# Imports every page of sample_multipage.pdf as a template and lays them out two
# per row in a table (tfScaleToRect), then draws the table across output pages.

HERE = os.path.dirname(os.path.abspath(__file__))
HELP_PDF = _here('sample_multipage.pdf')

# Table flag missing from the shared wrapper (from LumasPdf.pas):
tfScaleToRect = 0x8

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
    L.pdfSetImportFlags2(pdf, L.if2UseProxy)    # reduce memory usage

    L.pdfOpenImportFileA(pdf, HELP_PDF.encode("latin-1"), L.ptOpen, b"")

    page_count = L.pdfGetInPageCount(pdf)
    if page_count < 1:
        print("Help file not found!")
        L.pdfDeletePDF(pdf)
        return

    tbl = L.tblCreateTable(pdf, page_count // 4 + 1, 2, 512.12, 0.0)
    L.tblSetBoxProperty(tbl, -1, -1, L.tbpBorderWidth, 1.0, 1.0, 1.0, 1.0)
    L.tblSetBoxProperty(tbl, -1, -1, L.tbpCellPadding, 5.0, 5.0, 5.0, 5.0)
    L.tblSetGridWidth(tbl, 1.0, 1.0)
    L.tblSetFlags(tbl, -1, -1, tfScaleToRect)

    L.pdfSetPageFormat(pdf, L.pfUS_Letter)

    rowNum = 0
    for i in range(1, page_count + 1):
        tmpl = L.pdfImportPage(pdf, i)
        if (i & 1) != 0:
            rowNum = L.tblAddRow(tbl, 335.0)
        L.tblSetCellTemplate(tbl, rowNum, (i - 1) & 1, 1, L.coCenter, L.coCenter, tmpl, 0.0, 0.0)

    # Draw the table now
    L.pdfAppend(pdf)
    L.tblDrawTable(tbl, 50.0, 50.0, 742.0)
    while L.tblHaveMore(tbl) != 0:
        L.pdfEndPage(pdf)
        L.pdfAppend(pdf)
        L.tblDrawTable(tbl, 50.0, 50.0, 742.0)
    L.pdfEndPage(pdf)

    _th = ctypes.c_void_p(tbl)
    L.tblDeleteTable(ctypes.byref(_th))

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

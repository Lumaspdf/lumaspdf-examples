import sys, os, ctypes, glob
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

# table_images -- port of examples\Vb6\tables\images\table_images.bas
# Lays out every JPEG in test_files\images into a 4-column table (native image
# color space), draws it, then redraws with tfScaleToRect.

HERE = os.path.dirname(os.path.abspath(__file__))
IMG_DIR = r"test_files\images"

# Table flags missing from the shared wrapper (from LumasPdf.pas):
tfScaleToRect = 0x8
tfUseImageCS = 0x10

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
    L.pdfSetResolution(pdf, 300)

    tbl = L.tblCreateTable(pdf, 100, 4, 500.0, 125.0)
    L.tblSetBoxProperty(tbl, -1, -1, L.tbpBorderWidth, 1.0, 1.0, 1.0, 1.0)
    L.tblSetBoxProperty(tbl, -1, -1, L.tbpCellPadding, 5.0, 5.0, 5.0, 5.0)
    L.tblSetGridWidth(tbl, 1.0, 1.0)
    L.tblSetFlags(tbl, -1, -1, tfUseImageCS)

    files = sorted(glob.glob(os.path.join(IMG_DIR, "*.jpg")))
    if not files:
        print("Test images not found!")
        _th0 = ctypes.c_void_p(tbl)
        L.tblDeleteTable(ctypes.byref(_th0))
        L.pdfDeletePDF(pdf)
        return

    full_size = 0
    i = 0            # column index (0..3)
    rowNum = L.tblAddRow(tbl, 125.0)
    for idx, path in enumerate(files):
        if idx > 0 and i == 4:
            rowNum = L.tblAddRow(tbl, 100.0)
            i = 0
        full_size += os.path.getsize(path)
        L.tblSetCellImageA(tbl, rowNum, i, 1, L.coCenter, L.coCenter,
                           0.0, 0.0, path.encode("latin-1"), 1)
        i += 1

    L.pdfAppend(pdf)
    L.tblDrawTable(tbl, 50.0, 50.0, 742.0)
    while L.tblHaveMore(tbl) != 0:
        L.pdfEndPage(pdf)
        if full_size > 104857600:
            L.pdfFlushPages(pdf, L.fpfDefault)
        L.pdfAppend(pdf)
        L.tblDrawTable(tbl, 50.0, 50.0, 742.0)
    L.pdfEndPage(pdf)

    # Draw the same table again but with the flag tfScaleToRect
    L.tblSetFlags(tbl, -1, -1, tfScaleToRect | tfUseImageCS)
    L.pdfAppend(pdf)

    L.pdfSetFontA(pdf, b"Arial", L.fsRegular, 12.0, 1, L.cp1252)
    L.pdfWriteTextA(pdf, 50.0, 50.0, b"The same table but the flag tfScaleToRect was set.")

    L.tblDrawTable(tbl, 50.0, 65.0, 742.0)
    while L.tblHaveMore(tbl) != 0:
        L.pdfEndPage(pdf)
        if full_size > 104857600:
            L.pdfFlushPages(pdf, L.fpfDefault)
        L.pdfAppend(pdf)
        L.tblDrawTable(tbl, 50.0, 50.0, 742.0)
    L.pdfEndPage(pdf)

    _th = ctypes.c_void_p(tbl)
    L.tblDeleteTable(ctypes.byref(_th))

    # A table stores errors and warnings in the error log
    err = L.TPDFError()
    err.StructSize = ctypes.sizeof(err)
    for k in range(L.pdfGetErrLogMessageCount(pdf)):
        L.pdfGetErrLogMessage(pdf, k, ctypes.byref(err))
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

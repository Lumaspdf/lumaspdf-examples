# ============================================================================
#  probe_test -- Python (ctypes) port of examples\Vb6\probe_test\probe_test.bas
#  Step-by-step probe of the TPDF flow (in-memory CreateNewPDF + TPDFTable).
# ============================================================================
import os
import sys
import ctypes
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


@L.TErrorProc
def err_proc(data, errcode, errmsg, errtype):
    msg = errmsg.decode("latin-1", "replace") if errmsg else ""
    print("ERR %d: %s" % (errcode, msg))
    return 0


def main():
    pdf = L.pdfNewPDF()
    print("Create ok")
    L.pdfSetOnErrorProc(pdf, 0, err_proc)
    print("CreateNewPDF('') = %d" % L.pdfCreateNewPDFA(pdf, b""))
    print("SetPageCoords = %d" % L.pdfSetPageCoords(pdf, L.pcTopDown))
    print("Append = %d" % L.pdfAppend(pdf))
    print("SetFont = %d" % L.pdfSetFontA(pdf, b"Arial", L.fsRegular, 12.0, 1, L.cp1252))
    print("WriteText = %d" % L.pdfWriteTextA(pdf, 50, 50, b"probe"))

    tbl = L.tblCreateTable(pdf, 3, 3, 500.0, 100.0)
    print("Table created")
    r = L.tblAddRow(tbl, -1.0)
    print("AddRow = %d" % r)
    # NOTE: the VB6/C originals pass ALen = -1 ("compute strlen"), but this
    # LumasPdf.dll build access-violates on -1; passing the real length works.
    cell = b"cell"
    print("SetCellText = %d" % L.tblSetCellTextA(tbl, r, 0, L.taLeft, L.coTop, cell, len(cell)))
    print("DrawTable = %f" % L.tblDrawTable(tbl, 50.0, 80.0, 700.0))
    print("HaveMore = %d" % L.tblHaveMore(tbl))
    tbl_h = ctypes.c_void_p(tbl)
    L.tblDeleteTable(ctypes.byref(tbl_h))

    print("EndPage = %d" % L.pdfEndPage(pdf))
    print("GetPageCount = %d" % L.pdfGetPageCount(pdf))
    print("HaveOpenDoc = %d" % L.pdfHaveOpenDoc(pdf))
    out_file = os.path.join(HERE, "probe_out.pdf")
    print("OpenOutputFile = %d" % L.pdfOpenOutputFileA(pdf, out_file.encode("latin-1")))
    print("CloseFile = %d" % L.pdfCloseFile(pdf))
    L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

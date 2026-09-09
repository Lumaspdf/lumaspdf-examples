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

# ===========================================================================
#  Python (ctypes) port of examples\Vb6\reporting\08_custom_provider.bas
#  Registers an in-memory data provider (4 rows x 5 typed columns) via the
#  rptRegisterProvider vtable of C callbacks.
# ===========================================================================

PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0"
RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

HERE = os.path.dirname(os.path.abspath(__file__))

# value kinds
vkNull, vkBool, vkInt, vkFloat, vkDate, vkStr = 0, 1, 2, 3, 4, 5


def trim_null(s):
    return s.split('\0')[0]


def write_text(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)


def dump_rpt_error(eng):
    info = L.TRptErrorInfoC()
    if L.rptGetLastError(eng, ctypes.byref(info)) != 0:
        if info.Code != 0:
            print("  ! rpt error %d [%s] at %s: %s" % (
                info.Code,
                trim_null(info.Module_.decode('latin-1')),
                trim_null(info.Location.decode('latin-1')),
                trim_null(info.Msg.decode('latin-1'))))


def boot_engine():
    pdf = L.pdfNewPDF()
    if not pdf:
        print("pdfNewPDF failed")
        return None, None
    L.pdfSetLicenseKey(pdf, PDF_DEMO_KEY.encode('latin-1'))
    L.rptSetRptLicenseKeyA(pdf, RPT_DEMO_KEY.encode('latin-1'))
    eng = L.rptCreateEngineA(pdf, None)
    if not eng:
        print("rptCreateEngine failed:")
        dump_rpt_error(0)
        return None, pdf
    return eng, pdf


# ---- in-memory table -------------------------------------------------------
mRowId = [1, 2, 3, 4]
mPrice = [12.5, 9.99, 0.0, 47.75]
mActive = [1, 0, 1, 1]
mHasNote = [True, True, False, True]
mNames = ["Alpha", "Beta", "Gamma", "Delta"]
mNotes = ["first", "second", "", "fourth"]
mFieldName = ["Id", "Price", "Name", "Active", "Note"]
mFieldKind = [vkInt, vkFloat, vkStr, vkBool, vkStr]

# persistent C string buffers (must outlive the render)
_name_bufs = [ctypes.create_string_buffer(n.encode('latin-1')) for n in mNames]
_note_bufs = [ctypes.create_string_buffer(n.encode('latin-1')) for n in mNotes]
# keep cursor buffers alive
_cursors = []
# keep callback objects alive
_keep = []


# ---- callback function types (match the C provider vtable ABI) -------------
PROC_OPEN = ctypes.WINFUNCTYPE(ctypes.c_int32, ctypes.c_void_p, ctypes.c_char_p,
                               ctypes.c_char_p, ctypes.c_void_p, ctypes.c_int32,
                               ctypes.POINTER(ctypes.c_void_p))
PROC_SCHEMA = ctypes.WINFUNCTYPE(ctypes.c_int32, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int32)
PROC_FETCH = ctypes.WINFUNCTYPE(ctypes.c_int32, ctypes.c_void_p)
PROC_GETVAL = ctypes.WINFUNCTYPE(ctypes.c_int32, ctypes.c_void_p, ctypes.c_int32, ctypes.c_void_p)
PROC_CLOSE = ctypes.WINFUNCTYPE(None, ctypes.c_void_p)


def my_open(user, conn, query, params, nparams, cursor_out):
    buf = ctypes.c_int32(-1)   # row index, pre-increment starts at 0
    _cursors.append(buf)
    cursor_out[0] = ctypes.cast(ctypes.pointer(buf), ctypes.c_void_p)
    return 0


def my_get_schema(cursor, fields, maxfields):
    n = 5
    if n > maxfields:
        n = maxfields
    arr = ctypes.cast(fields, ctypes.POINTER(L.TRptCFieldDef))
    for i in range(n):
        arr[i].Name = mFieldName[i].encode('latin-1')
        arr[i].Kind = mFieldKind[i]
    return n


def my_fetch(cursor):
    p = ctypes.cast(cursor, ctypes.POINTER(ctypes.c_int32))
    p[0] = p[0] + 1
    return 1 if p[0] <= 3 else 0


def my_get_val(cursor, field, v):
    r = ctypes.cast(cursor, ctypes.POINTER(ctypes.c_int32))[0]
    cv = ctypes.cast(v, ctypes.POINTER(L.TRptCValue)).contents
    cv.Kind = vkNull
    cv.B = 0
    cv.I = 0
    cv.F = 0.0
    cv.S = 0
    if field == 0:
        cv.Kind = vkInt
        cv.I = mRowId[r]
    elif field == 1:
        cv.Kind = vkFloat
        cv.F = mPrice[r]
    elif field == 2:
        cv.Kind = vkStr
        cv.S = ctypes.addressof(_name_bufs[r])
    elif field == 3:
        cv.Kind = vkBool
        cv.B = mActive[r]
    elif field == 4:
        if not mHasNote[r]:
            cv.Kind = vkNull
        else:
            cv.Kind = vkStr
            cv.S = ctypes.addressof(_note_bufs[r])
    else:
        cv.Kind = vkNull
    return 0


def my_close(cursor):
    pass


def main():
    eng, pdf = boot_engine()
    if not eng:
        return

    try:
        vt = L.TRptProviderVTable()
        cb_open = PROC_OPEN(my_open)
        cb_schema = PROC_SCHEMA(my_get_schema)
        cb_fetch = PROC_FETCH(my_fetch)
        cb_getval = PROC_GETVAL(my_get_val)
        cb_close = PROC_CLOSE(my_close)
        _keep.extend([cb_open, cb_schema, cb_fetch, cb_getval, cb_close, vt])
        vt.Open = ctypes.cast(cb_open, ctypes.c_void_p)
        vt.GetSchema = ctypes.cast(cb_schema, ctypes.c_void_p)
        vt.Fetch = ctypes.cast(cb_fetch, ctypes.c_void_p)
        vt.GetVal = ctypes.cast(cb_getval, ctypes.c_void_p)
        vt.CloseC = ctypes.cast(cb_close, ctypes.c_void_p)

        if L.rptRegisterProvider(eng, b"mydata", ctypes.byref(vt), None) == 0:
            print("register provider failed")
            dump_rpt_error(eng)
            return

        lrpt = os.path.join(HERE, "08_custom.lrpt")
        out_pdf = os.path.join(HERE, "08_custom.pdf")
        out_txt = os.path.join(HERE, "08_custom.txt")
        xml = (
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<report name="CustomProvider" tagLangVersion="1">\n'
            ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
            ' <datasources><datasource alias="d" provider="mydata" conn="" query=""/></datasources>\n'
            ' <bands>\n'
            '  <band kind="reportheader" name="rh" height="12">\n'
            '   <text name="t" x="0" y="0" w="180" h="8" fontSize="16" hAlign="center" wordWrap="0">Custom Provider - typed rows</text>\n'
            '  </band>\n'
            '  <band kind="pageheader" name="ph" height="7">\n'
            '   <text name="h1" x="0"   y="0" w="20" h="5" fontSize="9" bold="1" wordWrap="0">Id</text>\n'
            '   <text name="h2" x="22"  y="0" w="40" h="5" fontSize="9" bold="1" wordWrap="0">Name</text>\n'
            '   <text name="h3" x="64"  y="0" w="30" h="5" fontSize="9" bold="1" hAlign="right" wordWrap="0">Price</text>\n'
            '   <text name="h4" x="98"  y="0" w="24" h="5" fontSize="9" bold="1" wordWrap="0">Active</text>\n'
            '   <text name="h5" x="126" y="0" w="50" h="5" fontSize="9" bold="1" wordWrap="0">Note</text>\n'
            '  </band>\n'
            '  <band kind="detail" name="det" height="6" data="d">\n'
            '   <text name="c1" x="0"   y="0" w="20" h="5" fontSize="9" wordWrap="0">{{Id}}</text>\n'
            '   <text name="c2" x="22"  y="0" w="40" h="5" fontSize="9" wordWrap="0">{{Name}}</text>\n'
            '   <text name="c3" x="64"  y="0" w="30" h="5" fontSize="9" hAlign="right" wordWrap="0">{{expr: FORMATNUM(\'#,##0.00\', Price) }}</text>\n'
            '   <text name="c4" x="98"  y="0" w="24" h="5" fontSize="9" wordWrap="0">{{expr: CSTR(Active) }}</text>\n'
            '   <text name="c5" x="126" y="0" w="50" h="5" fontSize="9" wordWrap="0">{{expr: IFNULL(Note, \'(none)\') }}</text>\n'
            '  </band>\n'
            ' </bands>\n'
            '</report>\n'
        )
        write_text(lrpt, xml)

        job = L.rptOpenReportA(eng, lrpt.encode('latin-1'))
        if not job:
            print("open failed")
            dump_rpt_error(eng)
            return
        if L.rptRender(job) == 0:
            print("render failed")
            dump_rpt_error(eng)
            L.rptCloseReport(job)
            return
        print("rendered %d page(s) from the custom provider" % L.rptGetPageCount(job))
        L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1'))
        L.rptExportA(job, L.RPT_EXP_TEXT, out_txt.encode('latin-1'))
        print("wrote %s  +  %s" % (out_pdf, out_txt))
        L.rptCloseReport(job)
    finally:
        L.rptDeleteEngine(eng)
        L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

# ============================================================================
#  LumasReport example 13 -- Custom function + custom exporter (Python port)
#  NO external plugin DLL. Instead of rptLoadPlugin, this registers the
#  behaviour DIRECTLY from Python through the public C ABI:
#    * rptRegisterFunction -- the expression function PlugDouble(x) = x*2,
#      invoked via {{expr: PlugDouble(21)}} / {{expr: PlugDouble(2.5)}}.
#    * rptRegisterExporter -- a custom export target (id 100) that writes a
#      marker file when driven through the normal rptExport dispatch.
#  Both are supplied as stdcall ctypes callbacks (ctypes.WINFUNCTYPE); the
#  callback objects are kept in module-level vars so they are not GC'd while
#  the engine still holds their function pointers.
# ============================================================================
import sys, os, ctypes
from ctypes import c_int, c_int32, c_int64, c_double, c_void_p, c_char_p, cast, WINFUNCTYPE
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

PDF_DEMO_KEY = b"LUMAS-LumasReportExamples-DD5D40E0"
RPT_DEMO_KEY = b"LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

CUSTOM_TARGET = 100
MARKER = "PLUGIN:OK -- custom exporter via rptRegisterExporter (no external plugin DLL)"

# TRptCValue layout (pack=1): Kind:int32@0  B:int32@4  I:int64@8  F:double@16  S:ptr@24
CV_KIND, CV_I, CV_F = 0, 8, 16
CV_KIND_INT, CV_KIND_FLOAT = 2, 3

# --- ctypes callback signatures (stdcall) ----------------------------------
CFUNC_FN = WINFUNCTYPE(c_int, c_void_p, c_void_p, c_int, c_void_p)
CFUNC_EXP = WINFUNCTYPE(c_int, c_void_p, c_void_p, c_char_p)


def _plug_double(user, args, nargs, resultv):
    # PlugDouble(x) = x*2 -- read arg 0 by Kind, double it, echo Kind back.
    kind = c_int32.from_address(args + CV_KIND).value
    if kind == CV_KIND_INT:
        i = c_int64.from_address(args + CV_I).value
        c_int32.from_address(resultv + CV_KIND).value = CV_KIND_INT
        c_int64.from_address(resultv + CV_I).value = i * 2
    elif kind == CV_KIND_FLOAT:
        f = c_double.from_address(args + CV_F).value
        c_int32.from_address(resultv + CV_KIND).value = CV_KIND_FLOAT
        c_double.from_address(resultv + CV_F).value = f * 2.0
    return 0


def _plug_export(user, job, path):
    # Custom export target 100 -- write a marker file at the requested path.
    dest = path.decode('latin-1') if path else os.path.join(HERE, "13_custom.out")
    with open(dest, "wb") as f:
        f.write(MARKER.encode('latin-1'))
    return 0


# keep the callback thunks alive for the engine's lifetime (module scope)
FN_CB = CFUNC_FN(_plug_double)
EXP_CB = CFUNC_EXP(_plug_export)


def build_xml():
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="Plugin" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="rh" height="24">\n'
        '   <text name="p1" x="0" y="0"  w="180" h="8" fontSize="16">PlugDouble(21) = {{expr: PlugDouble(21) }}</text>\n'
        '   <text name="p2" x="0" y="10" w="180" h="8" fontSize="12">PlugDouble(2.5) = {{expr: PlugDouble(2.5) }}</text>\n'
        '  </band>\n'
        ' </bands>\n'
        '</report>\n'
    )


def main():
    pdf, eng = boot_engine()
    if not eng:
        return
    try:
        # Register BEFORE opening the report so the expression compiler resolves
        # PlugDouble and the exporter dispatch knows target 100.
        if L.rptRegisterFunction(eng, b"PlugDouble", 1, 1, cast(FN_CB, c_void_p), None) == 0:
            print("rptRegisterFunction failed"); dump_err(eng); return
        if L.rptRegisterExporter(eng, CUSTOM_TARGET, cast(EXP_CB, c_void_p), None) == 0:
            print("rptRegisterExporter failed"); dump_err(eng); return
        print("registered custom function PlugDouble/1 + custom exporter target 100 (plugin-free, direct ctypes callbacks)")

        lrpt = os.path.join(HERE, "13_plugin.lrpt")
        out_pdf = os.path.join(HERE, "13_plugin.pdf")
        out_txt = os.path.join(HERE, "13_plugin.txt")
        out_custom = os.path.join(HERE, "13_custom.out")
        write_text(lrpt, build_xml())

        job = L.rptOpenReportA(eng, lrpt.encode('latin-1'))
        if not job:
            print("open failed"); dump_err(eng); return
        try:
            if L.rptRender(job) == 0:
                print("render failed"); dump_err(eng); return
            if L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1')) == 0:
                print("export PDF failed"); dump_err(eng); return
            if L.rptExportA(job, L.RPT_EXP_TEXT, out_txt.encode('latin-1')) == 0:
                print("export TEXT failed"); dump_err(eng); return
            # Drive OUR custom exporter through the normal rptExport dispatch.
            if L.rptExportA(job, CUSTOM_TARGET, out_custom.encode('latin-1')) == 0:
                print("custom export failed"); dump_err(eng); return
            print("wrote " + out_pdf + " + " + out_txt + " + " + out_custom)
            print("OK")
        finally:
            L.rptCloseReport(job)
    finally:
        L.rptDeleteEngine(eng)
        L.pdfDeletePDF(pdf)


# --- shared boilerplate (mirror of _shared.inc) -----------------------------

def boot_engine():
    pdf = L.pdfNewPDF()
    if not pdf:
        print("pdfNewPDF failed"); return None, None
    L.pdfSetLicenseKey(pdf, PDF_DEMO_KEY)
    L.rptSetRptLicenseKeyA(pdf, RPT_DEMO_KEY)
    eng = L.rptCreateEngineA(pdf, None)
    if not eng:
        print("rptCreateEngine failed"); return pdf, None
    return pdf, eng


def write_text(path, content):
    with open(path, "wb") as f:
        f.write(content.encode('latin-1'))


def dump_err(eng):
    info = L.TRptErrorInfoC()
    if L.rptGetLastError(eng, ctypes.byref(info)) != 0:
        if info.Code != 0:
            print("  ! rpt error %d [%s] at %s: %s" % (
                info.Code, info.Module_.decode('latin-1', 'replace'),
                info.Location.decode('latin-1', 'replace'),
                info.Msg.decode('latin-1', 'replace')))


if __name__ == "__main__":
    main()

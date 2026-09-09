# ============================================================================
#  LumasReport example 12 -- Custom expression function (Python port)
#  Registers a Python-implemented expression function on the engine via
#  rptRegisterFunction(Eng, "GREET", MinArgs, MaxArgs, callback, User). The
#  callback matches the engine's C user-function ABI (stdcall):
#     int Fn(User, Args: PRptCValue, NArgs, ResultV: PRptCValue)  # 0 = ok
#  TRptCValue = { Kind:int32; B:int32; I:int64; F:double; S:void* }, Kind
#  ordinals vkNull=0 vkBool=1 vkInt=2 vkFloat=3 vkDate=4 vkStr=5. A string result
#  must stay valid until the next call, so we keep it in a module-level buffer.
#  Invoked from the report via {{expr: GREET('World')}}.
# ============================================================================
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

HERE = os.path.dirname(os.path.abspath(__file__))

PDF_DEMO_KEY = b"LUMAS-LumasReportExamples-DD5D40E0"
RPT_DEMO_KEY = b"LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

VK_INT = 2
VK_STR = 5

# C user-function ABI (stdcall on Win32/Win64): int Fn(user, args, nargs, result)
RPT_USERFN = ctypes.WINFUNCTYPE(ctypes.c_int32, ctypes.c_void_p, ctypes.c_void_p,
                                ctypes.c_int32, ctypes.c_void_p)

# Backing store for the string handed back to the engine. Must outlive the
# callback return (engine copies it immediately on the way out).
_g_result = None


def _greet(user, args, nargs, resultv):
    global _g_result
    if nargs != 1 or not args or not resultv:
        return -1
    argv = ctypes.cast(args, ctypes.POINTER(L.TRptCValue))
    a0 = argv[0]
    if a0.Kind == VK_STR:
        arg_str = ctypes.cast(a0.S, ctypes.c_char_p).value.decode('latin-1') if a0.S else ""
    elif a0.Kind == VK_INT:
        arg_str = str(a0.I)
    else:
        return -2
    _g_result = ctypes.create_string_buffer(("Hello, " + arg_str + "!").encode('latin-1'))
    res = ctypes.cast(resultv, ctypes.POINTER(L.TRptCValue))
    res[0].Kind = VK_STR
    res[0].S = ctypes.cast(_g_result, ctypes.c_void_p)
    return 0


# Keep a global ref to the callback so it is not garbage-collected.
_greet_cb = RPT_USERFN(_greet)


def build_xml():
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="CustomFn" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="rh" height="24">\n'
        '   <text name="g1" x="0" y="0"  w="180" h="8" fontSize="16">{{expr: GREET(\'World\') }}</text>\n'
        '   <text name="g2" x="0" y="10" w="180" h="8" fontSize="12">{{expr: GREET(\'LumasReport\') }}</text>\n'
        '  </band>\n'
        ' </bands>\n'
        '</report>\n'
    )


def main():
    pdf, eng = boot_engine()
    if not eng:
        return
    try:
        # Register BEFORE opening/rendering so the compiler resolves GREET.
        if L.rptRegisterFunction(eng, b"GREET", 1, 1,
                                 ctypes.cast(_greet_cb, ctypes.c_void_p), None) == 0:
            print("rptRegisterFunction failed"); dump_err(eng); return
        print("registered custom function GREET/1")

        lrpt = os.path.join(HERE, "12_custom_function.lrpt")
        out_pdf = os.path.join(HERE, "12_custom_function.pdf")
        out_txt = os.path.join(HERE, "12_custom_function.txt")
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
            print("wrote " + out_pdf)
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

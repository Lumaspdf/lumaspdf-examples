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
#  Python (ctypes) port of examples\Vb6\reporting\01_hello_report.bas
#  LumasReport (rpt*) minimal engine -> render -> PDF flow.
# ===========================================================================

PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0"
RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

HERE = os.path.dirname(os.path.abspath(__file__))


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


def main():
    mj = ctypes.c_int32()
    mn = ctypes.c_int32()
    pt = ctypes.c_int32()
    L.rptGetVersion(ctypes.byref(mj), ctypes.byref(mn), ctypes.byref(pt))
    print("LumasReport v%d.%d.%d" % (mj.value, mn.value, pt.value))

    eng, pdf = boot_engine()
    if not eng:
        return

    lrpt = os.path.join(HERE, "01_hello.lrpt")
    out_pdf = os.path.join(HERE, "01_hello.pdf")

    xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="Hello" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="rh" height="20">\n'
        '   <text name="title" x="0" y="0" w="180" h="10" fontSize="20" hAlign="center">Hello, LumasReport!</text>\n'
        '   <text name="sub"   x="0" y="12" w="180" h="6" fontSize="10" hAlign="center">The minimal engine -&gt; render -&gt; PDF flow.</text>\n'
        '  </band>\n'
        ' </bands>\n'
        '</report>\n'
    )
    write_text(lrpt, xml)

    try:
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
        print("rendered %d page(s)" % L.rptGetPageCount(job))
        if L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1')) == 0:
            print("export failed")
            dump_rpt_error(eng)
            L.rptCloseReport(job)
            return
        print("wrote " + out_pdf)
        L.rptCloseReport(job)
    finally:
        L.rptDeleteEngine(eng)
        L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

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
#  Python (ctypes) port of examples\Vb6\reporting\02_license_and_errors.bas
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


def features_to_str(f):
    r = ""
    if f & L.RPT_FEAT_CORE:
        r += "CORE "
    if f & L.RPT_FEAT_EXPORT_PDF:
        r += "PDF "
    if f & L.RPT_FEAT_EXPORT_WEB:
        r += "WEB "
    if f & L.RPT_FEAT_EXPORT_DATA:
        r += "DATA "
    if f & L.RPT_FEAT_PREVIEW:
        r += "PREVIEW "
    if f & L.RPT_FEAT_PRINT:
        r += "PRINT "
    if f & L.RPT_FEAT_PLUGINS:
        r += "PLUGINS "
    return r.strip()


def last_error_code(eng):
    info = L.TRptErrorInfoC()
    if L.rptGetLastError(eng, ctypes.byref(info)) != 0:
        return info.Code
    return 0


def show_error(tag, eng):
    info = L.TRptErrorInfoC()
    if L.rptGetLastError(eng, ctypes.byref(info)) != 0 and info.Code != 0:
        print("  %s -> code %d  module=%s  location=%s  msg=%s" % (
            tag, info.Code,
            trim_null(info.Module_.decode('latin-1')),
            trim_null(info.Location.decode('latin-1')),
            trim_null(info.Msg.decode('latin-1'))))
    else:
        print("  %s -> (no structured error reported)" % tag)


def main():
    eng, pdf = boot_engine()
    if not eng:
        return

    good_lrpt = os.path.join(HERE, "02_good.lrpt")
    bad_lrpt = os.path.join(HERE, "02_bad.lrpt")
    out_pdf = os.path.join(HERE, "02_out.pdf")

    try:
        print("== License info ==")
        info = L.TRptLicenseInfoC()
        info.StructSize = ctypes.sizeof(info)
        if L.rptGetLicenseInfo(eng, ctypes.byref(info)) != 0:
            print("  Edition  : %d" % info.Edition)
            print("  Features : $%08X (%s)" % (info.Features, features_to_str(info.Features)))
            print("  LicClass : %d" % info.LicClass)
            print("  LockClass: %d" % info.LockClass)
            if info.Expiry == 0:
                print("  Expiry   : 0 (perpetual / unbound)")
            else:
                print("  Expiry   : %d" % info.Expiry)
            print("  Customer : %s" % trim_null(info.Customer.decode('latin-1')))
        else:
            print("  rptGetLicenseInfo failed")
            dump_rpt_error(eng)

        print("== Deliberate errors ==")

        write_text(bad_lrpt, "this is not a report at all\n")
        job = L.rptOpenReportA(eng, bad_lrpt.encode('latin-1'))
        if not job:
            show_error("open(not-XML .lrpt)", eng)
        else:
            print("  open(not-XML .lrpt) -> unexpectedly succeeded")
            L.rptCloseReport(job)

        write_text(bad_lrpt, "<notreport><oops/></notreport>\n")
        job = L.rptOpenReportA(eng, bad_lrpt.encode('latin-1'))
        if not job:
            show_error("open(wrong-root .lrpt)", eng)
        else:
            print("  open(wrong-root .lrpt) -> unexpectedly succeeded")
            L.rptCloseReport(job)

        prev_code = last_error_code(eng)
        if L.rptRender(0) != 0:
            print("  rptRender(nil) -> unexpectedly succeeded")
        elif last_error_code(eng) == prev_code:
            print("  rptRender(nil) -> returned False; no new engine error (last code still %d)" % prev_code)
        else:
            show_error("rptRender(nil)", eng)

        prev_code = last_error_code(eng)
        if L.rptExportA(0, L.RPT_EXP_PDF, out_pdf.encode('latin-1')) != 0:
            print("  rptExportA(nil) -> unexpectedly succeeded")
        elif last_error_code(eng) == prev_code:
            print("  rptExportA(nil) -> returned False; no new engine error (last code still %d)" % prev_code)
        else:
            show_error("rptExportA(nil)", eng)

        print("== Valid render ==")
        xml = (
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<report name="LicDemo" tagLangVersion="1">\n'
            ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
            ' <bands>\n'
            '  <band kind="reportheader" name="rh" height="16">\n'
            '   <text name="t" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center">License &amp; error demo</text>\n'
            '  </band>\n'
            ' </bands>\n'
            '</report>\n'
        )
        write_text(good_lrpt, xml)
        job = L.rptOpenReportA(eng, good_lrpt.encode('latin-1'))
        if not job:
            print("  open failed")
            dump_rpt_error(eng)
            return
        if L.rptRender(job) == 0:
            print("  render failed")
            dump_rpt_error(eng)
            L.rptCloseReport(job)
            return
        print("  rendered %d page(s)" % L.rptGetPageCount(job))
        if L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1')) == 0:
            print("  export failed")
            dump_rpt_error(eng)
            L.rptCloseReport(job)
            return
        print("  wrote " + out_pdf)
        L.rptCloseReport(job)
    finally:
        L.rptDeleteEngine(eng)
        L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

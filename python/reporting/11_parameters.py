# ============================================================================
#  LumasReport example 11 -- Report parameters  (Python port of 11_parameters.bas)
#  Declares <params> in the .lrpt and drives them from Python at JOB level via
#  rptSetParamStr / rptSetParamNum / rptSetParamInt (AFTER rptOpenReport, BEFORE
#  rptRender). The whole report is rendered TWICE with different parameter values.
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


def build_xml():
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="Params" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
        ' <params>\n'
        '  <param name="Customer" default="ACME (default)"/>\n'
        '  <param name="UnitPrice" default="0"/>\n'
        '  <param name="Qty" default="0"/>\n'
        ' </params>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="rh" height="30">\n'
        '   <text name="title" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center">Invoice for {{var:Customer}}</text>\n'
        '   <text name="line1" x="0" y="14" w="180" h="6" fontSize="11">Unit price: {{var:UnitPrice}}   Quantity: {{var:Qty}}</text>\n'
        '   <text name="line2" x="0" y="22" w="180" h="6" fontSize="11">TOTAL = {{expr: UnitPrice * Qty}}</text>\n'
        '  </band>\n'
        ' </bands>\n'
        '</report>\n'
    )


def run_once(eng, lrpt, out_pdf, out_txt, customer, unit_price, qty):
    job = L.rptOpenReportA(eng, lrpt.encode('latin-1'))
    if not job:
        print("  open failed"); dump_err(eng); return False
    try:
        if L.rptSetParamStr(job, b"Customer", customer.encode('latin-1')) == 0:
            print("  SetParamStr failed"); dump_err(eng); return False
        if L.rptSetParamNum(job, b"UnitPrice", unit_price) == 0:
            print("  SetParamNum failed"); dump_err(eng); return False
        if L.rptSetParamInt(job, b"Qty", qty) == 0:
            print("  SetParamInt failed"); dump_err(eng); return False
        if L.rptRender(job) == 0:
            print("  render failed"); dump_err(eng); return False
        if L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1')) == 0:
            print("  export PDF failed"); dump_err(eng); return False
        if L.rptExportA(job, L.RPT_EXP_TEXT, out_txt.encode('latin-1')) == 0:
            print("  export TEXT failed"); dump_err(eng); return False
        print('  wrote %s  (Customer="%s" UnitPrice=%s Qty=%s TOTAL=%s)'
              % (out_pdf, customer, unit_price, qty, unit_price * qty))
        return True
    finally:
        L.rptCloseReport(job)


def main():
    pdf, eng = boot_engine()
    if not eng:
        return
    try:
        lrpt = os.path.join(HERE, "11_parameters.lrpt")
        write_text(lrpt, build_xml())

        print("Run #1:")
        if not run_once(eng, lrpt, os.path.join(HERE, "11_run1.pdf"),
                        os.path.join(HERE, "11_run1.txt"), "Globex Corporation", 12.5, 4):
            return
        print("Run #2:")
        if not run_once(eng, lrpt, os.path.join(HERE, "11_run2.pdf"),
                        os.path.join(HERE, "11_run2.txt"), "Initech LLC", 9.99, 10):
            return
        print("OK")
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

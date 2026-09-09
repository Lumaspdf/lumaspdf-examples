# ============================================================================
#  LumasReport example 14 -- In-memory open + headless print (Python port)
#    1. The .lrpt does NOT have to live on disk: the markup is built in code and
#       handed straight to the engine with rptOpenReportMem(Eng, ptr, len).
#    2. A report can be sent to a physical printer head-less via rptPrintA. We
#       drive "Microsoft Print to PDF" with an absolute OutputFile (no dialog).
#       If the printer is not installed the call fails softly.
#  NOTE: printing needs a printer/UI device. The in-memory/open/export part is
#  run for real; the print step is attempted but treated as non-fatal / noted.
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
        '<report name="InMem" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="rh" height="24">\n'
        '   <text name="title" x="0" y="0"  w="180" h="12" fontSize="20" hAlign="center">In-memory report</text>\n'
        '   <text name="sub"   x="0" y="14" w="180" h="6"  fontSize="10" hAlign="center">Opened with rptOpenReportMem -- no file on disk.</text>\n'
        '  </band>\n'
        '  <band kind="pageheader" name="ph" height="8">\n'
        '   <text name="ph1" x="0" y="0" w="180" h="6" fontSize="9" hAlign="left">LumasReport example 14</text>\n'
        '  </band>\n'
        '  <band kind="detail" name="det" height="8">\n'
        '   <text name="d1" x="0" y="0" w="180" h="6" fontSize="11" hAlign="left">This band was rendered from bytes handed to the engine directly.</text>\n'
        '  </band>\n'
        '  <band kind="pagefooter" name="pf" height="8">\n'
        '   <text name="pf1" x="0" y="0" w="180" h="6" fontSize="8" hAlign="right">page {{var:PageNo}} of {{var:TotalPages}}</text>\n'
        '  </band>\n'
        ' </bands>\n'
        '</report>\n'
    )


def main():
    pdf, eng = boot_engine()
    if not eng:
        return
    try:
        out_pdf = os.path.join(HERE, "14_open_mem.pdf")
        out_print = os.path.join(HERE, "14_printed.pdf")

        # --- 1. Open straight from memory (no temp file) --------------------
        print("== Open from memory ==")
        blob = build_xml().encode('latin-1')
        buf = ctypes.create_string_buffer(blob, len(blob))
        print("  blob is %d bytes" % len(blob))
        job = L.rptOpenReportMem(eng, ctypes.cast(buf, ctypes.c_void_p), len(blob))
        if not job:
            print("  rptOpenReportMem failed"); dump_err(eng); return

        pages = 0
        try:
            if L.rptRender(job) == 0:
                print("  render failed"); dump_err(eng); return
            pages = L.rptGetPageCount(job)
            print("  rendered %d page(s) from the in-memory report" % pages)

            # --- 2a. Export the in-memory report to a PDF -------------------
            print("== Export ==")
            if L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1')) == 0:
                print("  export failed"); dump_err(eng); return
            print("  wrote " + out_pdf)

            # --- 2b. Headless print via "Microsoft Print to PDF" -----------
            print("== Headless print ==")
            if L.rptPrintA(job, b"Microsoft Print to PDF", out_print.encode('latin-1')) != 0:
                print('  "Microsoft Print to PDF" -> ' + out_print)
            else:
                print('  "Microsoft Print to PDF" not available / print failed (continuing -- not fatal):')
                dump_err(eng)

            # --- 2c. Preview (documented, deliberately NOT called) ----------
            #  rptPreviewA(job, "In-memory report") would pop the built-in modal viewer.
        finally:
            L.rptCloseReport(job)

        # --- 3. Verify the in-memory PDF is real ----------------------------
        print("== Verify ==")
        if os.path.exists(out_pdf) and pages >= 1:
            print("  OK: %s exists, report has %d page(s)" % (out_pdf, pages))
        else:
            print("  VERIFY FAILED: in-memory PDF missing or zero pages")
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

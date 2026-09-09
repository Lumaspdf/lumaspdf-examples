# ============================================================================
#  LumasReport example 15 -- {{ }} tag language + text formatting tour (Python)
#  Exercises every form of the v1 interpolation namespace and the text-formatting
#  knobs, then proves (by exporting to plain TEXT and grepping it) that the
#  interpolations actually resolved:
#    {{expr: 2+3*4 }} -> 14 ; {{var:Name}} ; {{fields.d.Col}} / {{d.Col}} ;
#    {{{{ }} -> literal "{{ }}" ; FORMATNUM('#,##0.00',1234.5) ; FORMATDATE(...)
#  hAlign 0=left 1=center 2=right 3=justify ; vAlign 0=top 1=middle 2=bottom.
# ============================================================================
import sys, os, ctypes, datetime
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


def csv_data():
    return "Col,Note\nAlpha,first\nBeta,second\n"


# The report template. %CSV% is replaced with the absolute csv path at runtime.
def report_tmpl():
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="TagTour" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="12" marginTop="12" marginRight="12" marginBottom="12"/>\n'
        ' <datasources>\n'
        '  <datasource alias="d" provider="csv" conn="%CSV%"/>\n'
        ' </datasources>\n'
        ' <params>\n'
        '  <param name="Name" default="(unset)"/>\n'
        ' </params>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="rh" height="120">\n'
        '   <text name="h"   x="0" y="0"  w="186" h="8" fontSize="16" hAlign="center">Tag &amp; formatting tour</text>\n'
        '   <text name="ex"  x="0" y="12" w="186" h="6" fontSize="11">expr 2+3*4 = {{expr: 2+3*4 }}</text>\n'
        '   <text name="vr"  x="0" y="20" w="186" h="6" fontSize="11">var:Name = {{var:Name}}</text>\n'
        '   <text name="fn"  x="0" y="28" w="186" h="6" fontSize="11">FORMATNUM = {{expr: FORMATNUM(\'#,##0.00\', 1234.5) }}</text>\n'
        '   <text name="fd"  x="0" y="36" w="186" h="6" fontSize="11">FORMATDATE = {{expr: FORMATDATE(\'yyyy-mm-dd\', TODAY()) }}</text>\n'
        '   <text name="esc" x="0" y="44" w="186" h="6" fontSize="11">escape literal = {{{{ }}</text>\n'
        '   <text name="a0" x="0" y="56" w="186" h="6" fontSize="10" hAlign="0">hAlign 0 = left</text>\n'
        '   <text name="a1" x="0" y="63" w="186" h="6" fontSize="10" hAlign="1">hAlign 1 = center</text>\n'
        '   <text name="a2" x="0" y="70" w="186" h="6" fontSize="10" hAlign="2">hAlign 2 = right</text>\n'
        '   <text name="a3" x="0" y="77" w="186" h="6" fontSize="10" hAlign="3">hAlign 3 = justify this line so it spreads across the whole width of the box evenly</text>\n'
        '   <text name="v0" x="0"   y="92" w="60" h="20" fontSize="9" vAlign="0">vAlign 0 top</text>\n'
        '   <text name="v1" x="63"  y="92" w="60" h="20" fontSize="9" vAlign="1">vAlign 1 middle</text>\n'
        '   <text name="v2" x="126" y="92" w="60" h="20" fontSize="9" vAlign="2">vAlign 2 bottom</text>\n'
        '  </band>\n'
        '  <band kind="detail" name="rows" height="7" data="d">\n'
        '   <text name="r" x="0" y="0" w="186" h="6" fontSize="11">row: fields.d.Col={{fields.d.Col}}  bare d.Col={{d.Col}}  note={{d.Note}}</text>\n'
        '  </band>\n'
        ' </bands>\n'
        '</report>\n'
    )


def prove(what, needle, hay):
    if needle in hay:
        print('  OK   %s found "%s"' % (what, needle))
    else:
        print('  MISS %s expected "%s"' % (what, needle))


def main():
    pdf, eng = boot_engine()
    if not eng:
        return
    try:
        csv = os.path.join(HERE, "15_data.csv")
        out_pdf = os.path.join(HERE, "15_tags.pdf")
        out_txt = os.path.join(HERE, "15_tags.txt")

        write_text(csv, csv_data())

        # Inject the absolute CSV path into the report markup.
        xml = report_tmpl().replace("%CSV%", csv)
        blob = xml.encode('latin-1')
        buf = ctypes.create_string_buffer(blob, len(blob))
        job = L.rptOpenReportMem(eng, ctypes.cast(buf, ctypes.c_void_p), len(blob))
        if not job:
            print("open failed"); dump_err(eng); return
        try:
            # Give the {{var:Name}} parameter a distinctive value to grep for.
            L.rptSetParamStr(job, b"Name", b"Ada_Lovelace")

            if L.rptRender(job) == 0:
                print("render failed"); dump_err(eng); return
            print("rendered %d page(s)" % L.rptGetPageCount(job))

            if L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1')) == 0:
                print("PDF export failed"); dump_err(eng); return
            print("wrote " + out_pdf)
            if L.rptExportA(job, L.RPT_EXP_TEXT, out_txt.encode('latin-1')) == 0:
                print("TEXT export failed"); dump_err(eng); return
            print("wrote " + out_txt)
        finally:
            L.rptCloseReport(job)

        # --- Proof: grep the TEXT export for each resolved interpolation -----
        print("== Proof (grep the TEXT export) ==")
        txt = read_all_text(out_txt)
        iso_today = datetime.date.today().strftime("%Y-%m-%d")

        prove("expr 2+3*4", "= 14", txt)
        prove("var:Name", "Ada_Lovelace", txt)
        prove("FORMATNUM", "1,234.50", txt)
        prove("FORMATDATE", iso_today, txt)
        prove("escape {{}}", "{{ }}", txt)
        prove("fields.d.Col", "Alpha", txt)
        prove("bare d.Col", "Beta", txt)
    finally:
        L.rptDeleteEngine(eng)
        L.pdfDeletePDF(pdf)


# --- shared boilerplate (mirror of _shared.inc) -----------------------------

def read_all_text(path):
    if not os.path.exists(path):
        return ""
    with open(path, "rb") as f:
        return f.read().decode('latin-1')


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

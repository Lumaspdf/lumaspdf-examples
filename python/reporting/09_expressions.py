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
#  Python (ctypes) port of examples\Vb6\reporting\09_expressions.bas
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


def build_report():
    y = [0]
    s = []

    def line_el(label, expr):
        s.append('   <text name="l' + str(y[0]) + '" x="0" y="' + str(y[0]) +
                 '" w="185" h="5" fontSize="9" wordWrap="0">' + label +
                 ' -&gt; {{expr: ' + expr + '}}</text>\n')
        y[0] += 5

    line_el("UPPER", "UPPER('abc')")
    line_el("LOWER", "LOWER('ABC')")
    line_el("LEFT", "LEFT('LumasReport', 5)")
    line_el("RIGHT", "RIGHT('LumasReport', 6)")
    line_el("SUBSTR", "SUBSTR('LumasReport', 6, 6)")
    line_el("LEN", "LEN('LumasReport')")
    line_el("TRIM", "'[' + TRIM('  hi  ') + ']'")
    line_el("REPLACE", "REPLACE('a-b-c', '-', '+')")
    line_el("PADL", "PADL('7', 4, '0')")
    line_el("POS", "POS('Report', 'LumasReport')")
    line_el("REVERSE", "REVERSE('abc')")
    line_el("REPLICATE", "REPLICATE('ab', 3)")
    line_el("CONTAINS", "CONTAINS('LumasReport', 'Rep')")
    line_el("STARTSWITH", "STARTSWITH('LumasReport', 'Lumas')")
    line_el("ENDSWITH", "ENDSWITH('LumasReport', 'port')")
    line_el("ABS", "ABS(-42)")
    line_el("ROUND", "ROUND(3.14159, 2)")
    line_el("FLOOR", "FLOOR(3.9)")
    line_el("CEIL", "CEIL(3.1)")
    line_el("SQRT", "SQRT(144)")
    line_el("POWER", "POWER(2, 10)")
    line_el("MIN", "MIN(5, 3)")
    line_el("MAX", "MAX(5, 3)")
    line_el("SIGN", "SIGN(-7)")
    line_el("TRUNC", "TRUNC(9.87)")
    line_el("MOD_op", "17 % 5")
    line_el("YEAR", "YEAR(TODAY())")
    line_el("FORMATDATE", "FORMATDATE('yyyy-mm-dd', TODAY())")
    line_el("ADDDAYS", "FORMATDATE('yyyy-mm-dd', ADDDAYS(TODAY(), 7))")
    line_el("DATEDIFF", "DATEDIFF('d', TODAY(), ADDDAYS(TODAY(), 30))")
    line_el("CSTR", "CSTR(123)")
    line_el("CINT", "CINT('45')")
    line_el("CFLOAT", "CFLOAT('3.5') * 2")
    line_el("VAL", "VAL('19') + 1")
    line_el("FORMATNUM", "FORMATNUM('#,##0.00', 1234.5)")
    line_el("ISNULL", "ISNULL(NULLIF(3, 3))")
    line_el("IFNULL", "IFNULL(NULLIF(3, 3), 'was-null')")
    line_el("COALESCE", "COALESCE(NULLIF(1,1), NULLIF(2,2), 'fallback')")
    line_el("REGEXMATCH", "REGEXMATCH('abc123', '[a-z]+[0-9]+')")
    line_el("REGEXREPLACE", "REGEXREPLACE('a1b2c3', '[0-9]', '#')")
    line_el("REGEXEXTRACT", "REGEXEXTRACT('order 4567 ok', '[0-9]+')")

    xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="Expressions" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="12" marginTop="12" marginRight="12" marginBottom="12"/>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="rh" height="' + str(y[0] + 4) + '">\n' +
        ''.join(s) +
        '  </band>\n'
        ' </bands>\n'
        '</report>\n'
    )
    return xml


def main():
    eng, pdf = boot_engine()
    if not eng:
        return

    xml = build_report()
    lrpt = os.path.join(HERE, "09_expr.lrpt")
    out_pdf = os.path.join(HERE, "09_expr.pdf")
    out_txt = os.path.join(HERE, "09_expr.txt")
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
        L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1'))
        L.rptExportA(job, L.RPT_EXP_TEXT, out_txt.encode('latin-1'))
        print("rendered %d page(s); 41 expression lines -> %s" % (L.rptGetPageCount(job), out_txt))
        L.rptCloseReport(job)
    finally:
        L.rptDeleteEngine(eng)
        L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

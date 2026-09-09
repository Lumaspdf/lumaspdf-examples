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
#  Python (ctypes) port of examples\Vb6\reporting\10_aggregates_groups.bas
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
    eng, pdf = boot_engine()
    if not eng:
        return

    csv = os.path.join(HERE, "10_data.csv")
    lrpt = os.path.join(HERE, "10_groups.lrpt")
    out_pdf = os.path.join(HERE, "10_groups.pdf")
    out_txt = os.path.join(HERE, "10_groups.txt")

    csv_data = (
        "Cat,Item,Amount\n"
        "Fruit,Apple,10\n"
        "Fruit,Pear,7\n"
        "Fruit,Plum,5\n"
        "Dairy,Milk,4\n"
        "Dairy,Cheese,9\n"
        "Dairy,Butter,6\n"
        "Grain,Bread,3\n"
        "Grain,Rice,8\n"
        "Grain,Oats,2\n"
    )
    write_text(csv, csv_data)
    xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="Groups" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
        ' <datasources><datasource alias="d" provider="csv" conn="' + csv + '"/></datasources>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="rh" height="10"><text name="t" x="0" y="0" w="180" h="8" fontSize="16" hAlign="center" wordWrap="0">Grouped Catalog</text></band>\n'
        '  <band kind="groupheader" name="gh" group="d.Cat" height="7"><text name="g" x="0" y="1" w="180" h="5" fontSize="12" bold="1" wordWrap="0">Category: {{expr: d.Cat}}</text></band>\n'
        '  <band kind="detail" name="det" height="5" data="d"><text name="i" x="6" y="0" w="110" h="4" fontSize="9" wordWrap="0">{{Item}}</text><text name="a" x="118" y="0" w="26" h="4" fontSize="9" hAlign="right" wordWrap="0">{{Amount}}</text><text name="r" x="148" y="0" w="30" h="4" fontSize="9" hAlign="right" wordWrap="0">[{{expr: SUM(Amount)}}]</text></band>\n'
        '  <band kind="groupfooter" name="gf" group="d.Cat" height="6"><text name="gt" x="4" y="0" w="176" h="5" fontSize="9" bold="1" wordWrap="0">{{expr: d.Cat}} total = {{expr: SUM(Amount)}}  (n={{expr: COUNT(Amount)}}, avg={{expr: ROUND(AVG(Amount),2)}}, min={{expr: MIN(Amount)}}, max={{expr: MAX(Amount)}})</text></band>\n'
        '  <band kind="summary" name="sm" height="8"><text name="s" x="4" y="1" w="176" h="6" fontSize="11" bold="1" wordWrap="0">GRAND TOTAL = {{expr: SUM(Amount)}}   (items={{expr: COUNT()}}, categories={{expr: COUNTDISTINCT(Cat)}})</text></band>\n'
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
        print("rendered %d page(s), grouped by Cat with per-group + grand totals" % L.rptGetPageCount(job))
        L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1'))
        L.rptExportA(job, L.RPT_EXP_TEXT, out_txt.encode('latin-1'))
        print("wrote %s  +  %s" % (out_pdf, out_txt))
        L.rptCloseReport(job)
    finally:
        L.rptDeleteEngine(eng)
        L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

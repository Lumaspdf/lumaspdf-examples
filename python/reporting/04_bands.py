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
#  Python (ctypes) port of examples\Vb6\reporting\04_bands.bas
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


def build_csv():
    sb = "grp,item,val\n"
    for g in range(1, 4):
        for r in range(1, 31):
            sb += "Group-%d,Item %d-%02d,%d\n" % (g, g, r, g * 100 + r)
    return sb


def main():
    eng, pdf = boot_engine()
    if not eng:
        return

    csv = os.path.join(HERE, "04_data.csv")
    lrpt = os.path.join(HERE, "04_report.lrpt")
    out_pdf = os.path.join(HERE, "04_out.pdf")
    write_text(csv, build_csv())
    xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="BandsDemo" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
        ' <datasources><datasource alias="d" provider="csv" conn="' + csv + '"/></datasources>\n'
        ' <styles>\n'
        '  <style name="Wm"  fontSize="48" bold="1" textColor="00EEEEEE" hAlign="1" vAlign="1"/>\n'
        '  <style name="Ov"  fontSize="8"  textColor="00B0B0B0" hAlign="2"/>\n'
        '  <style name="Grp" fontSize="12" bold="1" textColor="00FFFFFF" backColor="002A6099" vAlign="1"/>\n'
        ' </styles>\n'
        ' <bands>\n'
        '  <band kind="background" name="bg" height="297">\n'
        '   <text name="wm" x="20" y="120" w="150" h="40" style="Wm" rotation="45" wordWrap="0">BACKGROUND</text>\n'
        '  </band>\n'
        '  <band kind="overlay" name="ov" height="297">\n'
        '   <text name="ol" x="0" y="150" w="180" h="6" style="Ov" rotation="90" wordWrap="0">overlay band</text>\n'
        '  </band>\n'
        '  <band kind="reportheader" name="rh" height="16">\n'
        '   <text name="rt" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center">reportheader band</text>\n'
        '  </band>\n'
        '  <band kind="pageheader" name="ph" height="8">\n'
        '   <text name="pt" x="0" y="0" w="180" h="6" fontSize="9" wordWrap="0">pageheader band - grp / item / val</text>\n'
        '  </band>\n'
        '  <band kind="groupheader" name="gh" group="d.grp" height="8">\n'
        '   <text name="gt" x="0" y="0" w="180" h="7" style="Grp" wordWrap="0">groupheader band: {{d.grp}}</text>\n'
        '  </band>\n'
        '  <band kind="detail" name="det" height="6" data="d">\n'
        '   <text name="di" x="4"   y="0" w="120" h="5" fontSize="9" wordWrap="0">detail band: {{d.item}}</text>\n'
        '   <text name="dv" x="130" y="0" w="46"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{d.val}}</text>\n'
        '  </band>\n'
        '  <band kind="groupfooter" name="gf" group="d.grp" height="7">\n'
        '   <text name="ft" x="0" y="1" w="180" h="5" fontSize="9" italic="1" wordWrap="0">groupfooter band: end of {{d.grp}}</text>\n'
        '  </band>\n'
        '  <band kind="pagefooter" name="pf" height="7">\n'
        '   <text name="pft" x="0" y="1" w="180" h="5" fontSize="8" hAlign="center" wordWrap="0">pagefooter band</text>\n'
        '  </band>\n'
        '  <band kind="summary" name="sm" height="16">\n'
        '   <text name="st" x="0" y="2" w="180" h="10" fontSize="14" hAlign="center">summary band - report complete</text>\n'
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
        pages = L.rptGetPageCount(job)
        print("rendered %d page(s)" % pages)
        if L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1')) == 0:
            print("export failed")
            dump_rpt_error(eng)
            L.rptCloseReport(job)
            return
        print("wrote " + out_pdf)
        if pages < 2:
            print("FAIL: expected >= 2 pages, got %d" % pages)
        else:
            print("OK: multi-page grouped report with all band kinds")
        L.rptCloseReport(job)
    finally:
        L.rptDeleteEngine(eng)
        L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

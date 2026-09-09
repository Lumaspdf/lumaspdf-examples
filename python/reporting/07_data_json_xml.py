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
#  Python (ctypes) port of examples\Vb6\reporting\07_data_json_xml.bas
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


def run_report(eng, tag, xml):
    lrpt = os.path.join(HERE, "07_" + tag + ".lrpt")
    out_pdf = os.path.join(HERE, "07_" + tag + ".pdf")
    out_txt = os.path.join(HERE, "07_" + tag + ".txt")
    write_text(lrpt, xml)
    job = L.rptOpenReportA(eng, lrpt.encode('latin-1'))
    if not job:
        print(tag + ": open failed")
        dump_rpt_error(eng)
        return False
    if L.rptRender(job) == 0:
        print(tag + ": render failed")
        dump_rpt_error(eng)
        L.rptCloseReport(job)
        return False
    print("%s: rendered %d page(s)" % (tag, L.rptGetPageCount(job)))
    if L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1')) == 0:
        print(tag + ": pdf export failed")
        dump_rpt_error(eng)
        L.rptCloseReport(job)
        return False
    if L.rptExportA(job, L.RPT_EXP_TEXT, out_txt.encode('latin-1')) == 0:
        print(tag + ": text export failed")
        dump_rpt_error(eng)
        L.rptCloseReport(job)
        return False
    print("wrote %s + %s" % (out_pdf, out_txt))
    L.rptCloseReport(job)
    return True


def main():
    eng, pdf = boot_engine()
    if not eng:
        return

    jsn = os.path.join(HERE, "07_data.json")
    xm = os.path.join(HERE, "07_data.xml")

    try:
        json_data = '[{"City":"Paris","Country":"FR","Pop":2100},{"City":"Lyon","Country":"FR","Pop":515},{"City":"Nice","Country":"FR","Pop":340}]'
        write_text(jsn, json_data)
        xml_data = (
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<rows>\n'
            ' <row City="Berlin" Country="DE" Pop="3600"/>\n'
            ' <row City="Munich" Country="DE" Pop="1500"/>\n'
            ' <row City="Hamburg" Country="DE" Pop="1900"/>\n'
            '</rows>\n'
        )
        write_text(xm, xml_data)

        xml = (
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<report name="JsonCities" tagLangVersion="1">\n'
            ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
            ' <datasources><datasource alias="j" provider="json" conn="' + jsn + '" query=""/></datasources>\n'
            ' <bands>\n'
            '  <band kind="reportheader" name="rh" height="10">\n'
            '   <text name="ttl" x="0" y="0" w="180" h="8" fontSize="16" hAlign="center">Cities (JSON source)</text>\n'
            '  </band>\n'
            '  <band kind="detail" name="jd" height="6" data="j">\n'
            '   <text name="c1" x="0"  y="0" w="60" h="5" fontSize="9" wordWrap="0">{{j.City}}</text>\n'
            '   <text name="c2" x="60" y="0" w="30" h="5" fontSize="9" wordWrap="0">{{j.Country}}</text>\n'
            '   <text name="c3" x="90" y="0" w="40" h="5" fontSize="9" hAlign="right" wordWrap="0">{{j.Pop}}</text>\n'
            '  </band>\n'
            ' </bands>\n'
            '</report>\n'
        )
        if not run_report(eng, "json", xml):
            return

        xml = (
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<report name="XmlCities" tagLangVersion="1">\n'
            ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
            ' <datasources><datasource alias="x" provider="xml" conn="' + xm + '" query="rows/row"/></datasources>\n'
            ' <bands>\n'
            '  <band kind="reportheader" name="rh" height="10">\n'
            '   <text name="ttl" x="0" y="0" w="180" h="8" fontSize="16" hAlign="center">Cities (XML source)</text>\n'
            '  </band>\n'
            '  <band kind="detail" name="xd" height="6" data="x">\n'
            '   <text name="c1" x="0"  y="0" w="60" h="5" fontSize="9" wordWrap="0">{{x.City}}</text>\n'
            '   <text name="c2" x="60" y="0" w="30" h="5" fontSize="9" wordWrap="0">{{x.Country}}</text>\n'
            '   <text name="c3" x="90" y="0" w="40" h="5" fontSize="9" hAlign="right" wordWrap="0">{{x.Pop}}</text>\n'
            '  </band>\n'
            ' </bands>\n'
            '</report>\n'
        )
        if not run_report(eng, "xml", xml):
            return
    finally:
        L.rptDeleteEngine(eng)
        L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

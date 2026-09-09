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
#  Python (ctypes) port of examples\Vb6\reporting\03_export_targets.bas
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
    targets = [
        (L.RPT_EXP_PDF, "pdf"), (L.RPT_EXP_HTML, "html"), (L.RPT_EXP_CSV, "csv"),
        (L.RPT_EXP_JSON, "json"), (L.RPT_EXP_XML, "xml"), (L.RPT_EXP_TEXT, "txt"),
        (L.RPT_EXP_SVG, "svg"), (L.RPT_EXP_XLSX, "xlsx"), (L.RPT_EXP_PNG, "png"),
        (L.RPT_EXP_BMP, "bmp"),
    ]

    eng, pdf = boot_engine()
    if not eng:
        return

    csv = os.path.join(HERE, "03_data.csv")
    lrpt = os.path.join(HERE, "03_report.lrpt")
    csv_data = (
        "product,qty,price\n"
        "Widget,4,9.95\n"
        "Gadget,2,19.50\n"
        "Sprocket,7,3.25\n"
    )
    write_text(csv, csv_data)
    xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="ExportDemo" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
        ' <datasources><datasource alias="d" provider="csv" conn="' + csv + '"/></datasources>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="rh" height="14">\n'
        '   <text name="ttl" x="0" y="0" w="180" h="8" fontSize="16" hAlign="center">Order Lines</text>\n'
        '  </band>\n'
        '  <band kind="detail" name="det" height="7" data="d">\n'
        '   <text name="p" x="0"   y="0" w="90" h="6" fontSize="10" wordWrap="0">{{d.product}}</text>\n'
        '   <text name="q" x="90"  y="0" w="30" h="6" fontSize="10" hAlign="right" wordWrap="0">{{d.qty}}</text>\n'
        '   <text name="r" x="120" y="0" w="60" h="6" fontSize="10" hAlign="right" wordWrap="0">{{d.price}}</text>\n'
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
        print("== Exporting to all targets ==")
        for tid, ext in targets:
            out_file = os.path.join(HERE, "03_out." + ext)
            if L.rptExportA(job, tid, out_file.encode('latin-1')) != 0 and os.path.exists(out_file):
                print("  [%s] id=%d  OK  %d bytes" % (ext, tid, os.path.getsize(out_file)))
            else:
                print("  [%s] id=%d  FAILED" % (ext, tid))
                dump_rpt_error(eng)
        L.rptCloseReport(job)
    finally:
        L.rptDeleteEngine(eng)
        L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

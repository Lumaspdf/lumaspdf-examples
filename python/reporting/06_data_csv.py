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
#  Python (ctypes) port of examples\Vb6\reporting\06_data_csv.bas
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

    lrpt = os.path.join(HERE, "06_data.lrpt")
    csv = os.path.join(HERE, "06_data.csv")
    out_pdf = os.path.join(HERE, "06_data.pdf")
    out_csv = os.path.join(HERE, "06_data_out.csv")
    out_txt = os.path.join(HERE, "06_data.txt")

    csv_data = (
        "Region,Product,Qty,Price\n"
        "North,Widget,10,2.50\n"
        "North,Gadget,4,9.99\n"
        "South,Widget,7,2.50\n"
        "South,Sprocket,20,1.25\n"
        "East,Gadget,3,9.99\n"
        "West,Sprocket,15,1.25\n"
    )
    write_text(csv, csv_data)
    xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="CsvSales" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
        ' <datasources><datasource alias="d" provider="csv" conn="' + csv + '"/></datasources>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="rh" height="12">\n'
        '   <text name="ttl" x="0" y="0" w="180" h="8" fontSize="16" hAlign="center">Sales by Region</text>\n'
        '  </band>\n'
        '  <band kind="pageheader" name="ph" height="8">\n'
        '   <text name="h1" x="0"   y="0" w="50" h="6" fontSize="9" style="">REGION</text>\n'
        '   <text name="h2" x="50"  y="0" w="60" h="6" fontSize="9">PRODUCT</text>\n'
        '   <text name="h3" x="110" y="0" w="30" h="6" fontSize="9" hAlign="right">QTY</text>\n'
        '   <text name="h4" x="140" y="0" w="40" h="6" fontSize="9" hAlign="right">PRICE</text>\n'
        '   <line name="hl" x="0" y="7" w="180" h="0.3" toX="180" toY="0"/>\n'
        '  </band>\n'
        '  <band kind="detail" name="det" height="6" data="d">\n'
        '   <text name="c1" x="0"   y="0" w="50" h="5" fontSize="9" wordWrap="0">{{d.Region}}</text>\n'
        '   <text name="c2" x="50"  y="0" w="60" h="5" fontSize="9" wordWrap="0">{{d.Product}}</text>\n'
        '   <text name="c3" x="110" y="0" w="30" h="5" fontSize="9" hAlign="right" wordWrap="0">{{d.Qty}}</text>\n'
        '   <text name="c4" x="140" y="0" w="40" h="5" fontSize="9" hAlign="right" wordWrap="0">{{d.Price}}</text>\n'
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
            print("pdf export failed")
            dump_rpt_error(eng)
            L.rptCloseReport(job)
            return
        if L.rptExportA(job, L.RPT_EXP_CSV, out_csv.encode('latin-1')) == 0:
            print("csv export failed")
            dump_rpt_error(eng)
            L.rptCloseReport(job)
            return
        if L.rptExportA(job, L.RPT_EXP_TEXT, out_txt.encode('latin-1')) == 0:
            print("text export failed")
            dump_rpt_error(eng)
            L.rptCloseReport(job)
            return
        print("wrote " + out_pdf)
        print("wrote " + out_csv)
        print("wrote " + out_txt)
        L.rptCloseReport(job)
    finally:
        L.rptDeleteEngine(eng)
        L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

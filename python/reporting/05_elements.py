import sys, os, ctypes, struct
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
#  Python (ctypes) port of examples\Vb6\reporting\05_elements.bas
#  text / line / shape / image / barcode / subreport elements.
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


def write_bmp_8x8(path):
    # 24-bit 8x8 BMP, bottom-up BGR checkerboard (red / blue).
    pixels = bytearray()
    for y in range(8):
        for x in range(8):
            if (x + y) & 1 == 0:
                pixels += bytes((0, 0, 255))   # B,G,R -> red
            else:
                pixels += bytes((255, 0, 0))   # B,G,R -> blue
    # BITMAPFILEHEADER (14) + BITMAPINFOHEADER (40) = 54, then 192 pixel bytes
    fileheader = b"BM" + struct.pack("<III", 54 + 192, 0, 54)
    infoheader = struct.pack("<IiiHHIIiiII", 40, 8, 8, 1, 24, 0, 192, 2835, 2835, 0, 0)
    with open(path, "wb") as f:
        f.write(fileheader)
        f.write(infoheader)
        f.write(bytes(pixels))


def main():
    eng, pdf = boot_engine()
    if not eng:
        return

    lrpt = os.path.join(HERE, "05_elements.lrpt")
    sub = os.path.join(HERE, "05_sub.lrpt")
    img = os.path.join(HERE, "05_img.bmp")
    out_pdf = os.path.join(HERE, "05_elements.pdf")

    sub_xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="Sub" tagLangVersion="1">\n'
        ' <page width="70" height="30" marginLeft="1" marginTop="1" marginRight="1" marginBottom="1"/>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="sh" height="10">\n'
        '   <text name="st" x="0" y="0" w="66" h="6" fontSize="8">Subreport content here.</text>\n'
        '  </band>\n'
        ' </bands>\n'
        '</report>\n'
    )
    write_text(sub, sub_xml)
    write_bmp_8x8(img)

    xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="Elements" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="rh" height="150">\n'
        '   <text name="title" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center">Every Element Kind</text>\n'
        '   <text name="note"  x="0" y="12" w="180" h="6" fontSize="9" hAlign="center">text / line / shape / image / barcode / subreport</text>\n'
        '   <line  name="rule" x="0" y="20" w="180" h="0.3" toX="180" toY="0"/>\n'
        '   <shape name="rect" x="0"  y="26" w="55" h="22" shape="0"/>\n'
        '   <shape name="rrct" x="63" y="26" w="55" h="22" shape="1"/>\n'
        '   <shape name="elps" x="126" y="26" w="55" h="22" shape="2"/>\n'
        '   <text name="l1" x="0"   y="49" w="55" h="5" fontSize="7" hAlign="center">shape=0 rect</text>\n'
        '   <text name="l2" x="63"  y="49" w="55" h="5" fontSize="7" hAlign="center">shape=1 roundrect</text>\n'
        '   <text name="l3" x="126" y="49" w="55" h="5" fontSize="7" hAlign="center">shape=2 ellipse</text>\n'
        '   <image name="pic" x="0" y="58" w="24" h="24" source="' + img + '" stretch="1"/>\n'
        '   <text name="il" x="0" y="83" w="40" h="5" fontSize="7">8x8 BMP image</text>\n'
        '   <barcode name="qr"  x="40"  y="58" w="24" h="24" type="0" text="QR:LumasReport"/>\n'
        '   <barcode name="pdf" x="70"  y="58" w="40" h="24" type="1" text="PDF417-DATA-001"/>\n'
        '   <barcode name="dm"  x="116" y="58" w="24" h="24" type="2" text="DataMatrix99"/>\n'
        '   <barcode name="az"  x="146" y="58" w="24" h="24" type="3" text="AZTEC-XYZ"/>\n'
        '   <text name="bl" x="40" y="83" w="140" h="5" fontSize="7">barcodes: QR / PDF417 / DataMatrix / Aztec</text>\n'
        '   <subreport name="sub" x="0" y="92" w="90" h="30" ref="05_sub.lrpt"/>\n'
        '   <text name="sl" x="0" y="123" w="120" h="5" fontSize="7">^ subreport (05_sub.lrpt) merged above</text>\n'
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
            print("export failed")
            dump_rpt_error(eng)
            L.rptCloseReport(job)
            return
        print("wrote " + out_pdf)
        L.rptCloseReport(job)
    finally:
        L.rptDeleteEngine(eng)
        L.pdfDeletePDF(pdf)


if __name__ == "__main__":
    main()

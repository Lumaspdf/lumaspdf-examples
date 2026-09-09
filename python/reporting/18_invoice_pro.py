# ============================================================================
#  LumasReport example 18 -- Professional FRAMED invoice (Python port)
#  A polished, print-ready invoice built from the banded model + the SECTION-
#  BOUNDED line feature (scope="section"): horizontal rules auto-span the band
#  WIDTH, vertical rules auto-span the band HEIGHT. Money columns right-aligned;
#  totals use inline SUM(Qty*Price). Exports to PDF/HTML/SVG/TEXT + CSV/XLSX/XLS.
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

# Colours are COLORREF 00BBGGRR (low byte = red).
NAVY  = "005F3A1F"   # brand / rules / totals
INK   = "00222222"   # near-black body text
GREY  = "00808080"   # muted labels
GRID  = "00B9B9B9"   # table grid lines
HAIR  = "00D8D8D8"   # hairline row rules
SHADE = "00F4F1EC"   # zebra row tint
WHITE = "00FFFFFF"


def csv_data():
    return (
        "Item,Qty,Price\n"
        "Precision Widget Assembly,4,42.50\n"
        "Gadget Control Module,2,149.50\n"
        "Shielded Signal Cable (3m),10,4.75\n"
        "Universal Power Adapter,3,28.00\n"
        "Steel Mounting Bracket,12,3.25\n"
        "Thermal Interface Kit,5,11.20\n"
    )


# The five vertical column dividers, section-scoped so each spans its band.
def col_grid(tag):
    return (
        '   <line name="' + tag + 'a" orient="v" scope="section" x="0"   width="0.35" color="' + GRID + '"/>\n'
        '   <line name="' + tag + 'b" orient="v" scope="section" x="95"  width="0.35" color="' + GRID + '"/>\n'
        '   <line name="' + tag + 'c" orient="v" scope="section" x="117" width="0.35" color="' + GRID + '"/>\n'
        '   <line name="' + tag + 'd" orient="v" scope="section" x="149" width="0.35" color="' + GRID + '"/>\n'
        '   <line name="' + tag + 'e" orient="v" scope="section" x="182" width="0.35" color="' + GRID + '"/>\n'
    )


def build_xml(csv):
    dot = chr(0xB7)   # middle dot U+00B7
    s = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="InvoicePro" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="14" marginTop="14" marginRight="14" marginBottom="16"/>\n'
        ' <datasources><datasource alias="d" provider="csv" conn="' + csv + '"/></datasources>\n'
        ' <variables><variable name="PageNo" init="1"/></variables>\n'
        ' <styles>\n'
        '  <style name="brand"  fontName="Helvetica" fontSize="20" bold="1" textColor="' + NAVY + '"/>\n'
        '  <style name="addr"   fontName="Helvetica" fontSize="8"  textColor="' + GREY + '"/>\n'
        '  <style name="title"  fontName="Helvetica" fontSize="30" bold="1" textColor="' + NAVY + '" hAlign="right"/>\n'
        '  <style name="mlbl"   fontName="Helvetica" fontSize="8.5" bold="1" textColor="' + GREY + '" hAlign="right"/>\n'
        '  <style name="mval"   fontName="Helvetica" fontSize="8.5" textColor="' + INK + '" hAlign="right"/>\n'
        '  <style name="billto" fontName="Helvetica" fontSize="8" bold="1" textColor="' + NAVY + '"/>\n'
        '  <style name="cust"   fontName="Helvetica" fontSize="9.5" textColor="' + INK + '"/>\n'
        '  <style name="colh"   fontName="Helvetica" fontSize="8.5" bold="1" textColor="' + WHITE + '"/>\n'
        '  <style name="colhr"  fontName="Helvetica" fontSize="8.5" bold="1" textColor="' + WHITE + '" hAlign="right"/>\n'
        '  <style name="cell"   fontName="Helvetica" fontSize="9.5" textColor="' + INK + '"/>\n'
        '  <style name="cellr"  fontName="Helvetica" fontSize="9.5" textColor="' + INK + '" hAlign="right"/>\n'
        '  <style name="tlbl"   fontName="Helvetica" fontSize="9.5" bold="1" textColor="' + INK + '" hAlign="right"/>\n'
        '  <style name="tval"   fontName="Helvetica" fontSize="9.5" textColor="' + INK + '" hAlign="right"/>\n'
        '  <style name="glbl"   fontName="Helvetica" fontSize="13" bold="1" textColor="' + WHITE + '"/>\n'
        '  <style name="gval"   fontName="Helvetica" fontSize="13" bold="1" textColor="' + WHITE + '" hAlign="right"/>\n'
        '  <style name="note"   fontName="Helvetica" fontSize="8.5" textColor="' + GREY + '"/>\n'
        '  <style name="foot"   fontName="Helvetica" fontSize="8" textColor="' + GREY + '"/>\n'
        '  <style name="footr"  fontName="Helvetica" fontSize="8" textColor="' + GREY + '" hAlign="right"/>\n'
        ' </styles>\n'
        ' <bands>\n'
        # ============ REPORT HEADER ============
        '  <band kind="reportheader" name="rh" height="42">\n'
        '   <text name="co"   x="0"  y="0"  w="110" h="9" style="brand" wordWrap="0">ACME Corporation</text>\n'
        '   <text name="a1"   x="0"  y="10" w="120" h="4" style="addr" wordWrap="0">123 Industrial Way  ' + dot + '  Springfield, IL 62704</text>\n'
        '   <text name="a2"   x="0"  y="14" w="120" h="4" style="addr" wordWrap="0">+1 (555) 018-2245  ' + dot + '  billing@acme.example</text>\n'
        '   <text name="ti"   x="92" y="0"  w="90"  h="13" style="title" wordWrap="0">INVOICE</text>\n'
        '   <text name="ml1"  x="108" y="15" w="40" h="4" style="mlbl" wordWrap="0">INVOICE #</text>\n'
        '   <text name="mv1"  x="150" y="15" w="32" h="4" style="mval" wordWrap="0">INV-1042</text>\n'
        '   <text name="ml2"  x="108" y="20" w="40" h="4" style="mlbl" wordWrap="0">ISSUE DATE</text>\n'
        '   <text name="mv2"  x="150" y="20" w="32" h="4" style="mval" wordWrap="0">2026-07-19</text>\n'
        '   <text name="ml3"  x="108" y="25" w="40" h="4" style="mlbl" wordWrap="0">DUE DATE</text>\n'
        '   <text name="mv3"  x="150" y="25" w="32" h="4" style="mval" wordWrap="0">2026-08-18</text>\n'
        '   <text name="bt"   x="0"  y="25" w="60" h="4" style="billto" wordWrap="0">BILL TO</text>\n'
        '   <text name="c1"   x="0"  y="29.5" w="95" h="4.5" style="cust" wordWrap="0">Globex Manufacturing Co.</text>\n'
        '   <text name="c2"   x="0"  y="33.5" w="95" h="4" style="addr" wordWrap="0">500 Commerce Blvd, Metropolis, NY 10001</text>\n'
        '   <line name="rht" orient="h" scope="section" vAlign="top"    width="0.3" color="' + HAIR + '"/>\n'
        '   <line name="rhb" orient="h" scope="section" vAlign="bottom" width="1.1" color="' + NAVY + '"/>\n'
        '  </band>\n'
        # ============ COLUMN CAPTIONS (navy bar) ============
        '  <band kind="pageheader" name="ph" height="8">\n'
        '   <shape name="bar" x="0" y="0" w="182" h="8" shape="0" backColor="' + NAVY + '"/>\n'
        '   <text name="hI" x="3"   y="2" w="88" h="5" style="colh"  wordWrap="0">DESCRIPTION</text>\n'
        '   <text name="hQ" x="97"  y="2" w="16" h="5" style="colhr" wordWrap="0">QTY</text>\n'
        '   <text name="hP" x="119" y="2" w="26" h="5" style="colhr" wordWrap="0">UNIT PRICE</text>\n'
        '   <text name="hA" x="151" y="2" w="29" h="5" style="colhr" wordWrap="0">AMOUNT</text>\n'
        + col_grid("phg") +
        ' </band>\n'
        # ============ DETAIL ROWS ============
        '  <band kind="detail" name="det" height="7" data="d">\n'
        '   <shape name="zebra" x="0" y="0" w="182" h="7" shape="0" backColor="' + SHADE + '" visible="RowNum % 2 = 0"/>\n'
        '   <text name="dI" x="3"   y="1.6" w="90" h="4" style="cell"  wordWrap="0">{{Item}}</text>\n'
        '   <text name="dQ" x="97"  y="1.6" w="16" h="4" style="cellr" wordWrap="0">{{Qty}}</text>\n'
        '   <text name="dP" x="119" y="1.6" w="26" h="4" style="cellr" wordWrap="0">{{expr: FORMATNUM(\'#,##0.00\', Price)}}</text>\n'
        '   <text name="dA" x="151" y="1.6" w="29" h="4" style="cellr" wordWrap="0">{{expr: FORMATNUM(\'#,##0.00\', Qty*Price)}}</text>\n'
        + col_grid("dg") +
        '   <line name="drb" orient="h" scope="section" vAlign="bottom" width="0.2" color="' + HAIR + '"/>\n'
        '  </band>\n'
        # ============ SUMMARY ============
        '  <band kind="summary" name="sm" height="46">\n'
        '   <line name="stop" orient="h" scope="section" vAlign="top" width="0.6" color="' + NAVY + '"/>\n'
        '   <text name="nh" x="0" y="4"  w="95" h="4" style="billto" wordWrap="0">NOTES</text>\n'
        '   <text name="n1" x="0" y="8.5" w="100" h="4" style="note" wordWrap="0">Payment due within 30 days. Bank transfer to</text>\n'
        '   <text name="n2" x="0" y="12"  w="100" h="4" style="note" wordWrap="0">ACME Corp ' + dot + ' IBAN GB00 ACME 0000 1042 ' + dot + ' Ref INV-1042.</text>\n'
        '   <text name="s1l" x="100" y="4"  w="45" h="4.5" style="tlbl" wordWrap="0">Subtotal</text>\n'
        '   <text name="s1v" x="149" y="4"  w="31" h="4.5" style="tval" wordWrap="0">{{expr: FORMATNUM(\'#,##0.00\', SUM(Qty*Price))}}</text>\n'
        '   <text name="s2l" x="100" y="9.5" w="45" h="4.5" style="tlbl" wordWrap="0">Tax (8.5%)</text>\n'
        '   <text name="s2v" x="149" y="9.5" w="31" h="4.5" style="tval" wordWrap="0">{{expr: FORMATNUM(\'#,##0.00\', SUM(Qty*Price)*0.085)}}</text>\n'
        '   <shape name="gbar" x="100" y="16" w="82" h="10" shape="0" backColor="' + NAVY + '"/>\n'
        '   <text name="gl" x="104" y="18.5" w="40" h="6" style="glbl" wordWrap="0">TOTAL</text>\n'
        '   <text name="gv" x="149" y="18.5" w="29" h="6" style="gval" wordWrap="0">{{expr: FORMATNUM(\'#,##0.00\', SUM(Qty*Price)*1.085)}}</text>\n'
        '   <text name="gc" x="100" y="28" w="82" h="4" style="footr" wordWrap="0">USD ' + dot + ' Total items {{expr: COUNT()}}</text>\n'
        '  </band>\n'
        # ============ PAGE FOOTER ============
        '  <band kind="pagefooter" name="pf" height="12">\n'
        '   <line name="pft" orient="h" scope="section" vAlign="top" width="0.3" color="' + GRID + '"/>\n'
        '   <text name="ty" x="0"   y="3" w="120" h="4" style="foot"  wordWrap="0">Thank you for your business.  Questions? billing@acme.example</text>\n'
        '   <text name="pg" x="120" y="3" w="62"  h="4" style="footr" wordWrap="0">Page {{var:PageNo}} of {{var:TotalPages}}</text>\n'
        '  </band>\n'
        ' </bands>\n'
        '</report>\n'
    )
    return s


def export_one(job, target, path):
    if L.rptExportA(job, target, path.encode('latin-1')) != 0:
        print("  wrote " + path)
    else:
        print("  EXPORT FAILED: " + path)


def main():
    pdf, eng = boot_engine()
    if not eng:
        return
    try:
        csv = os.path.join(HERE, "18_items.csv")
        write_text(csv, csv_data())
        lrpt = os.path.join(HERE, "18_invoice.lrpt")
        write_text(lrpt, build_xml(csv))

        job = L.rptOpenReportA(eng, lrpt.encode('latin-1'))
        if not job:
            print("open failed"); dump_err(eng); return
        try:
            if L.rptRender(job) == 0:
                print("render failed"); dump_err(eng); return
            print("rendered %d page(s); exporting:" % L.rptGetPageCount(job))
            export_one(job, L.RPT_EXP_PDF, os.path.join(HERE, "18_invoice.pdf"))
            export_one(job, L.RPT_EXP_HTML, os.path.join(HERE, "18_invoice.html"))
            export_one(job, L.RPT_EXP_SVG, os.path.join(HERE, "18_invoice.svg"))
            export_one(job, L.RPT_EXP_TEXT, os.path.join(HERE, "18_invoice.txt"))
            export_one(job, L.RPT_EXP_CSV, os.path.join(HERE, "18_invoice.csv"))
            export_one(job, L.RPT_EXP_XLSX, os.path.join(HERE, "18_invoice.xlsx"))
            export_one(job, L.RPT_EXP_XLS, os.path.join(HERE, "18_invoice.xls"))
        finally:
            L.rptCloseReport(job)
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

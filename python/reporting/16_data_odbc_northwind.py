# ============================================================================
#  LumasReport example 16 -- ODBC data provider over the real Northwind.mdb
#  Covers: the "odbc" data provider, a live DB connection + JOIN + ORDER BY,
#  grouping (groupheader/groupfooter over a DB column), field interpolation.
#  This is x64 Python, so it uses the 64-bit ACE driver
#  "Microsoft Access Driver (*.mdb, *.accdb)" (the VB6 32-bit build used the
#  legacy Jet "(*.mdb)" driver).
# ============================================================================
import sys, os, ctypes
import os, sys


def _here(name):
    """A fixture that ships with the examples, found without a
    hard-coded path: walk up looking for test_files/."""
    d = os.path.dirname(os.path.abspath(__file__))
    for _ in range(6):
        c = os.path.join(d, 'test_files', name)
        if os.path.isfile(c):
            return c
        d = os.path.dirname(d)
    return name

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

MDB = _here('Northwind.mdb')


def build_xml():
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<report name="Northwind" tagLangVersion="1">\n'
        ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>\n'
        ' <datasources>\n'
        '  <datasource alias="d" provider="odbc"\n'
        # x64 Python -> use the 64-bit ACE driver that reads .mdb/.accdb.
        '    conn="Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=' + MDB + ';"\n'
        '    query="SELECT c.CategoryName, p.ProductName, p.UnitPrice, p.UnitsInStock FROM Categories c INNER JOIN Products p ON c.CategoryID = p.CategoryID ORDER BY c.CategoryName, p.ProductName"/>\n'
        ' </datasources>\n'
        ' <bands>\n'
        '  <band kind="reportheader" name="rh" height="14">\n'
        '   <text name="t" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center" wordWrap="0">Northwind Product Catalog</text>\n'
        '  </band>\n'
        '  <band kind="pageheader" name="ph" height="8">\n'
        '   <text name="c1" x="0"   y="0" w="110" h="5" fontSize="9" bold="1" wordWrap="0">Product</text>\n'
        '   <text name="c2" x="120" y="0" w="30"  h="5" fontSize="9" bold="1" hAlign="right" wordWrap="0">Price</text>\n'
        '   <text name="c3" x="152" y="0" w="28"  h="5" fontSize="9" bold="1" hAlign="right" wordWrap="0">Stock</text>\n'
        '  </band>\n'
        '  <band kind="groupheader" name="gh" group="d.CategoryName" height="8">\n'
        '   <text name="g" x="0" y="1" w="180" h="6" fontSize="12" bold="1" wordWrap="0">{{expr: d.CategoryName}}</text>\n'
        '  </band>\n'
        '  <band kind="detail" name="det" height="6" data="d">\n'
        '   <text name="p"  x="4"   y="0" w="110" h="5" fontSize="9" wordWrap="0">{{ProductName}}</text>\n'
        '   <text name="pr" x="120" y="0" w="30"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{expr: FORMATNUM(\'#,##0.00\', UnitPrice) }}</text>\n'
        '   <text name="sk" x="152" y="0" w="28"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{UnitsInStock}}</text>\n'
        '  </band>\n'
        '  <band kind="groupfooter" name="gf" group="d.CategoryName" height="4">\n'
        '   <text name="ge" x="4" y="0" w="176" h="4" fontSize="7" wordWrap="0">-- end of {{expr: d.CategoryName}} --</text>\n'
        '  </band>\n'
        '  <band kind="pagefooter" name="pf" height="6">\n'
        '   <text name="f" x="0" y="0" w="180" h="5" fontSize="7" hAlign="right" wordWrap="0">printed {{expr: FORMATDATE(\'yyyy-mm-dd\', TODAY()) }}</text>\n'
        '  </band>\n'
        ' </bands>\n'
        '</report>\n'
    )


def main():
    if not os.path.exists(MDB):
        print("Northwind.mdb not found: " + MDB); return
    pdf, eng = boot_engine()
    if not eng:
        return
    try:
        lrpt = os.path.join(HERE, "16_northwind.lrpt")
        out_pdf = os.path.join(HERE, "16_northwind.pdf")
        out_txt = os.path.join(HERE, "16_northwind.txt")
        write_text(lrpt, build_xml())

        job = L.rptOpenReportA(eng, lrpt.encode('latin-1'))
        if not job:
            print("open failed"); dump_err(eng); return
        try:
            if L.rptRender(job) == 0:
                print("render failed"); dump_err(eng); return
            print("rendered %d page(s) from Northwind.mdb (odbc)" % L.rptGetPageCount(job))
            if L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1')) == 0:
                print("pdf export failed"); dump_err(eng); return
            if L.rptExportA(job, L.RPT_EXP_TEXT, out_txt.encode('latin-1')) == 0:
                print("text export failed"); dump_err(eng); return
            print("wrote %s  +  %s" % (out_pdf, out_txt))
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

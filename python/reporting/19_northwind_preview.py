# ============================================================================
#  LumasReport example 19 -- Build a .lrpt STEP-BY-STEP, bind it to the real
#  Northwind.mdb, render + export.  (Python port)
#
#  This is the "teaching" example: it assembles the .lrpt one labelled block at
#  a time (STEP 1..14) the way the engine reads it -- top to bottom -- then does
#  the four things every LumasReport job does:
#      boot engine -> rptOpenReport -> rptRender -> rptExport.
#
#  The .dpr/.bas also pops the SDK's embedded viewer via rptPreviewA which BLOCKS
#  until closed. Pass --headless / --no-preview (or set LUMAS_HEADLESS=1) to skip
#  it and run unattended; otherwise the modal viewer is shown.
#  x64 Python -> 64-bit ACE ODBC driver "(*.mdb, *.accdb)".
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


# Assemble the 14 steps into the full .lrpt markup, in document order.
def build_report_xml():
    s = ""
    # STEP 1 + 2  <report> + <page>
    s += '<?xml version="1.0" encoding="UTF-8"?>\n'
    s += '<report name="Northwind Catalog" tagLangVersion="1">\n'
    s += '  <page width="210" height="297" marginLeft="15" marginTop="15"\n'
    s += '        marginRight="15" marginBottom="15"/>\n'
    # STEP 3  <datasources> -> Northwind.mdb (odbc, 64-bit ACE driver)
    s += '  <datasources>\n'
    s += '    <datasource alias="d" provider="odbc"\n'
    s += '      conn="Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=' + MDB + ';"\n'
    s += '      query="SELECT c.CategoryName, p.ProductName, p.QuantityPerUnit,\n'
    s += '                    p.UnitPrice, p.UnitsInStock\n'
    s += '             FROM Categories c INNER JOIN Products p\n'
    s += '               ON c.CategoryID = p.CategoryID\n'
    s += '             ORDER BY c.CategoryName, p.ProductName"/>\n'
    s += '  </datasources>\n'
    # STEP 4  <params>
    s += '  <params>\n'
    s += '    <param name="Title"   default="\'Northwind Product Catalog\'"/>\n'
    s += '    <param name="Company" default="\'LumasPDF Trading Co.\'"/>\n'
    s += '  </params>\n'
    # STEP 5 + 6  <styles> + open <bands>
    s += '  <styles>\n'
    s += '    <style name="Bar"     backColor="005F3A1F" borderWidth="0"/>\n'
    s += '    <style name="GrpBar"  backColor="002A170F" borderWidth="0"/>\n'
    s += '    <style name="Title"   fontName="Helvetica" fontSize="22" bold="1" textColor="00FFFFFF" vAlign="1"/>\n'
    s += '    <style name="Sub"     fontName="Helvetica" fontSize="9"  textColor="00FFFFFF" hAlign="2" vAlign="1"/>\n'
    s += '    <style name="ColH"    fontName="Helvetica" fontSize="8"  bold="1" textColor="00FFFFFF" vAlign="1"/>\n'
    s += '    <style name="ColHR"   fontName="Helvetica" fontSize="8"  bold="1" textColor="00FFFFFF" hAlign="2" vAlign="1"/>\n'
    s += '    <style name="Grp"     fontName="Helvetica" fontSize="12" bold="1" textColor="00FFFFFF" vAlign="1"/>\n'
    s += '    <style name="Cell"    fontName="Helvetica" fontSize="9"  textColor="002A170F" vAlign="1"/>\n'
    s += '    <style name="CellR"   fontName="Helvetica" fontSize="9"  textColor="002A170F" hAlign="2" vAlign="1"/>\n'
    s += '    <style name="Muted"   fontName="Helvetica" fontSize="8"  textColor="008B7464" vAlign="1"/>\n'
    s += '    <style name="Sub L"   fontName="Helvetica" fontSize="8.5" bold="1" textColor="005F3A1F"/>\n'
    s += '    <style name="SubR"    fontName="Helvetica" fontSize="8.5" bold="1" textColor="005F3A1F" hAlign="2"/>\n'
    s += '    <style name="GTotL"   fontName="Helvetica" fontSize="11" bold="1" textColor="00FFFFFF"/>\n'
    s += '    <style name="GTotR"   fontName="Helvetica" fontSize="11" bold="1" textColor="00FFFFFF" hAlign="2"/>\n'
    s += '    <style name="Foot"    fontName="Helvetica" fontSize="7.5" textColor="008B7464"/>\n'
    s += '    <style name="FootR"   fontName="Helvetica" fontSize="7.5" textColor="008B7464" hAlign="2"/>\n'
    s += '  </styles>\n'
    s += '  <bands>\n'
    # STEP 7  reportheader
    s += '    <band kind="reportheader" name="rh" height="26">\n'
    s += '      <shape name="hbar"  x="0" y="0" w="180" h="18" style="Bar" shape="0"/>\n'
    s += '      <text  name="ttl"   x="5"  y="1"  w="120" h="10" style="Title" wordWrap="0">{{var:Title}}</text>\n'
    s += '      <text  name="sub"   x="95" y="6"  w="80"  h="6"  style="Sub"   wordWrap="0">{{var:Company}}</text>\n'
    s += '      <text  name="asof"  x="0"  y="20" w="180" h="4"  style="Muted" wordWrap="0">Generated {{expr: FORMATDATE(\'yyyy-mm-dd\', TODAY()) }} from Northwind.mdb (live ODBC)</text>\n'
    s += '    </band>\n'
    # STEP 8  pageheader
    s += '    <band kind="pageheader" name="ph" height="8">\n'
    s += '      <shape name="cbar" x="0" y="0" w="180" h="7" style="GrpBar" shape="0"/>\n'
    s += '      <text name="hP"  x="3"   y="1.5" w="64" h="4" style="ColH"  wordWrap="0">PRODUCT</text>\n'
    s += '      <text name="hK"  x="69"  y="1.5" w="44" h="4" style="ColH"  wordWrap="0">PACK</text>\n'
    s += '      <text name="hU"  x="114" y="1.5" w="21" h="4" style="ColHR" wordWrap="0">PRICE</text>\n'
    s += '      <text name="hS"  x="137" y="1.5" w="18" h="4" style="ColHR" wordWrap="0">STOCK</text>\n'
    s += '      <text name="hV"  x="157" y="1.5" w="20" h="4" style="ColHR" wordWrap="0">VALUE</text>\n'
    s += '    </band>\n'
    # STEP 9  groupheader
    s += '    <band kind="groupheader" name="gh" group="d.CategoryName" height="9">\n'
    s += '      <shape name="gbar" x="0" y="1" w="180" h="7" style="GrpBar" shape="0"/>\n'
    s += '      <text  name="gname" x="4" y="1.7" w="140" h="5" style="Grp" wordWrap="0">{{expr: d.CategoryName}}</text>\n'
    s += '    </band>\n'
    # STEP 10  detail
    s += '    <band kind="detail" name="det" height="6" data="d">\n'
    s += '      <shape name="zebra" x="0" y="0" w="180" h="6" shape="0" backColor="00F9F5F1" visible="RowNum % 2 = 0"/>\n'
    s += '      <text name="cP" x="3"   y="1" w="64" h="4" style="Cell"  wordWrap="0">{{ProductName}}</text>\n'
    s += '      <text name="cK" x="69"  y="1" w="44" h="4" style="Muted" wordWrap="0">{{QuantityPerUnit}}</text>\n'
    s += '      <text name="cU" x="114" y="1" w="21" h="4" style="CellR" wordWrap="0">{{expr: FORMATNUM(\'#,##0.00\', UnitPrice) }}</text>\n'
    s += '      <text name="cS" x="137" y="1" w="18" h="4" style="CellR" wordWrap="0">{{UnitsInStock}}</text>\n'
    s += '      <text name="cV" x="157" y="1" w="20" h="4" style="CellR" wordWrap="0">{{expr: FORMATNUM(\'#,##0\', UnitPrice*UnitsInStock) }}</text>\n'
    s += '      <line name="drow" orient="h" scope="section" vAlign="bottom" width="0.15" color="00E2D8CE"/>\n'
    s += '    </band>\n'
    # STEP 11  groupfooter
    s += '    <band kind="groupfooter" name="gf" group="d.CategoryName" height="7">\n'
    s += '      <line name="gtop" orient="h" scope="section" vAlign="top" width="0.4" color="005F3A1F"/>\n'
    s += '      <text name="sl" x="3"   y="1.5" w="110" h="4" style="Sub L" wordWrap="0">Subtotal -- {{expr: d.CategoryName}} ({{expr: COUNT()}} products)</text>\n'
    s += '      <text name="sv" x="137" y="1.5" w="40"  h="4" style="SubR"  wordWrap="0">{{expr: FORMATNUM(\'#,##0\', SUM(UnitPrice*UnitsInStock)) }}</text>\n'
    s += '    </band>\n'
    # STEP 12  summary
    s += '    <band kind="summary" name="sm" height="16">\n'
    s += '      <shape name="tbar" x="0" y="2" w="180" h="10" style="Bar" shape="0"/>\n'
    s += '      <text name="gl" x="4"   y="4.2" w="120" h="6" style="GTotL" wordWrap="0">GRAND TOTAL -- {{expr: COUNT()}} products in {{expr: COUNTDISTINCT(d.CategoryName)}} categories</text>\n'
    s += '      <text name="gv" x="120" y="4.2" w="56"  h="6" style="GTotR" wordWrap="0">{{expr: FORMATNUM(\'#,##0\', SUM(UnitPrice*UnitsInStock)) }}</text>\n'
    s += '    </band>\n'
    # STEP 13  pagefooter
    s += '    <band kind="pagefooter" name="pf" height="9">\n'
    s += '      <line name="ft" orient="h" scope="section" vAlign="top" width="0.3" color="00B9B9B9"/>\n'
    s += '      <text name="fl" x="0"   y="2.5" w="120" h="4" style="Foot"  wordWrap="0">{{var:Company}} -- confidential</text>\n'
    s += '      <text name="fr" x="120" y="2.5" w="57"  h="4" style="FootR" wordWrap="0">Page {{var:PageNo}} of {{var:TotalPages}}</text>\n'
    s += '    </band>\n'
    # STEP 14  close </bands></report>
    s += '  </bands>\n'
    s += '</report>\n'
    return s


def is_headless():
    c = " ".join(sys.argv[1:]).lower()
    if ("--headless" in c) or ("--no-preview" in c) or ("/headless" in c):
        return True
    return os.environ.get("LUMAS_HEADLESS", "") not in ("", "0")


def main():
    if not os.path.exists(MDB):
        print("Northwind.mdb not found: " + MDB); return
    pdf, eng = boot_engine()
    if not eng:
        return
    try:
        lrpt = os.path.join(HERE, "19_northwind.lrpt")
        out_pdf = os.path.join(HERE, "19_northwind.pdf")
        out_txt = os.path.join(HERE, "19_northwind.txt")

        xml = build_report_xml()
        write_text(lrpt, xml)
        print("STEP 1-14: wrote %s (%d bytes)" % (lrpt, len(xml)))

        job = L.rptOpenReportA(eng, lrpt.encode('latin-1'))
        if not job:
            print("open failed"); dump_err(eng); return

        pages = 0
        try:
            L.rptSetParamStr(job, b"Title", b"Northwind Product Catalog")
            L.rptSetParamStr(job, b"Company", b"LumasPDF Trading Co.")

            if L.rptRender(job) == 0:
                print("render failed"); dump_err(eng); return
            pages = L.rptGetPageCount(job)
            print("RENDER: %d page(s) bound from Northwind.mdb" % pages)

            if L.rptExportA(job, L.RPT_EXP_PDF, out_pdf.encode('latin-1')) == 0:
                print("pdf export failed"); dump_err(eng); return
            if L.rptExportA(job, L.RPT_EXP_TEXT, out_txt.encode('latin-1')) == 0:
                print("text export failed"); dump_err(eng); return
            print("EXPORT: %s  +  %s" % (out_pdf, out_txt))

            # -- *** EMBEDDED PREVIEW *** ------------------------------------
            #  rptPreviewA opens the SDK's built-in viewer window; it BLOCKS
            #  until the window is closed. Skipped under --headless.
            if is_headless():
                print("PREVIEW: skipped (--headless). Open %s to view." % out_pdf)
            else:
                print("PREVIEW: opening the embedded viewer -- close the window to continue...")
                if L.rptPreviewA(job, b"Northwind Product Catalog") == 0:
                    print("  preview failed (continuing -- not fatal):")
                    dump_err(eng)
        finally:
            L.rptCloseReport(job)

        if os.path.exists(out_pdf) and pages >= 1:
            print("OK: %s exists, %d page(s)." % (out_pdf, pages))
        else:
            print("VERIFY FAILED: PDF missing or zero pages")
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

# ============================================================================
#  07_table_layout -- Python (ctypes) port of
#  examples\delphi\xfa\07_table_layout\07_table_layout.dpr
#
#  LumasPDF XFA "flavor tour" example 7/10 -- TABLE LAYOUT. Demonstrates
#  layout="table": "ProductTable" is a 4-column (Product/Price/Stock/Rating)
#  subform with columnWidths="216pt 108pt 108pt 108pt" and 6 layout="row"
#  children (1 header + 5 data rows), each column authoring a different
#  <para hAlign> (Product=left, Price=right, Stock=center, Rating=right).
#
#    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
#    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
#
#  Packets are read pre-split from their own .template.xml/.datasets.xml
#  files -- no XML library needed in this driver.
# ============================================================================
import os
import sys
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


def render(template_path, datasets_path, out_pdf_path):
    template = open(template_path, "rb").read()
    datasets = open(datasets_path, "rb").read()
    print("template packet bytes:", len(template))
    print("datasets packet bytes:", len(datasets))

    pdf = L.pdfNewPDF()
    if not pdf:
        print("pdfNewPDF FAILED")
        return -100
    try:
        if L.pdfCreateNewPDFA(pdf, out_pdf_path.encode("latin-1")) == 0:
            print("pdfCreateNewPDFA FAILED")
            return -100

        idx = L.pdfCreateXFAStreamA(pdf, b"template", template, len(template))
        print("pdfCreateXFAStreamA(template) -> index", idx)
        if idx < 0:
            print("pdfCreateXFAStreamA(template) FAILED")
            return -100

        idx = L.pdfCreateXFAStreamA(pdf, b"datasets", datasets, len(datasets))
        print("pdfCreateXFAStreamA(datasets) -> index", idx)
        if idx < 0:
            print("pdfCreateXFAStreamA(datasets) FAILED")
            return -100

        rc = L.pdfRenderXFAForm(pdf)
        print("pdfRenderXFAForm ->", rc)
        if rc < 1:
            print("pdfRenderXFAForm FAILED, code", rc)
            return rc

        if L.pdfCloseFile(pdf) == 0:
            print("pdfCloseFile FAILED")
            return -101

        print("OK: wrote", out_pdf_path)
        return rc
    finally:
        L.pdfDeletePDF(pdf)


def main():
    template_path = os.path.join(HERE, "07_table_layout.template.xml")
    datasets_path = os.path.join(HERE, "07_table_layout.datasets.xml")
    out_pdf_path = os.path.join(HERE, "07_table_layout.pdf")

    print("=== 07_table_layout -> 07_table_layout.pdf ===")
    rc = render(template_path, datasets_path, out_pdf_path)
    print("RESULT|07_table_layout=", rc)

    print()
    print("Expected table geometry (hand-derived, verified against the rendered")
    print("PDF content stream Tj operators via pypdf in the Delphi flavor's README):")
    print("  6 rows stacked tb-style, h=20pt each, zero gap: y = 688,668,648,628,608,588")
    print("  col1 Product (hAlign=left)   -- every row's text starts at x=39 (flush-left)")
    print("  col2 Price   (hAlign=right)  -- every row's text ENDS at x=356.99 (right-aligned)")
    print("  col3 Stock   (hAlign=center) -- every row's text centered on x=414")
    print("  col4 Rating  (hAlign=right)  -- every row's text ENDS at x=573.0 (right-aligned)")


if __name__ == "__main__":
    main()

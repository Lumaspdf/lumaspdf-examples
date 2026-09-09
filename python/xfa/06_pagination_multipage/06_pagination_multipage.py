# ============================================================================
#  06_pagination_multipage -- Python (ctypes) port of
#  examples\delphi\xfa\06_pagination_multipage\06_pagination_multipage.dpr
#
#  LumasPDF XFA dynamic engine "flavor tour" example 6 of 10 --
#  MULTI-PAGE PAGINATION: pageSet/pageArea/contentArea, forced overflow of a
#  70-row "Invoice Line Items" table across several pages, leader/trailer
#  "continued" banner subforms via <overflow leader=... trailer=...>.
#
#    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
#    pdfCreateXFAStreamA('datasets',...) -> pdfXFAFormPageCount (pre-flight)
#    -> pdfRenderXFAForm -> pdfCloseFile
#
#  CheckPageCount=4: hand-derived in the Delphi flavor's README.md from this
#  fixture's own geometry (contentArea 400pt tall, row/leader/trailer h=20pt
#  each, 70 <Line> records) using the engine's real pagination algorithm
#  (trailer height reserved on every page unconditionally; leader height
#  reserved on every page except the first). This driver calls
#  pdfXFAFormPageCount BEFORE pdfRenderXFAForm and asserts the two agree.
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

CHECK_PAGE_COUNT = 4


def render(template_path, datasets_path, out_pdf_path, check_page_count):
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

        pre = L.pdfXFAFormPageCount(pdf)
        print("pdfXFAFormPageCount (pre-flight, before any AppendPage) ->", pre)
        if pre != check_page_count:
            print(f"PAGECOUNT-MISMATCH: expected {check_page_count} got {pre}")
            return -102

        rc = L.pdfRenderXFAForm(pdf)
        print("pdfRenderXFAForm ->", rc)
        if rc < 0:
            print("pdfRenderXFAForm FAILED, code", rc)
            return rc
        if rc != check_page_count:
            print(f"RENDER-PAGECOUNT-MISMATCH: pre-flight said {check_page_count} but render produced {rc}")
            return -103

        if L.pdfCloseFile(pdf) == 0:
            print("pdfCloseFile FAILED")
            return -101

        print("OK: wrote", out_pdf_path)
        return rc
    finally:
        L.pdfDeletePDF(pdf)


def main():
    template_path = os.path.join(HERE, "06_pagination_multipage.template.xml")
    datasets_path = os.path.join(HERE, "06_pagination_multipage.datasets.xml")
    out_pdf_path = os.path.join(HERE, "06_pagination_multipage.pdf")

    print("=== 06_pagination_multipage -> 06_pagination_multipage.pdf ===")
    rc = render(template_path, datasets_path, out_pdf_path, CHECK_PAGE_COUNT)
    print("RESULT|06_pagination_multipage=", rc)

    print()
    print("Expected page-by-page layout (hand-derived, verified against the")
    print("Delphi flavor's content-stream inspection via pypdf):")
    print("  page 1: header yes, leader no,  trailer yes, 19 Description rows (1-19)")
    print("  page 2: header no,  leader yes, trailer yes, 18 Description rows (20-37)")
    print("  page 3: header no,  leader yes, trailer yes, 18 Description rows (38-55)")
    print("  page 4: header no,  leader yes, trailer no,  15 Description rows (56-70)")
    print("  19 + 18 + 18 + 15 = 70 total line items, matching the 70 authored records.")


if __name__ == "__main__":
    main()

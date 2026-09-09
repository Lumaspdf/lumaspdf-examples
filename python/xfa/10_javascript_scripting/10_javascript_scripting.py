# ============================================================================
#  10_javascript_scripting -- Python (ctypes) port of
#  examples\delphi\xfa\10_javascript_scripting\10_javascript_scripting.dpr
#
#  XFA "flavor tour" example 10 of 10 -- JS-as-XFA-script. Demonstrates
#  <script contentType="application/x-javascript"> calculate scripts --
#  the last piece of the XFA dynamic-form engine, wired minimally and
#  XFA-only (this.rawValue getter/setter + xfa.resolveNode(path).rawValue,
#  via BESEN on this engine). Same pdfRenderXFAForm pipeline FormCalc
#  already uses, via the existing IXfaScriptHost seam -- no new export
#  needed.
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
        print("pdfRenderXFAForm ->", rc, "(expected: page count >= 1)")
        if rc < 1:
            print("RENDER-FAILED, code", rc)
            return rc

        if L.pdfCloseFile(pdf) == 0:
            print("pdfCloseFile FAILED")
            return -101

        print(f"Wrote {out_pdf_path} ({rc} page(s))")
        return rc
    finally:
        L.pdfDeletePDF(pdf)


def main():
    template_path = os.path.join(HERE, "10_javascript_scripting.template.xml")
    datasets_path = os.path.join(HERE, "10_javascript_scripting.datasets.xml")
    out_pdf_path = os.path.join(HERE, "output.pdf")

    print("=== 10_javascript_scripting -> output.pdf ===")
    rc = render(template_path, datasets_path, out_pdf_path)

    if rc >= 1:
        print(f"OK: JavaScript-scripted form rendered, {rc} page(s). Open output.pdf and confirm:")
    else:
        print("FAILED, see errors above.")
    print("  - UnitPriceWithTax  ~= 21.59  (19.99 * 1.08)")
    print('  - OrderSummary      = "Purchase Order PO-1042 for Acme Robotics"')
    print("  - 3 Line rows, Total = Qty*UnitCost per row (50.00 / 90.00 / 89.75)")
    print("  If any of these are wrong or missing, the JS bridge contract in the .xdp")
    print("  needs adjusting to match the FINAL implementation -- see the .xdp header comment.")


if __name__ == "__main__":
    main()

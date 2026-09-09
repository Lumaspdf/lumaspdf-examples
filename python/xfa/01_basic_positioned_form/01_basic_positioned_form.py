# ============================================================================
#  01_basic_positioned_form -- Python (ctypes) port of
#  examples\delphi\xfa\01_basic_positioned_form\01_basic_positioned_form.dpr
#
#  "Flavor tour" example 1 of 10: POSITIONED LAYOUT -- static field
#  positioning, no flow/occur/pagination. Renders a single-page "Employee
#  Information" HR record (masthead, five statically placed/data-bound
#  fields, a photo-placeholder box) through the real LumasPdf.dll:
#
#    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
#    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
#
#  The Delphi driver parses the combined .xdp and splits it into
#  <template>/<datasets> packets at run time. This Python port instead reads
#  the two packets pre-split into their own files (this session's one-off
#  split_xfa_packets tool already extracted them next to the Delphi .xdp) --
#  no XML library needed here, just two raw-byte file reads.
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
    template_path = os.path.join(HERE, "01_basic_positioned_form.template.xml")
    datasets_path = os.path.join(HERE, "01_basic_positioned_form.datasets.xml")
    out_pdf_path = os.path.join(HERE, "output.pdf")

    print("=== 01_basic_positioned_form -> output.pdf ===")
    rc = render(template_path, datasets_path, out_pdf_path)
    print("RESULT|01_basic_positioned_form=", rc)

    print()
    print("Expect a single page with these statically positioned/bound fields:")
    print('  Full Name:    "Sarah J. Connor"')
    print('  Employee ID:  "EMP-10457"')
    print('  Department:   "Engineering"')
    print('  Hire Date:    "2021-03-15"')
    print('  Full-time employee checkbox + "Employee Photo" placeholder box')


if __name__ == "__main__":
    main()

# ============================================================================
#  02_data_binding -- Python (ctypes) port of
#  examples\delphi\xfa\02_data_binding\02_data_binding.dpr
#
#  LumasPDF XFA "flavor tour" example 2 of 10 -- DATA BINDING. Demonstrates
#  the three binding modes an XFA form mixes in practice, all against one
#  realistic, genuinely nested <xfa:datasets> packet:
#    1. Implicit binding (by-name, no <bind> element, containment-aware).
#    2. Explicit <bind match="dataRef" ref="$data...."/> against a nested
#       SOM path (3 and 4 levels deep).
#    3. <bind match="none"/> -- pure literal, unaffected by same-named data.
#
#    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
#    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
#
#  Packets are read pre-split from their own .template.xml/.datasets.xml
#  files (extracted from the combined .xdp by this session's one-off
#  split_xfa_packets tool) -- no XML library needed in this driver.
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
    print("LumasPDF XFA flavor tour -- example 2/10: Data Binding")
    print("(implicit by-name + explicit dataRef SOM path + match=none literal)")
    print()

    template_path = os.path.join(HERE, "02_data_binding.template.xml")
    datasets_path = os.path.join(HERE, "02_data_binding.datasets.xml")
    out_pdf_path = os.path.join(HERE, "02_data_binding.render.pdf")

    print("=== 02_data_binding -> 02_data_binding.render.pdf ===")
    rc = render(template_path, datasets_path, out_pdf_path)
    print()
    print("RESULT|02_data_binding=", rc)

    print()
    print("Expected resolved values (checked against the rendered PDF page 1")
    print("content stream via pypdf -- adjacent Tj caption/value pairs):")
    print('  Customer Name (implicit)              : "Acme Robotics LLC"')
    print('  Account ID (implicit)                  : "ACCT-88213"')
    print('  Street (implicit, nested subform)      : "500 Innovation Way"')
    print('  State (implicit, nested subform)       : "IL"')
    print('  Zip (implicit, nested subform)         : "62704"')
    print('  Shipping City (explicit dataRef, 3 deep): "Springfield"')
    print('  Primary Contact Email (dataRef, 4 deep) : "ap@acmerobotics.example"')
    print('  Status (match="none", literal)          : "Active - Verified"')
    print('    (NOT "PENDING_CLOSURE", the same-named trap node in datasets)')


if __name__ == "__main__":
    main()

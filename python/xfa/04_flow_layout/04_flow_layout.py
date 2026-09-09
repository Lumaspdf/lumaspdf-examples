# ============================================================================
#  04_flow_layout -- Python (ctypes) port of
#  examples\delphi\xfa\04_flow_layout\04_flow_layout.dpr
#
#  LumasPDF XFA dynamic engine "flavor tour" example 4 of 10 -- FLOW LAYOUT
#  (layout="tb" vertical stacking + layout="lr-tb" left-to-right wrapping).
#  Renders a one-page "Employment Application" with two sibling flowed
#  subforms: TermsPanel (layout="tb", 6 clauses stacked with zero gap) and
#  SkillsPanel (layout="lr-tb", 9 tags wrapping across lines).
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
    template_path = os.path.join(HERE, "04_flow_layout.template.xml")
    datasets_path = os.path.join(HERE, "04_flow_layout.datasets.xml")
    out_pdf_path = os.path.join(HERE, "04_flow_layout.pdf")

    print("=== 04_flow_layout -> 04_flow_layout.pdf ===")
    rc = render(template_path, datasets_path, out_pdf_path)
    print("RESULT|04_flow_layout=", rc)

    print()
    print("Expected layout geometry (hand-derived, verified against the engine's")
    print("own xfa_layout_dump.exe self-oracle in the Delphi flavor's README):")
    print("  TermsPanel (tb, x=36 y=92 w=540, child h=24, gap=0):")
    print("    Clause1..6 y = 92, 116, 140, 164, 188, 212  (curY += 24 each step)")
    print("  SkillsPanel (lr-tb, x=36 y=270 w=540, child w=110 h=20):")
    print("    line 1 (y=270): Skill1 x=36, Skill2 x=146, Skill3 x=256, Skill4 x=366")
    print("    line 2 (y=290): Skill5 x=36, Skill6 x=146, Skill7 x=256, Skill8 x=366")
    print("    line 3 (y=310): Skill9 x=36")
    print("  3 lines total (4 + 4 + 1 tags), 21 boxes total incl. form1/headers.")


if __name__ == "__main__":
    main()

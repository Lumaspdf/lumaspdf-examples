# ============================================================================
#  09_acroform_widget_synthesis -- Python (ctypes) port of
#  examples\delphi\xfa\09_acroform_widget_synthesis\09_acroform_widget_synthesis.dpr
#
#  LumasPDF XFA "flavor tour" example 9 of 10 -- ACROFORM-WIDGET SYNTHESIS.
#  Demonstrates pdfSetXFARenderMode(doc, 1): turning an XFA form into a REAL
#  fillable AcroForm PDF:
#    - textEdit / numericEdit / dateTimeEdit -> /FT Tx
#    - checkButton (standalone, or exclGroup radio group) -> /FT Btn
#    - choiceList                                         -> /FT Ch
#    - button (whole-box pushbutton, real bevel /AP)       -> /FT Btn
#    - imageEdit is NOT synthesized by design (no native fillable image
#      field type in ISO 32000-1) -- this example does not use one.
#
#  Renders the SAME .xdp packets TWICE through the real-DLL export sequence:
#
#    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
#    pdfCreateXFAStreamA('datasets',...) -> [pdfSetXFARenderMode(doc,1) only
#    for the second pass] -> pdfRenderXFAForm -> pdfCloseFile
#
#      mode0.pdf -- Mode 0 (default): flattened ink only, no /AcroForm.
#      mode1.pdf -- Mode 1: flattened ink PLUS real synthesized AcroForm
#                   fillable widgets (/AcroForm/Fields).
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


def render(template_path, datasets_path, out_pdf_path, mode):
    template = open(template_path, "rb").read()
    datasets = open(datasets_path, "rb").read()
    print(f"=== {os.path.basename(template_path)} (mode={mode}) -> {os.path.basename(out_pdf_path)} ===")
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

        if mode != 0:
            prev = L.pdfSetXFARenderMode(pdf, mode)
            print(f"pdfSetXFARenderMode(pdf, {mode}) -> previous={prev} (expect 0, the default)")

        rc = L.pdfRenderXFAForm(pdf)
        print("pdfRenderXFAForm ->", rc, "(expected: page count >= 1)")
        if rc < 1:
            print("RENDER-FAILED, code", rc)
            return rc

        if L.pdfCloseFile(pdf) == 0:
            print("pdfCloseFile FAILED")
            return -101

        print(f"OK: wrote {out_pdf_path} ({rc} page(s))")
        return rc
    finally:
        L.pdfDeletePDF(pdf)


def main():
    template_path = os.path.join(HERE, "09_acroform_widget_synthesis.template.xml")
    datasets_path = os.path.join(HERE, "09_acroform_widget_synthesis.datasets.xml")

    r0 = render(template_path, datasets_path, os.path.join(HERE, "mode0.pdf"), 0)
    r1 = render(template_path, datasets_path, os.path.join(HERE, "mode1.pdf"), 1)

    print()
    print(f"RESULT|mode0={r0}|mode1={r1}")
    if r0 >= 1 and r1 >= 1:
        print("OK: both renders succeeded.")
        print("  mode0.pdf -- flattened ink only, NO /AcroForm/Fields.")
        print("  mode1.pdf -- flattened ink PLUS a REAL fillable AcroForm:")
        print("    ApplicantName (Tx), YearsExperience (Tx), ApplicationDate (Tx),")
        print("    EmploymentType (Btn radio, 3 Kids: Full-time/Part-time/Contract),")
        print("    Department (Ch combo, 6 options), SubmitButton (Btn pushbutton, real bevel /AP),")
        print("    Employer[0].EmployerName / Employer[1].EmployerName / Employer[2].EmployerName (Tx x3).")
        print("  Open mode1.pdf in a real PDF reader (Acrobat, Chrome, Edge, etc.) --")
        print("  it is a genuinely fillable form: click into the fields and type.")
        print()
        print("Expected (verified via pypdf in the Delphi flavor's README):")
        print("  mode0.pdf: /AcroForm/Fields is an EMPTY array.")
        print("  mode1.pdf: /AcroForm/Fields has exactly 9 top-level fields:")
        print('    ApplicantName /Tx  V="Jordan Rivera"')
        print('    YearsExperience /Tx  V="7"')
        print('    ApplicationDate /Tx  V="2026-07-24"')
        print('    Department /Ch  V="Engineering"  Ff=131072 (bit18 Combo)')
        print("    SubmitButton /Btn  (no /V -- pushbuttons never bind)")
        print('    Employer[0].EmployerName /Tx  V="Acme Robotics"')
        print('    Employer[1].EmployerName /Tx  V="Nimbus Data Systems"')
        print('    Employer[2].EmployerName /Tx  V="BrightPath Logistics"')
        print('    EmploymentType /Btn  Ff=32768 (bit16 Radio)  V="/Full-time", 3 Kids')
    else:
        print("FAILED, see errors above.")


if __name__ == "__main__":
    main()

# ============================================================================
#  08_picture_clause_formatting -- Python (ctypes) port of
#  examples\delphi\xfa\08_picture_clause_formatting\08_picture_clause_formatting.dpr
#
#  LumasPDF XFA dynamic engine "flavor tour" example 8 of 10 -- PICTURE-CLAUSE
#  FORMATTING. Demonstrates the <format><picture> formatter: real num{} /
#  date{} / text{} picture patterns applied both to plain bound data values
#  and to a value produced by a FormCalc <calculate> script (GrandTotalField),
#  proving the calculate-then-format pipeline order.
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

        # Phase-6 config gate defaults to enabled (FXFAScriptEnabled := True
        # in Lumas.Pdf.Document.pas's Create), but this driver sets it
        # explicitly anyway so GrandTotalField's <calculate> script is
        # guaranteed to run regardless of that default ever changing -- this
        # example's whole point is the calculate-then-format pipeline.
        prev = L.pdfSetXFAScriptEnabled(pdf, 1)
        print("pdfSetXFAScriptEnabled(1) ->", prev)

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
    template_path = os.path.join(HERE, "08_picture_clause_formatting.template.xml")
    datasets_path = os.path.join(HERE, "08_picture_clause_formatting.datasets.xml")
    out_pdf_path = os.path.join(HERE, "08_picture_clause_formatting.pdf")

    print("=== 08_picture_clause_formatting -> 08_picture_clause_formatting.pdf ===")
    rc = render(template_path, datasets_path, out_pdf_path)
    print("RESULT|08_picture_clause_formatting=", rc)

    print()
    print("Expect one page rendered; verify with any text extractor (e.g. pypdf)")
    print("-- the extracted text should read:")
    print("  Purchase Receipt -- Picture-Clause Formatting")
    print("  Customer: Acme Corp")
    print("  Unit Price: 1,875.50")
    print("  Discount: ($125.00)")
    print("  Date: July 24, 2026")
    print("  Phone: 555-123-4567")
    print("  845.25 620.00 410.25")
    print("  Grand Total: 1,875.50")
    print()
    print("  (GrandTotalField has no literal <value> -- its 1,875.50 can only come")
    print("  from the calculate script actually running, THEN the num{zzz,zz9.99}")
    print("  picture formatter being applied to that script's own result.)")


if __name__ == "__main__":
    main()

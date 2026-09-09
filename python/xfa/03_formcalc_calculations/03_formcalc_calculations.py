# ============================================================================
#  03_formcalc_calculations -- Python (ctypes) port of
#  examples\delphi\xfa\03_formcalc_calculations\03_formcalc_calculations.dpr
#
#  LumasPDF XFA "flavor tour" example 3 of 10 -- FORMCALC CALCULATIONS.
#  Demonstrates the XFA FormCalc engine (lexer -> parser -> VM -> builtin
#  catalog) end-to-end: an "Order Calculator" with a 3-line item table and a
#  calculated summary block (line totals, subtotal, average price, item
#  count, a discount tier + amount, grand total), all wired up with
#  <calculate><script contentType="application/x-formcalc"> bodies. 13
#  fields are bound to the datasets packet; 14 are calculate-only.
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
    print("LumasPDF XFA flavor tour -- example 3/10: FormCalc Calculations")
    print("(Sum/Avg/Round/Count, If, Concat/Upper/Left, Date2Num/Num2Date/DateFmt)")
    print()

    template_path = os.path.join(HERE, "03_formcalc_calculations.template.xml")
    datasets_path = os.path.join(HERE, "03_formcalc_calculations.datasets.xml")
    out_pdf_path = os.path.join(HERE, "03_formcalc_calculations.render.pdf")

    print("=== 03_formcalc_calculations -> 03_formcalc_calculations.render.pdf ===")
    rc = render(template_path, datasets_path, out_pdf_path)
    print()
    print("RESULT|03_formcalc_calculations=", rc)

    print()
    print("Dataset ($data.Order): Customer Alex Nguyen, OrderDate 'Jul 15, 2026',")
    print("DiscountThreshold 100, Item1(Widget) 3x12.50, Item2(Gadget) 2x45.00,")
    print("Item3(Gizmo) 5x8.00.")
    print()
    print("Hand-computed expected values (checked against the rendered PDF text")
    print("via pypdf/PyMuPDF in the Delphi flavor's README):")
    print("  Item1Total      = 3 x 12.50        = 37.5")
    print("  Item2Total      = 2 x 45.00         = 90")
    print("  Item3Total      = 5 x 8.00          = 40")
    print("  TotalQty        = 3+2+5             = 10")
    print("  Subtotal        = 37.5+90+40        = 167.5")
    print("  AvgUnitPrice    = round(avg,2)      = 21.83")
    print("  ItemCount       = Count(3 args)     = 3")
    print('  DiscountLabel   = 167.5>=100        = "Bulk Discount"')
    print("  DiscountAmount  = round(167.5*.10,2)= 16.75")
    print("  GrandTotal      = 167.5-16.75       = 150.75")
    print('  FullName        = Concat(...)       = "Alex Nguyen"')
    print('  CustomerInitial = Upper(Left(...))  = "A"')
    print("  OrderDateNum (displayed)             = 2026-07-15")
    print("  OrderDateFormatted = Num2Date(...)   = 7/15/26")


if __name__ == "__main__":
    main()

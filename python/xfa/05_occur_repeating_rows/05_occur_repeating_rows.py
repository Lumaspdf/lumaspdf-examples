# ============================================================================
#  05_occur_repeating_rows -- Python (ctypes) port of
#  examples\delphi\xfa\05_occur_repeating_rows\05_occur_repeating_rows.dpr
#
#  LumasPDF XFA "flavor tour" example 5 of 10 -- OCCUR/REPEAT data-driven row
#  cloning. <occur min="1" max="-1"/> instantiates one repeating template row
#  once per matching dataset record (7 <Item> records under
#  $data.ExpenseReport.Items), each instance independently bound to its own
#  record and independently re-running its own calculate script
#  (LineTotal = Qty * UnitPrice).
#
#    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
#    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm ->
#    [pdfInitStack/pdfGetPageText verification, see below] -> pdfCloseFile
#
#  VERIFICATION STRATEGY (mirrors the Delphi driver exactly): rather than
#  hand-parsing the compressed content stream, this driver uses the engine's
#  own pdfGetPageText export (looped via pdfInitStack) on the freshly
#  rendered page, BEFORE pdfCloseFile. Each field's displayed value is drawn
#  as its own text run, in template/layout traversal order, so the runs come
#  back as: [title, EmployeeName, Department, ReportDate], then
#  [Description, Qty, UnitPrice, LineTotal] x 7 rows, then [Total,
#  GrandTotal]. For every occur instance this driver locates that row's own
#  Description among the extracted runs, reads the next three runs (Qty,
#  UnitPrice, LineTotal), independently recomputes Qty*UnitPrice in Python,
#  and asserts it equals the engine's own LineTotal run for that same row --
#  proving per-instance independence (no shared/stale state across occur
#  instances).
#
#  Packets are read pre-split from their own .template.xml/.datasets.xml
#  files -- no XML library needed in this driver.
# ============================================================================
import ctypes
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

EXPECTED_ROWS = [
    ("Airfare - SFO to ORD", "1", "450.00"),
    ("Hotel - 3 nights", "3", "120.00"),
    ("Taxi / Rideshare", "4", "18.50"),
    ("Client Dinner", "5", "22.00"),
    ("Parking", "2", "15.00"),
    ("Conference Registration", "1", "299.00"),
    ("Office Supplies", "6", "4.25"),
]
# GrandTotal is a literal bound dataset value (bind match="dataRef"), NOT
# FormCalc-computed -- so this must match the dataset's own authored string
# exactly, unlike each row's engine-computed LineTotal.
EXPECTED_GRAND_TOTAL = "1348.50"


def fmt_num(v):
    """FloatToStr-parity formatting: invariant '.' separator, no group
    separator, no forced trailing zeros -- matches the engine's own
    FloatToStr-produced LineTotal run for a true string-equality comparison."""
    if v == int(v):
        return str(int(v))
    s = repr(v)
    return s


def collect_page_text(pdf):
    stack = L.TPDFStack()
    ctypes.memset(ctypes.byref(stack), 0, ctypes.sizeof(stack))
    if L.pdfInitStack(pdf, ctypes.byref(stack)) == 0:
        print("pdfInitStack FAILED")
        return []
    runs = []
    while L.pdfGetPageText(pdf, ctypes.byref(stack)) != 0:
        if stack.Text and stack.TextLen > 0:
            runs.append(ctypes.string_at(stack.Text, stack.TextLen).decode("latin-1"))
    return runs


def find_run(runs, start_at, needle):
    for i in range(start_at, len(runs)):
        if runs[i] == needle:
            return i
    return -1


def main():
    all_pass = True
    print("=== 05_occur_repeating_rows (Expense Report, occur min=1 max=-1) ===")

    template_path = os.path.join(HERE, "05_occur_repeating_rows.template.xml")
    datasets_path = os.path.join(HERE, "05_occur_repeating_rows.datasets.xml")
    out_pdf_path = os.path.join(HERE, "05_occur_repeating_rows.pdf")

    template = open(template_path, "rb").read()
    datasets = open(datasets_path, "rb").read()
    print("template packet bytes:", len(template))
    print("datasets packet bytes:", len(datasets))

    pdf = L.pdfNewPDF()
    if not pdf:
        print("pdfNewPDF FAILED")
        sys.exit(1)
    try:
        if L.pdfCreateNewPDFA(pdf, out_pdf_path.encode("latin-1")) == 0:
            print("pdfCreateNewPDFA FAILED")
            sys.exit(1)

        idx = L.pdfCreateXFAStreamA(pdf, b"template", template, len(template))
        print("pdfCreateXFAStreamA(template) -> index", idx)
        if idx < 0:
            sys.exit(1)

        idx = L.pdfCreateXFAStreamA(pdf, b"datasets", datasets, len(datasets))
        print("pdfCreateXFAStreamA(datasets) -> index", idx)
        if idx < 0:
            sys.exit(1)

        rc = L.pdfRenderXFAForm(pdf)
        print("pdfRenderXFAForm ->", rc, "page(s)")
        if rc < 0:
            print("pdfRenderXFAForm FAILED, code", rc)
            sys.exit(1)
        if rc != 1:
            print("UNEXPECTED PAGE COUNT: expected 1 (single pageArea, no pagination), got", rc)
            all_pass = False

        # --- verification: extract the rendered page's text BEFORE closing ---
        runs = collect_page_text(pdf)
        print("extracted", len(runs), "text run(s) from the rendered page")
        for i, r in enumerate(runs):
            print(f'  run[{i}] = "{r}"')
        print()

        # Header fields (explicit <bind dataRef>, non-occur, sanity check).
        if (len(runs) >= 4 and runs[0] == "Expense Report" and runs[1] == "Alex Rivera"
                and runs[2] == "Field Operations" and runs[3] == "2026-07-24"):
            print("HEADER OK: title/EmployeeName/Department/ReportDate all bound correctly")
        else:
            print("HEADER MISMATCH: expected title+3 header fields as the first 4 runs")
            all_pass = False
        print()

        # Per-row check: locate each row's Description, then its Qty/UnitPrice/
        # LineTotal are expected to be the next 3 runs in traversal order.
        cursor = 0
        for row_idx, (description, qty_str, price_str) in enumerate(EXPECTED_ROWS):
            idx = find_run(runs, cursor, description)
            if idx < 0:
                print(f'ROW {row_idx} MISSING: Description "{description}" not found')
                all_pass = False
                continue
            if idx + 3 >= len(runs):
                print(f"ROW {row_idx} TRUNCATED: not enough runs after Description at {idx}")
                all_pass = False
                continue

            qty_n = float(runs[idx + 1])
            price_n = float(runs[idx + 2])
            engine_total_n = float(runs[idx + 3])
            expected_total = fmt_num(qty_n * price_n)

            print(f'ROW {row_idx} "{description}"  Qty={runs[idx + 1]} UnitPrice={runs[idx + 2]}'
                  f'  engine LineTotal={runs[idx + 3]}  hand-check {runs[idx + 1]} x {runs[idx + 2]} = {expected_total}', end="")

            if runs[idx + 1] != qty_str or runs[idx + 2] != price_str:
                print("  MISMATCH: bound Qty/UnitPrice do not match this row's own dataset record")
                all_pass = False
            elif runs[idx + 3] != expected_total:
                print(f"  MISMATCH: engine LineTotal ({runs[idx + 3]}) <> hand-computed ({expected_total})"
                      " -- possible shared/stale state across instances")
                all_pass = False
            else:
                print("  OK")

            cursor = idx + 4
        print()

        # Instance-count check: exactly one occurrence of row 0's own
        # Description (a real dup would indicate a templating/instance bug).
        dup_count = 0
        i = 0
        while True:
            i = find_run(runs, i, EXPECTED_ROWS[0][0])
            if i < 0:
                break
            dup_count += 1
            i += 1
        if dup_count != 1:
            print(f"INSTANCE-DUP CHECK FAILED for row 0's Description: found {dup_count} time(s), expected 1")
            all_pass = False

        # Grand total: literal dataset value, TotalsRow non-occur sibling
        # flowed directly after the 7 occur rows.
        idx = find_run(runs, 0, "Total")
        if idx < 0:
            print('GrandTotal label "Total" NOT FOUND')
            all_pass = False
        elif idx + 1 >= len(runs) or runs[idx + 1] != EXPECTED_GRAND_TOTAL:
            got = runs[idx + 1] if idx + 1 < len(runs) else "<none>"
            print(f'GrandTotal MISMATCH: expected "{EXPECTED_GRAND_TOTAL}", got "{got}"')
            all_pass = False
        else:
            print("GrandTotal OK:", runs[idx + 1])

        if L.pdfCloseFile(pdf) == 0:
            print("pdfCloseFile FAILED")
            sys.exit(1)
        print()
        print("OK: wrote", out_pdf_path)
    finally:
        L.pdfDeletePDF(pdf)

    print()
    if all_pass:
        print(f"RESULT|05_occur_repeating_rows=PASS|instances={len(EXPECTED_ROWS)}")
    else:
        print("RESULT|05_occur_repeating_rows=FAIL")
        sys.exit(1)


if __name__ == "__main__":
    main()

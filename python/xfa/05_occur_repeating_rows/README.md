# 05 - OCCUR/REPEAT Data-Driven Row Cloning (Python)

Python (ctypes) port of `examples\delphi\xfa\05_occur_repeating_rows`.

Demonstrates `<occur min="1" max="-1"/>`: one repeating template row is
instantiated **once per matching dataset record**, each instance
independently bound to its own record and independently re-running its own
`calculate` script (`LineTotal = Qty * UnitPrice`).

Renders a one-page "Expense Report": a title + three header fields
(`EmployeeName`/`Department`/`ReportDate`, explicit `<bind dataRef>`), an
`ExpenseItemsTable` with the occur-repeated `Item` row (implicitly bound to 7
`<Item>` records under `$data.ExpenseReport.Items`), and a non-occur
`TotalsRow` showing a literal `GrandTotal`.

## Files

- `05_occur_repeating_rows.template.xml` / `.datasets.xml` -- pre-split XFA
  packets, copied verbatim from the Delphi flavor's `.xdp` fixture.
- `05_occur_repeating_rows.py` -- the driver: `pdfNewPDF -> pdfCreateNewPDFA
  -> pdfCreateXFAStreamA` x2 `-> pdfRenderXFAForm -> [pdfInitStack /
  pdfGetPageText verification] -> pdfCloseFile`.

## How to run

```
python 05_occur_repeating_rows.py
```

Writes `05_occur_repeating_rows.pdf` alongside the script.

## Verification strategy

Rather than hand-parsing the compressed content stream, this driver uses the
engine's own `pdfGetPageText` export (looped via `pdfInitStack`) on the
freshly rendered page, **before** `pdfCloseFile`. For every one of the 7
occur instances it locates that row's own `Description` among the extracted
text runs, reads the next three runs (`Qty`/`UnitPrice`/`LineTotal`),
independently recomputes `Qty * UnitPrice` in Python, and asserts it equals
the engine's own `LineTotal` for that same row -- proving per-instance
independence (no shared/stale state across occur instances, the "clone-free
occur" property).

## Expected checklist

| Row | Description | Qty | UnitPrice | engine LineTotal |
|---|---|---|---|---|
| 0 | Airfare - SFO to ORD | 1 | 450.00 | 450 |
| 1 | Hotel - 3 nights | 3 | 120.00 | 360 |
| 2 | Taxi / Rideshare | 4 | 18.50 | 74 |
| 3 | Client Dinner | 5 | 22.00 | 110 |
| 4 | Parking | 2 | 15.00 | 30 |
| 5 | Conference Registration | 1 | 299.00 | 299 |
| 6 | Office Supplies | 6 | 4.25 | 25.5 |

Header fields: `Alex Rivera` / `Field Operations` / `2026-07-24`.
`GrandTotal`: `1348.50` (literal dataset value, matches the 7 rows' own sum).
`pdfRenderXFAForm` returns page count `1` (no pagination -- 7 rows fit the
720pt content area).

Expected final line: `RESULT|05_occur_repeating_rows=PASS|instances=7`.

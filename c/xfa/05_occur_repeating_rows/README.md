# 05 -- OCCUR/REPEAT data-driven row cloning (C)

C port of `examples\delphi\xfa\05_occur_repeating_rows`. Demonstrates
`<occur min="1" max="-1"/>`: one repeating template row is instantiated
**once per matching dataset record**, each instance independently bound to
its own record and independently re-running its own `calculate` script.

Renders a one-page "Expense Report": a title and three header fields
(`EmployeeName`, `Department`, `ReportDate`, explicit `<bind dataRef>`), an
`ExpenseItemsTable` containing 7 occur-repeated `Item` rows (implicitly bound
to `$data.ExpenseReport.Items`, each with `Description`/`Qty`/`UnitPrice`
plus a calculate-only `LineTotal = Qty * UnitPrice`), and a non-occur
`TotalsRow` with a literal `GrandTotal`.

## Why this is a real regression test, not just a demo

The engine's occur design is clone-free: every instance shares the same
template node subtree -- only the per-instance data context differs. A
single shared `LineTotal` calculate script has to independently recompute a
*different* correct answer for each of the 7 rows, purely from that row's
own context -- never a value left over from whichever instance last ran.

## Verification strategy

Rather than hand-parsing the compressed content stream, this driver uses the
engine's own text-extraction export (`pdfGetPageText`, looped via
`pdfInitStack` -- the "GetPageText per-run enumerator" convention) on the
freshly rendered page, **before** `pdfCloseFile`. Each field's displayed
value is drawn as its own text run, in template/layout traversal order, so
the runs come back as `[Description, Qty, UnitPrice, LineTotal] x 7`, then
`[Total, GrandTotal]`.

For every one of the 7 occur instances, the driver:
1. locates that row's own `Description` among the extracted runs,
2. reads the next three runs (`Qty`, `UnitPrice`, `LineTotal`),
3. independently recomputes `Qty * UnitPrice` in C and asserts it equals the
   `LineTotal` run the engine produced for that same row.

This proves instance count = 7, each instance's own bound fields are its own
record's values (not another row's), and each instance's calculate script
produced its own correct answer -- never shared/stale state across
instances.

## Files

- `05_occur_repeating_rows.c` -- console driver (self-contained verification,
  no external test framework).
- `05_occur_repeating_rows.template.xml` / `05_occur_repeating_rows.datasets.xml`
  -- pre-split packet bytes.
- `LumasPdf.dll` -- copy of the already-built engine DLL.

## How to build + run

```bat
"C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
cl /nologo /I "<repo root>\wrappers\c" 05_occur_repeating_rows.c /Fe:05_occur_repeating_rows.exe /link "<repo root>\wrappers\c\LumasPdf.x64.lib"
05_occur_repeating_rows.exe
```

Writes `05_occur_repeating_rows.pdf` alongside the exe. Expected final line:
`RESULT|05_occur_repeating_rows=PASS|instances=7`.

## Expected checklist

| Row | Description | Qty | UnitPrice | LineTotal |
|---|---|---|---|---|
| 0 | Airfare - SFO to ORD | 1 | 450.00 | 450 |
| 1 | Hotel - 3 nights | 3 | 120.00 | 360 |
| 2 | Taxi / Rideshare | 4 | 18.50 | 74 |
| 3 | Client Dinner | 5 | 22.00 | 110 |
| 4 | Parking | 2 | 15.00 | 30 |
| 5 | Conference Registration | 1 | 299.00 | 299 |
| 6 | Office Supplies | 6 | 4.25 | 25.5 |

Header: `Alex Rivera` / `Field Operations` / `2026-07-24`. `GrandTotal`
(literal dataset value, not FormCalc-summed): `1348.50`. Page count: `1`.

## Verified

Built and run for real. All 7 rows independently PASS (bound values match
their own dataset record, engine-computed `LineTotal` matches the
hand-recomputed `Qty x UnitPrice` for that exact row), header fields OK,
`GrandTotal` OK, instance-count check OK (exactly 1 occurrence of row 0's own
description, i.e. no duplication/no clone-state bleed), page count = 1.
Final result: `RESULT|05_occur_repeating_rows=PASS|instances=7`.

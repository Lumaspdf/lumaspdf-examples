# 05 - OCCUR/REPEAT Data-Driven Row Cloning (VB6)

VB6 port of `examples\delphi\xfa\05_occur_repeating_rows`. Demonstrates
`<occur min="1" max="-1"/>`: one repeating template row is instantiated
**once per matching dataset record**, each instance independently bound to
its own record and independently re-running its own `calculate` script.

Renders a one-page "Expense Report": a title and three explicitly-bound
header fields (`EmployeeName`, `Department`, `ReportDate`), plus an
`ExpenseItemsTable` containing the occur-repeated `Item` row (implicitly
bound by name to the 7 `<Item>` records under
`$data.ExpenseReport.Items`) -- each instance has `Description`/`Qty`/
`UnitPrice` (bound) plus `LineTotal` -- a calculate-only field whose
FormCalc script is `Qty * UnitPrice`, resolved independently per instance
(the engine's occur design is "clone-free": every instance shares the same
template node subtree, only the per-instance data context differs).

## Files

Same layout convention as every other example: pre-split
`05_occur_repeating_rows.template.xml`/`.datasets.xml` packets, a
native-C-API-style `05_occur_repeating_rows.bas` driver + `.vbp` project
file, and a bundled 32-bit `LumasPdf.dll`.

## How to build + run

```
"C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" /make 05_occur_repeating_rows.vbp
05_occur_repeating_rows.exe
```

Writes `05_occur_repeating_rows.pdf` alongside the exe.

## Verified output (rendered PDF page 1 text, via pypdf)

Built with `VB6.EXE /make`, run for real -- all 7 rows independently
correct:

| Description | Qty | UnitPrice | LineTotal (engine) | hand-check |
|---|---|---|---|---|
| Airfare - SFO to ORD | 1 | 450.00 | 450 | 1 x 450.00 = 450 |
| Hotel - 3 nights | 3 | 120.00 | 360 | 3 x 120.00 = 360 |
| Taxi / Rideshare | 4 | 18.50 | 74 | 4 x 18.50 = 74 |
| Client Dinner | 5 | 22.00 | 110 | 5 x 22.00 = 110 |
| Parking | 2 | 15.00 | 30 | 2 x 15.00 = 30 |
| Conference Registration | 1 | 299.00 | 299 | 1 x 299.00 = 299 |
| Office Supplies | 6 | 4.25 | 25.5 | 6 x 4.25 = 25.5 |

Header fields (`Alex Rivera`/`Field Operations`/`2026-07-24`) and
`GrandTotal` (`1348.50`, matching the 7 rows' own sum by hand) all bound
correctly. 1 page (no pagination -- 7 rows comfortably fit the content
area) -- matches the Delphi original's own verified output exactly.

# 05 — Occur/Repeat Data-Driven Row Cloning (ActiveX/COM)

ActiveX/COM port of `examples\delphi\xfa\05_occur_repeating_rows`. See
`..\README.md` for why this tour uses PowerShell rather than VBScript.

Demonstrates `<occur min="1" max="-1"/>`: one repeating template row is
instantiated once per matching dataset record, each instance independently
bound to its own record and independently re-running its own `calculate`
script.

A one-page "Expense Report": a title and three explicitly-bound header
fields (`EmployeeName`, `Department`, `ReportDate`), and an
`ExpenseItemsTable` (`layout="tb"`) containing 7 occur-repeated `Item` rows
(implicitly bound by name to `$data.ExpenseReport.Items`), each with
`Description`/`Qty`/`UnitPrice` (bound) plus `LineTotal` — a
calculate-only field whose FormCalc script is just `Qty * UnitPrice`, and a
non-occur `TotalsRow` showing a literal `GrandTotal`.

Because the engine's occur design is "clone-free" (every instance shares
the same template subtree, only the per-instance data context differs),
this is a real regression test: `LineTotal`'s single shared script must
independently recompute a different correct answer for each of the 7 rows.

## Run

```
powershell -File 05_occur_repeating_rows.ps1
```

## Expected values (all 7 rows independently correct)

| Row | Description | Qty | UnitPrice | LineTotal |
|---|---|---|---|---|
| 1 | Airfare | 1 | 450.00 | 450 |
| 2 | Hotel | 3 | 120.00 | 360 |
| 3 | Taxi / Rideshare | 4 | 18.50 | 74 |
| 4 | Client Dinner | 5 | 22.00 | 110 |
| 5 | Parking | 2 | 15.00 | 30 |
| 6 | Conference Registration | 1 | 299.00 | 299 |
| 7 | Office Supplies | 6 | 4.25 | 25.5 |

Header fields: `Alex Rivera` / `Field Operations` / `2026-07-24`.
`GrandTotal` (literal, hand-sum of the 7 rows) = `1348.50`.
`RenderXFAForm` returns 1 (one page — 7 rows comfortably fit the 720pt
content area).

# 05 - OCCUR/REPEAT Data-Driven Row Cloning (VB.NET)

VB.NET port of `examples\delphi\xfa\05_occur_repeating_rows`. Demonstrates
`<occur min="1" max="-1"/>`: one repeating template row is instantiated
**once per matching dataset record**, each instance independently bound to
its own record and independently re-running its own `calculate` script.

Renders a one-page "Expense Report":

- A title and three header fields (`EmployeeName`, `Department`,
  `ReportDate`), each an **explicit** `<bind match="dataRef">` field.
- An `ExpenseItemsTable` (`layout="tb"`) containing:
  - `Item` -- the occur-repeated row, **implicitly** bound by name to the 7
    `<Item>` records under `$data.ExpenseReport.Items`. Each instance has
    `Description`/`Qty`/`UnitPrice` plus `LineTotal` -- a calculate-only
    field whose FormCalc script is `Qty * UnitPrice`.
  - `TotalsRow` -- a non-occur sibling showing a literal `GrandTotal`.

## Files

- `05_occur_repeating_rows.vb` -- console driver, reads the two pre-split
  packet files directly and renders through the standard `pdfNewPDF ->
  pdfCreateNewPDFA -> pdfCreateXFAStreamA(x2) -> pdfRenderXFAForm ->
  pdfCloseFile` pipeline.
- `05_occur_repeating_rows.template.xml` / `.datasets.xml` -- packet bytes,
  copied from the Delphi source example.
- `LumasPdf.dll` / `LumasPdf.VB.dll` -- engine DLL + VB.NET binding.

## How to run

```
"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\vbc.exe" /nologo /platform:x64 /r:"LumasPdf.VB.dll" /out:05_occur_repeating_rows.exe 05_occur_repeating_rows.vb
05_occur_repeating_rows.exe
```

Writes `05_occur_repeating_rows.pdf` alongside the exe.

## Verified output

`pdfRenderXFAForm` returns `1` (one page). `RESULT|05_occur_repeating_rows=1`.
Expected 7-row set, each independently computed (`Qty x UnitPrice`):

| Row | Description | Qty | UnitPrice | LineTotal |
|---|---|---|---|---|
| 1 | Airfare | 1 | 450.00 | 450 |
| 2 | Hotel - 3 nights | 3 | 120.00 | 360 |
| 3 | Taxi / Rideshare | 4 | 18.50 | 74 |
| 4 | Client Dinner | 5 | 22.00 | 110 |
| 5 | Parking | 2 | 15.00 | 30 |
| 6 | Conference Registration | 1 | 299.00 | 299 |
| 7 | Office Supplies | 6 | 4.25 | 25.5 |

Header fields (`Alex Rivera` / `Field Operations` / `2026-07-24`) and
`GrandTotal` (`1348.50`, matching the 7 rows' own sum) bind correctly. This
proves the engine's "clone-free" occur design correctly threads a different
data context through the same shared `LineTotal` calculate script for each of
the 7 instances (no shared-state bleed between rows) -- same `.xdp` packet
bytes and engine as the Delphi original, so the same 7-row result applies
here.

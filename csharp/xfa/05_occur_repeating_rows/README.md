# 05 - OCCUR/REPEAT Data-Driven Row Cloning (C#)

C# port of `examples\delphi\xfa\05_occur_repeating_rows`. Demonstrates
`<occur min="1" max="-1"/>`: one repeating template row is instantiated
**once per matching dataset record**, each instance independently bound to
its own record and independently re-running its own `calculate` script.

A one-page "Expense Report": a title and three header fields
(`EmployeeName`, `Department`, `ReportDate`, each an **explicit** `<bind
match="dataRef">` field), and an `ExpenseItemsTable` (`layout="tb"`)
containing the occur-repeated `Item` row (implicitly bound by name to the 7
`<Item>` records under `$data.ExpenseReport.Items`) plus a non-occur
`TotalsRow` showing a literal `GrandTotal`.

Each `Item` instance has `Description`/`Qty`/`UnitPrice` (bound fields) plus
`LineTotal` -- a calculate-only field (`bind match="none"`) whose FormCalc
script is `Qty * UnitPrice`, run independently per instance (the engine's
occur design is "clone-free": all instances share the same template subtree,
only the per-instance data context differs).

## Files

- `05_occur_repeating_rows.cs` -- console driver.
- `05_occur_repeating_rows.template.xml` / `.datasets.xml` -- pre-split packets.
- `LumasPdf.dll` / `LumasPdf.Net.dll` -- engine DLL + P/Invoke wrapper.

## Pipeline

```
pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA("template",...) ->
pdfCreateXFAStreamA("datasets",...) -> pdfRenderXFAForm -> pdfCloseFile
```

## Build + run

```
powershell -File ..\..\build_one.ps1 xfa\05_occur_repeating_rows 05_occur_repeating_rows.cs
.\05_occur_repeating_rows.exe
```

Writes `05_occur_repeating_rows.pdf` alongside the exe.

## Expected checklist

Header fields: `Alex Rivera` / `Field Operations` / `2026-07-24`.

| Row | Description | Qty | UnitPrice | Expected LineTotal |
|---|---|---|---|---|
| 1 | Airfare | 1 | 450.00 | `450` |
| 2 | Hotel - 3 nights | 3 | 120.00 | `360` |
| 3 | Taxi / Rideshare | 4 | 18.50 | `74` |
| 4 | Client Dinner | 5 | 22.00 | `110` |
| 5 | Parking | 2 | 15.00 | `30` |
| 6 | Conference Registration | 1 | 299.00 | `299` |
| 7 | Office Supplies | 6 | 4.25 | `25.5` |

`GrandTotal` (literal) = `1348.50` (matches the 7 rows' own sum by hand).
Instance count must be exactly `7`. `pdfRenderXFAForm` should return `1`
(page count -- 7 rows comfortably fit the 720pt content area).

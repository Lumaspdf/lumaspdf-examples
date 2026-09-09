# 05 - OCCUR/REPEAT Data-Driven Row Cloning (C++)

C++ port of `examples\delphi\xfa\05_occur_repeating_rows`. Demonstrates
`<occur min="1" max="-1"/>`: one repeating template row is instantiated
**once per matching dataset record**, each instance independently bound to
its own record and independently re-running its own `calculate` script.

A one-page "Expense Report":

- A title and three header fields (`EmployeeName`, `Department`,
  `ReportDate`), each an **explicit** `<bind match="dataRef">` field.
- An `ExpenseItemsTable` (`layout="tb"`) containing:
  - `Item` -- the occur-repeated row (`<occur min="1" max="-1"/>`,
    `layout="row"`), **implicitly** bound by name to 7 `<Item>` records.
    Each instance has `Description`/`Qty`/`UnitPrice` plus `LineTotal` -- a
    calculate-only field (`Qty * UnitPrice`).
  - `TotalsRow` -- a non-occur sibling showing a literal `GrandTotal`.

## Files

- `05_occur_repeating_rows.cpp` -- console driver.
- `05_occur_repeating_rows.template.xml` / `.datasets.xml` -- pre-split XFA
  packets (raw bytes, no XML parsing needed).
- `LumasPdf.dll` -- a copy of the engine DLL.

## How to build and run

```bat
<repo root>\examples\cpp\xfa\build_xfa.bat
```

then run `05_occur_repeating_rows.exe` from its own directory. Writes
`05_occur_repeating_rows.pdf` alongside itself. Does not rebuild
`LumasPdf.dll`.

## Verified output (rendered PDF page 1 content, via pypdf)

All 7 rows independently correct -- each `LineTotal` = that row's own
`Qty x UnitPrice`, never a value bled over from another instance:

| Row | Description | Qty | UnitPrice | LineTotal |
|---|---|---|---|---|
| 1 | Airfare - SFO to ORD | 1 | 450.00 | 450 |
| 2 | Hotel - 3 nights | 3 | 120.00 | 360 |
| 3 | Taxi / Rideshare | 4 | 18.50 | 74 |
| 4 | Client Dinner | 5 | 22.00 | 110 |
| 5 | Parking | 2 | 15.00 | 30 |
| 6 | Conference Registration | 1 | 299.00 | 299 |
| 7 | Office Supplies | 6 | 4.25 | 25.5 |

Header fields (`Alex Rivera`/`Field Operations`/`2026-07-24`) and
`GrandTotal` (`1348.50`, matching the 7 rows' own sum) all bound correctly.
Page count = 1 (7 rows comfortably fit the 720pt content area) -- confirmed
via the real `pdfRenderXFAForm` return value.

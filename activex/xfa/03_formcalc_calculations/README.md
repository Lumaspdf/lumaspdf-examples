# 03 — FormCalc Calculations (ActiveX/COM)

ActiveX/COM port of `examples\delphi\xfa\03_formcalc_calculations`. See
`..\README.md` for why this tour uses PowerShell rather than VBScript.

Demonstrates LumasPDF's XFA **FormCalc engine** end-to-end through
`RenderXFAForm`. A single-page "Order Calculator": a customer/date header, a
3-line item table (Widget/Gadget/Gizmo, each with bound quantity + unit
price), and a calculated summary block (line totals, subtotal, average
price, item count, a discount tier + discount amount, grand total), all
wired up with `<calculate><script contentType="application/x-formcalc">`
bodies.

Builtins exercised: `Sum`, `Avg`, `Round`, `Count`, `If`, `Concat`, `Upper`,
`Left`, `Date2Num`, `Num2Date`, `DateFmt`, plus `*`/`-`/`>=`.

## Dataset (`$data.Order`)

```
Customer: FirstName=Alex, LastName=Nguyen
OrderDate: "Jul 15, 2026"
DiscountThreshold: 100
Item1 (Widget): Qty=3, Price=12.50
Item2 (Gadget): Qty=2, Price=45.00
Item3 (Gizmo):  Qty=5, Price=8.00
```

## Run

```
powershell -File 03_formcalc_calculations.ps1
```

## Verified output (pypdf text extraction of page 1)

| Field | Expected | Rendered |
|---|---|---|
| `Item1Total` | 37.5 | `37.5` |
| `Item2Total` | 90 | `90` |
| `Item3Total` | 40 | `40` |
| `TotalQty` | 10 | `10` |
| `Subtotal` | 167.5 | `167.5` |
| `AvgUnitPrice` | 21.83 | `21.83` |
| `ItemCount` | 3 | `3` |
| `DiscountLabel` | Bulk Discount | `Bulk Discount` |
| `DiscountAmount` | 16.75 | `16.75` |
| `GrandTotal` | 150.75 | `150.75` |
| `FullName` | Alex Nguyen | `Alex Nguyen` |
| `CustomerInitial` | A | `A` |
| `OrderDateFormatted` | 7/15/26 | `7/15/26` |

All values confirmed via `pypdf` against the actual rendered `output.pdf` —
exact match with the Delphi reference's own checklist, including the
`Date2Num`/`Num2Date`/`DateFmt` round trip (the underlying-vs-displayed date
epoch bug documented in the Delphi README was already fixed engine-side
before this port; the fix carries through unchanged here since it's the
same `LumasPdf.dll`).

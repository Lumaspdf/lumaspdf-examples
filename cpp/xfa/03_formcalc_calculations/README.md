# 03 - FormCalc Calculations (C++)

C++ port of `examples\delphi\xfa\03_formcalc_calculations`. Demonstrates
LumasPDF's XFA **FormCalc engine** end-to-end through the real
`pdfRenderXFAForm` export. The form is a single-page "Order Calculator" order
summary: a customer/date header, a 3-line item table (Widget/Gadget/Gizmo,
each with bound quantity + unit price), and a calculated summary block (line
totals, subtotal, average price, item count, a discount tier + discount
amount, grand total), wired up with `<calculate><script
contentType="application/x-formcalc">` bodies.

Builtins exercised: `Sum`, `Avg`, `Round`, `Count` (arithmetic); `If`
(logical); `Concat`, `Upper`, `Left` (string); `Date2Num`, `Num2Date`,
`DateFmt` (date/time); plus `*`, `-`, `>=` operators.

## Files

- `03_formcalc_calculations.cpp` -- console driver.
- `03_formcalc_calculations.template.xml` / `.datasets.xml` -- pre-split XFA
  packets (raw bytes, no XML parsing needed).
- `LumasPdf.dll` -- a copy of the engine DLL.

## Dataset (`$data.Order`)

```
Customer: FirstName=Alex, LastName=Nguyen
OrderDate: "Jul 15, 2026"
DiscountThreshold: 100
Item1 (Widget): Qty=3, Price=12.50
Item2 (Gadget): Qty=2, Price=45.00
Item3 (Gizmo):  Qty=5, Price=8.00
```

## How to build and run

```bat
<repo root>\examples\cpp\xfa\build_xfa.bat
```

then run `03_formcalc_calculations.exe` from its own directory. Writes
`03_formcalc_calculations.render.pdf` alongside itself. Does not rebuild
`LumasPdf.dll`.

## Verified output (hand-computed vs. actual rendered text, via pypdf)

| Field | Hand-computed | Rendered | Match |
|---|---|---|---|
| `Item1Total` | 3 x 12.50 = 37.5 | `37.5` | yes |
| `Item2Total` | 2 x 45.00 = 90 | `90` | yes |
| `Item3Total` | 5 x 8.00 = 40 | `40` | yes |
| `TotalQty` | 3+2+5 = 10 | `10` | yes |
| `Subtotal` | 37.5+90+40 = 167.5 | `167.5` | yes |
| `AvgUnitPrice` | round((12.50+45.00+8.00)/3, 2) = 21.83 | `21.83` | yes |
| `ItemCount` | 3 non-null args | `3` | yes |
| `DiscountLabel` | 167.5 >= 100 -> "Bulk Discount" | `Bulk Discount` | yes |
| `DiscountAmount` | round(167.5 x 0.10, 2) = 16.75 | `16.75` | yes |
| `GrandTotal` | 167.5 - 16.75 = 150.75 | `150.75` | yes |
| `FullName` | "Alex" + " " + "Nguyen" | `Alex Nguyen` | yes |
| `CustomerInitial` | Upper(Left("Alex",1)) = "A" | `A` | yes |
| `OrderDateNum` displayed | `Date2Num("Jul 15, 2026")` re-rendered as a date | `2026-07-15` | yes |
| `OrderDateFormatted` | `Num2Date(OrderDateNum, DateFmt(1))` | `7/15/26` | yes |

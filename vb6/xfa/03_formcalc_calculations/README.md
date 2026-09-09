# 03 - FormCalc Calculations (VB6)

VB6 port of `examples\delphi\xfa\03_formcalc_calculations`. Demonstrates
LumasPDF's XFA **FormCalc engine** (lexer -> parser -> VM -> builtin
catalog) end-to-end through the real `pdfRenderXFAForm` export. The form is
a single-page "Order Calculator": a customer/date header, a 3-line item
table (Widget/Gadget/Gizmo, each with bound quantity + unit price), and a
calculated summary block (line totals, subtotal, average price, item count,
a discount tier + discount amount, grand total), all wired up with
`<calculate><script contentType="application/x-formcalc">` bodies. Builtins
exercised: `Sum`, `Avg`, `Round`, `Count`, `If`, `Concat`, `Upper`, `Left`,
`Date2Num`, `Num2Date`, `DateFmt`, plus `*`/`-`/`>=` operators.

## Files

Same layout convention as every other example: pre-split
`03_formcalc_calculations.template.xml`/`.datasets.xml` packets, a
native-C-API-style `03_formcalc_calculations.bas` driver + `.vbp` project
file, and a bundled 32-bit `LumasPdf.dll`.

## How to build + run

```
"C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" /make 03_formcalc_calculations.vbp
03_formcalc_calculations.exe
```

Writes `03_formcalc_calculations.render.pdf` alongside the exe.

## Dataset (`$data.Order`)

```
Customer: FirstName=Alex, LastName=Nguyen
OrderDate: "Jul 15, 2026"
DiscountThreshold: 100
Item1 (Widget): Qty=3, Price=12.50
Item2 (Gadget): Qty=2, Price=45.00
Item3 (Gizmo):  Qty=5, Price=8.00
```

## Verified output (rendered PDF page 1 text, via pypdf)

Built with `VB6.EXE /make`, run for real:

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
| `CustomerInitial` | Upper(Left("Alex",1)) | `A` | yes |
| `OrderDateNum` (displayed) | `Date2Num("Jul 15, 2026")` | `2026-07-15` | yes |
| `OrderDateFormatted` | `Num2Date(46217, "M/D/YY")` | `7/15/26` | yes |

All 14 calculated/displayed values match exactly -- identical to the Delphi
original's own verified output (including the epoch-conversion bug that was
fixed engine-side on 2026-07-24, which this VB6 build already picks up since
it links the current `x32\LumasPdf.dll`).

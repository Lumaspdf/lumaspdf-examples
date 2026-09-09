# 03 - FormCalc Calculations (C)

C port of `examples\delphi\xfa\03_formcalc_calculations`. Demonstrates
LumasPDF's XFA **FormCalc engine** (lexer -> parser -> VM -> builtin
catalog) end-to-end through the real `pdfRenderXFAForm` export. The form is
a single-page "Order Calculator": a customer/date header, a 3-line item
table (Widget/Gadget/Gizmo, each with bound quantity + unit price), and a
calculated summary block (line totals, subtotal, average price, item count,
a discount tier + discount amount, grand total), all wired up with
`<calculate><script contentType="application/x-formcalc">` bodies.

Builtins exercised: `Sum`, `Avg`, `Round`, `Count`, `If`, `Concat`, `Upper`,
`Left`, `Date2Num`, `Num2Date`, `DateFmt`, plus `*`/`-`/`>=` operators.

## Files

- `03_formcalc_calculations.c` -- console driver.
- `03_formcalc_calculations.template.xml` / `03_formcalc_calculations.datasets.xml`
  -- pre-split packet bytes.
- `LumasPdf.dll` -- copy of the already-built engine DLL.

## Dataset (`$data.Order`)

```
Customer: FirstName=Alex, LastName=Nguyen
OrderDate: "Jul 15, 2026"
DiscountThreshold: 100
Item1 (Widget): Qty=3, Price=12.50
Item2 (Gadget): Qty=2, Price=45.00
Item3 (Gizmo):  Qty=5, Price=8.00
```

## How to build + run

```bat
"C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
cl /nologo /I "<repo root>\wrappers\c" 03_formcalc_calculations.c /Fe:03_formcalc_calculations.exe /link "<repo root>\wrappers\c\LumasPdf.x64.lib"
03_formcalc_calculations.exe
```

Writes `03_formcalc_calculations.render.pdf` alongside the exe.

## Expected checklist (hand-computed, matches the Delphi example exactly)

| Field | Expected |
|---|---|
| `Item1Total`/`Item2Total`/`Item3Total` | `37.5` / `90` / `40` |
| `TotalQty` | `10` |
| `Subtotal` | `167.5` |
| `AvgUnitPrice` | `21.83` |
| `ItemCount` | `3` |
| `DiscountLabel` | `Bulk Discount` |
| `DiscountAmount` | `16.75` |
| `GrandTotal` | `150.75` |
| `FullName` | `Alex Nguyen` |
| `CustomerInitial` | `A` |
| `OrderDateNum` (rendered as a date) | `2026-07-15` |
| `OrderDateFormatted` | `7/15/26` |

## Verified

Built and run for real; `pdfRenderXFAForm` returned `1`. Independently
confirmed via `pypdf` text extraction on the rendered PDF -- every value in
the table above appears exactly as expected, matching both the hand
computation and the Delphi example's already-verified output.

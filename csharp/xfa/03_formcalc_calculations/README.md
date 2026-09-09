# 03 - FormCalc Calculations (C#)

C# port of `examples\delphi\xfa\03_formcalc_calculations`. Demonstrates
LumasPDF's XFA **FormCalc engine** (lexer -> parser -> VM -> builtin catalog)
end-to-end through `pdfRenderXFAForm`. The form is a single-page "Order
Calculator": a customer/date header, a 3-line item table (Widget/Gadget/Gizmo,
each with bound quantity + unit price), and a calculated summary block (line
totals, subtotal, average price, item count, a discount tier + discount
amount, grand total), all wired up with `<calculate><script
contentType="application/x-formcalc">` bodies.

Builtins exercised: `Sum`, `Avg`, `Round`, `Count`, `If`, `Concat`, `Upper`,
`Left`, `Date2Num`, `Num2Date`, `DateFmt`, plus `*`, `-`, `>=`.

## Dataset (`$data.Order`)

```
Customer: FirstName=Alex, LastName=Nguyen
OrderDate: "Jul 15, 2026"
DiscountThreshold: 100
Item1 (Widget): Qty=3, Price=12.50
Item2 (Gadget): Qty=2, Price=45.00
Item3 (Gizmo):  Qty=5, Price=8.00
```

## Files

- `03_formcalc_calculations.cs` -- console driver.
- `03_formcalc_calculations.template.xml` / `.datasets.xml` -- pre-split packets.
- `LumasPdf.dll` / `LumasPdf.Net.dll` -- engine DLL + P/Invoke wrapper.

## Pipeline

```
pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA("template",...) ->
pdfCreateXFAStreamA("datasets",...) -> pdfRenderXFAForm -> pdfCloseFile
```

## Build + run

```
powershell -File ..\..\build_one.ps1 xfa\03_formcalc_calculations 03_formcalc_calculations.cs
.\03_formcalc_calculations.exe
```

Writes `03_formcalc_calculations.render.pdf` alongside the exe.

## Expected checklist

| Field | Hand-computed | Expected rendered |
|---|---|---|
| `Item1Total` | 3 x 12.50 | `37.5` |
| `Item2Total` | 2 x 45.00 | `90` |
| `Item3Total` | 5 x 8.00 | `40` |
| `TotalQty` | 3+2+5 | `10` |
| `Subtotal` | 37.5+90+40 | `167.5` |
| `AvgUnitPrice` | Round(Avg(12.50,45.00,8.00),2) | `21.83` |
| `ItemCount` | Count() | `3` |
| `DiscountLabel` | 167.5 >= 100 | `Bulk Discount` |
| `DiscountAmount` | Round(167.5*0.10,2) | `16.75` |
| `GrandTotal` | 167.5-16.75 | `150.75` |
| `FullName` | Concat | `Alex Nguyen` |
| `CustomerInitial` | Upper(Left("Alex",1)) | `A` |
| `OrderDateNum` displayed | Date2Num/day-count | `2026-07-15` |
| `OrderDateFormatted` | Num2Date(OrderDateNum, DateFmt(1)) | `7/15/26` |

`pdfRenderXFAForm` should return `1`.

# 03 - FormCalc Calculations (Python)

Python (ctypes) port of `examples\delphi\xfa\03_formcalc_calculations`.

Demonstrates LumasPDF's XFA **FormCalc engine** end-to-end. The form is a
single-page "Order Calculator": a customer/date header, a 3-line item table
(Widget/Gadget/Gizmo, bound quantity + unit price), and a calculated summary
block (line totals, subtotal, average price, item count, a discount tier +
amount, grand total), wired up with
`<calculate><script contentType="application/x-formcalc">` bodies.

13 fields are bound to the `<xfa:datasets>` packet; 14 are calculate-only.
Builtins exercised: `Sum`, `Avg`, `Round`, `Count`, `If`, `Concat`, `Upper`,
`Left`, `Date2Num`, `Num2Date`, `DateFmt`, plus `*`/`-`/`>=`.

## Files

- `03_formcalc_calculations.template.xml` / `.datasets.xml` -- pre-split XFA
  packets, copied verbatim from the Delphi flavor's `.xdp` fixture.
- `03_formcalc_calculations.py` -- the driver: `pdfNewPDF -> pdfCreateNewPDFA
  -> pdfCreateXFAStreamA` x2 `-> pdfRenderXFAForm -> pdfCloseFile`.

## How to run

```
python 03_formcalc_calculations.py
```

Writes `03_formcalc_calculations.render.pdf` alongside the script.

## Dataset (`$data.Order`)

```
Customer: FirstName=Alex, LastName=Nguyen
OrderDate: "Jul 15, 2026"
DiscountThreshold: 100
Item1 (Widget): Qty=3, Price=12.50
Item2 (Gadget): Qty=2, Price=45.00
Item3 (Gizmo):  Qty=5, Price=8.00
```

## Expected checklist (hand-computed, verified against the rendered PDF text)

| Field | Hand-computed | Rendered |
|---|---|---|
| `Item1Total` | 3 x 12.50 = 37.5 | `37.5` |
| `Item2Total` | 2 x 45.00 = 90 | `90` |
| `Item3Total` | 5 x 8.00 = 40 | `40` |
| `TotalQty` | 3+2+5 = 10 | `10` |
| `Subtotal` | 37.5+90+40 = 167.5 | `167.5` |
| `AvgUnitPrice` | round(avg, 2) = 21.83 | `21.83` |
| `ItemCount` | 3 non-null args | `3` |
| `DiscountLabel` | 167.5 >= 100 -> "Bulk Discount" | `Bulk Discount` |
| `DiscountAmount` | round(167.5 x 0.10, 2) = 16.75 | `16.75` |
| `GrandTotal` | 167.5 - 16.75 = 150.75 | `150.75` |
| `FullName` | Concat("Alex", " ", "Nguyen") | `Alex Nguyen` |
| `CustomerInitial` | Upper(Left("Alex",1)) | `A` |
| `OrderDateNum` (displayed) | epoch day 46217 | `2026-07-15` |
| `OrderDateFormatted` | Num2Date(46217, "M/D/YY") | `7/15/26` |

`pdfRenderXFAForm` returns page count `1`. All 14 values confirmed via
`pypdf` extraction of the rendered PDF.

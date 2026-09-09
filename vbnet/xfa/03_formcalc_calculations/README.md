# 03 - FormCalc Calculations (VB.NET)

VB.NET port of `examples\delphi\xfa\03_formcalc_calculations`. Demonstrates
LumasPDF's XFA **FormCalc engine** end-to-end through the real
`pdfRenderXFAForm` export. The form is a single-page "Order Calculator": a
customer/date header, a 3-line item table (Widget/Gadget/Gizmo, each with
bound quantity + unit price), and a calculated summary block (line totals,
subtotal, average price, item count, a discount tier + discount amount,
grand total), all wired up with
`<calculate><script contentType="application/x-formcalc">` bodies.

13 fields are bound to the `<xfa:datasets>` packet; 14 fields are
calculate-only and hold a FormCalc script each, using `Sum`, `Avg`, `Round`,
`Count`, `If`, `Concat`, `Upper`, `Left`, `Date2Num`, `Num2Date`, `DateFmt`,
plus `*`/`-`/`>=`.

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

- `03_formcalc_calculations.vb` -- console driver, reads the two pre-split
  packet files directly and renders through `LumasPdf.VB.dll`'s standard
  `pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA(x2) ->
  pdfRenderXFAForm -> pdfCloseFile` pipeline.
- `03_formcalc_calculations.template.xml` / `.datasets.xml` -- packet bytes,
  copied from the Delphi source example.
- `LumasPdf.dll` / `LumasPdf.VB.dll` -- engine DLL + VB.NET binding.

## How to run

```
"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\vbc.exe" /nologo /platform:x64 /r:"LumasPdf.VB.dll" /out:03_formcalc_calculations.exe 03_formcalc_calculations.vb
03_formcalc_calculations.exe
```

Writes `03_formcalc_calculations.render.pdf` alongside the exe.

## Verified output (rendered PDF page 1 text, extracted via `pypdf`)

| Field | Expected | Rendered | Match |
|---|---|---|---|
| `Item1Total` | 37.5 | `37.5` | yes |
| `Item2Total` | 90 | `90` | yes |
| `Item3Total` | 40 | `40` | yes |
| `TotalQty` | 10 | `10` | yes |
| `Subtotal` | 167.5 | `167.5` | yes |
| `AvgUnitPrice` | 21.83 | `21.83` | yes |
| `ItemCount` | 3 | `3` | yes |
| `DiscountLabel` | Bulk Discount | `Bulk Discount` | yes |
| `DiscountAmount` | 16.75 | `16.75` | yes |
| `GrandTotal` | 150.75 | `150.75` | yes |
| `FullName` | Alex Nguyen | `Alex Nguyen` | yes |
| `CustomerInitial` | A | `A` | yes |
| `OrderDateNum` displayed | `2026-07-15` | `2026-07-15` | yes (engine's epoch-conversion fix confirmed still holds) |
| `OrderDateFormatted` | 7/15/26 | `7/15/26` | yes |

All 14 values confirmed against the actual rendered PDF -- identical to the
Delphi original's checklist, including the previously-fixed `OrderDateNum`
display-epoch bug (was `2026-07-14`, now correctly `2026-07-15`).

# 03 - FormCalc Calculations (VCL static component surface)

VCL-static-component port of `examples\delphi\xfa\03_formcalc_calculations`.
Same `.xdp` fixture — a single-page "Order Calculator" order summary: a
customer/date header, a 3-line item table (Widget/Gadget/Gizmo, each with
bound quantity + unit price), and a calculated summary block (line totals,
subtotal, average price, item count, a discount tier + discount amount,
grand total), wired up with `<calculate><script
contentType="application/x-formcalc">` bodies. 13 fields are bound
(`bind match="dataRef"`); 14 fields are calculate-only (`bind match="none"`).

## Driver

Reads the already pre-split `03_formcalc_calculations.template.xml` /
`.datasets.xml` (no XML parsing needed) and drives the pipeline through
`TLumasPDFCore` (`wrappers\vcl\Lumas.Pdf.Wrap.Core.pas`), built
`LUMAS_STATIC`:

```
TLumasPDFCore.Create -> pdf.CreateNewPDFA -> pdf.CreateXFAStreamA('template',...) ->
pdf.CreateXFAStreamA('datasets',...) -> pdf.RenderXFAForm -> pdf.CloseFile -> pdf.Free
```

## Build + run

```bat
<repo root>\tools\build_vcl_static_app.bat <repo root>\examples\vcl_static\xfa\03_formcalc_calculations 03_formcalc_calculations.dpr
03_formcalc_calculations.exe
```

No `LumasPdf.dll` needed — statically linked. Writes `output.pdf` in this
folder.

## Dataset (`$data.Order`)

```
Customer: FirstName=Alex, LastName=Nguyen
OrderDate: "Jul 15, 2026"
DiscountThreshold: 100
Item1 (Widget): Qty=3, Price=12.50
Item2 (Gadget): Qty=2, Price=45.00
Item3 (Gizmo):  Qty=5, Price=8.00
```

## Verified this session (pypdf, independent re-extraction of `output.pdf`)

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
| `OrderDateNum` (display) | 2026-07-15 | `2026-07-15` | yes |
| `OrderDateFormatted` | 7/15/26 | `7/15/26` | yes |

All values match the flat-Delphi original's own README exactly, including
the `OrderDateNum` display-text epoch-conversion fix already landed in the
shared engine (`Lumas.Pdf.Xfa.Bind.pas`'s `XfaValueDisplayText`) — this port
exercises the same fixed code path, not a re-derivation.

# 03 — FormCalc Calculations (Delphi-OO)

Delphi-**OO** port of `examples\delphi\xfa\03_formcalc_calculations`. Same
fixture, same real `LumasPdf.dll`, same render pipeline — the only
difference is that this driver calls the class-based OO surface
(`wrappers\delphi\LumasPdfOO.pas`'s `TPDF` class) instead of the flat
`pdfXxx(Handle, ...)` functions the original uses.

Demonstrates LumasPDF's XFA **FormCalc engine** (lexer -> parser -> VM ->
38-builtin catalog, plan sec 4, Phase 3) end-to-end through
`pdf.RenderXFAForm`. The form is a realistic single-page "Order
Calculator" order summary: a customer/date header, a 3-line item table
(Widget/Gadget/Gizmo, each with bound quantity + unit price), and a
calculated summary block (line totals, subtotal, average price, item count,
a discount tier + discount amount, grand total), all wired up with
`<calculate><script contentType="application/x-formcalc">` bodies. 13
fields are bound to the `<xfa:datasets>` packet; 14 are calculate-only,
exercising `Sum`, `Avg`, `Round`, `Count`, `If`, `Concat`, `Upper`, `Left`,
`Date2Num`, `Num2Date`, `DateFmt` plus `*`/`-`/`>=`.

## Packet files are pre-split

`03_formcalc_calculations.template.xml` / `.datasets.xml` are raw bytes of
the original `.xdp`'s `<template>`/`<xfa:datasets>` subtrees (pre-split by
`examples\delphi\xfa\split_xfa_packets.cpp`) — read directly as bytes.

## How to run

```
"C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -NSSystem;Winapi;System.Win 03_formcalc_calculations.dpr
03_formcalc_calculations.exe
```

Writes `03_formcalc_calculations.render.pdf` alongside the exe.

## Verified output (pypdf `extract_text()`, this session)

Ran the built exe for real, then extracted page 1 text with `pypdf` — all
values match the hand-computed checklist exactly, identical to the flat
original:

| Field | Hand-computed | Rendered |
|---|---|---|
| `Item1Total`/`Item2Total`/`Item3Total` | 37.5 / 90 / 40 | `37.5` / `90` / `40` |
| `TotalQty` | 3+2+5=10 | `10` |
| `Subtotal` | 37.5+90+40=167.5 | `167.5` |
| `AvgUnitPrice` | round(21.8333,2)=21.83 | `21.83` |
| `ItemCount` | 3 | `3` |
| `DiscountLabel` | 167.5>=100 → Bulk Discount | `Bulk Discount` |
| `DiscountAmount` | round(16.75,2) | `16.75` |
| `GrandTotal` | 167.5-16.75=150.75 | `150.75` |
| `FullName` | Concat(Alex, " ", Nguyen) | `Alex Nguyen` |
| `CustomerInitial` | Upper(Left("Alex",1)) | `A` |
| `OrderDateNum` display | `Date2Num` epoch-converted | `2026-07-15` |
| `OrderDateFormatted` | `Num2Date(46217, "M/D/YY")` | `7/15/26` |

(The `OrderDateNum` display-text bug documented in the flat original's
README was already fixed in the shared engine before this OO port was
written — this port confirms the fix holds through the OO call surface
too.)

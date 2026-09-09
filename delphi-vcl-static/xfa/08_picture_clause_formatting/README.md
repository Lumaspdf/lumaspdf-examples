# 08 - Picture-Clause Formatting (VCL static component surface)

VCL-static-component port of
`examples\delphi\xfa\08_picture_clause_formatting`. Same `.xdp` fixture —
a one-page "Purchase Receipt" demonstrating the `<format><picture>`
formatter (`num{}`/`date{}`/`text{}`) applied both to plain bound data
values and to a value produced by a FormCalc `<calculate>` script, proving
the calculate-then-format pipeline order:

| Field | Mechanism | Picture | Raw value | Rendered text |
|---|---|---|---|---|
| `CustomerNameField` | bound | *(none)* | `"Acme Corp"` | `Acme Corp` |
| `UnitPriceField` | bound | `num{zzz,zz9.99}` | `"1875.50"` | `1,875.50` |
| `DiscountField` | bound, negative | `num{($zzz,zz9.99)}` | `"-125.00"` | `($125.00)` |
| `PurchaseDateField` | bound | `date{MMMM DD, YYYY}` | `"2026-07-24"` | `July 24, 2026` |
| `PhoneField` | bound | `text{999-999-9999}` | `"5551234567"` | `555-123-4567` |
| `GrandTotalField` | `<calculate>` (`Item1Price + Item2Price + Item3Price`) | `num{zzz,zz9.99}` | calculated `1875.50` | `1,875.50` |

## Driver

Reads the already pre-split `08_picture_clause_formatting.template.xml` /
`.datasets.xml` (no XML parsing needed) and drives the pipeline through
`TLumasPDFCore` (`wrappers\vcl\Lumas.Pdf.Wrap.Core.pas`), built
`LUMAS_STATIC`:

```
TLumasPDFCore.Create -> pdf.CreateNewPDFA -> pdf.CreateXFAStreamA('template',...) ->
pdf.CreateXFAStreamA('datasets',...) -> pdf.RenderXFAForm -> pdf.CloseFile -> pdf.Free
```

## Build + run

```bat
<repo root>\tools\build_vcl_static_app.bat <repo root>\examples\vcl_static\xfa\08_picture_clause_formatting 08_picture_clause_formatting.dpr
08_picture_clause_formatting.exe
```

No `LumasPdf.dll` needed — statically linked. Writes `output.pdf` in this
folder.

## Verified this session (pypdf, independent re-extraction of `output.pdf`)

```
Purchase Receipt -- Picture-Clause Formatting
Customer: Acme Corp
Unit Price: 1,875.50
Discount: ($125.00)
Date: July 24, 2026
Phone: 555-123-4567
845.25 620.00 410.25
Grand Total: 1,875.50
```

Byte-for-byte the same extracted text as the flat-Delphi original's own
README expects. `RenderXFAForm -> 1` (one page),
`RESULT|08_picture_clause_formatting=1`.

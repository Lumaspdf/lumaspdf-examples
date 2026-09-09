# 08 - Picture-Clause Formatting (VB.NET)

VB.NET port of `examples\delphi\xfa\08_picture_clause_formatting`.
Demonstrates the XFA `<format><picture>` formatter: real `num{}`/`date{}`/
`text{}` picture patterns applied both to plain **bound** data values and to
a value produced by a FormCalc **`<calculate>`** script, proving the
calculate-then-format pipeline order (the picture clause is applied to the
calc script's *result*, not skipped for calculated fields).

`08_picture_clause_formatting.template.xml` is a one-page "Purchase Receipt"
with:

| Field | Mechanism | Picture | Raw value | Rendered text |
|---|---|---|---|---|
| `CustomerNameField` | bound | *(none)* | `"Acme Corp"` | `Acme Corp` |
| `UnitPriceField` | bound | `num{zzz,zz9.99}` | `"1875.50"` | `1,875.50` |
| `DiscountField` | bound, negative | `num{($zzz,zz9.99)}` | `"-125.00"` | `($125.00)` |
| `PurchaseDateField` | bound | `date{MMMM DD, YYYY}` | `"2026-07-24"` | `July 24, 2026` |
| `PhoneField` | bound | `text{999-999-9999}` | `"5551234567"` | `555-123-4567` |
| `GrandTotalField` | **`<calculate>`** (`Item1Price+Item2Price+Item3Price`) | `num{zzz,zz9.99}` | calculated `1875.50` | `1,875.50` |

## Files

- `08_picture_clause_formatting.vb` -- console driver, reads the two
  pre-split packet files directly and renders through the standard
  `pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA(x2) ->
  pdfRenderXFAForm -> pdfCloseFile` pipeline.
- `08_picture_clause_formatting.template.xml` / `.datasets.xml` -- packet
  bytes, copied from the Delphi source example.
- `LumasPdf.dll` / `LumasPdf.VB.dll` -- engine DLL + VB.NET binding.

## How to run

```
"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\vbc.exe" /nologo /platform:x64 /r:"LumasPdf.VB.dll" /out:08_picture_clause_formatting.exe 08_picture_clause_formatting.vb
08_picture_clause_formatting.exe
```

Writes `08_picture_clause_formatting.pdf` alongside the exe.

## Verified output

`pdfRenderXFAForm` returns `1` (one page). `RESULT|08_picture_clause_formatting=1`.
Rendered text (extracted via `pypdf`, matches the Delphi original exactly):

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

`GrandTotalField` has no literal `<value>` of its own -- its rendered
`1,875.50` can only come from the calculate script actually running and the
picture formatter then being applied to that script's result, which is the
pipeline-order proof this example exists to demonstrate.

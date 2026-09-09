# 08 - Picture-Clause Formatting (Python)

Python (ctypes) port of `examples\delphi\xfa\08_picture_clause_formatting`.

Demonstrates the XFA dynamic engine's `<format><picture>` formatter: real
`num{}` / `date{}` / `text{}` picture patterns applied both to plain bound
data values and to a value produced by a FormCalc `<calculate>` script
(`GrandTotalField`), proving the calculate-then-format pipeline order (the
picture clause is applied to the calc script's *result*, not skipped for
calculated fields).

| Field | Mechanism | Picture | Raw value | Rendered text |
|---|---|---|---|---|
| `CustomerNameField` | bound | *(none)* | `Acme Corp` | `Acme Corp` |
| `UnitPriceField` | bound | `num{zzz,zz9.99}` | `1875.50` | `1,875.50` |
| `DiscountField` | bound, negative | `num{($zzz,zz9.99)}` | `-125.00` | `($125.00)` |
| `PurchaseDateField` | bound | `date{MMMM DD, YYYY}` | `2026-07-24` | `July 24, 2026` |
| `PhoneField` | bound | `text{999-999-9999}` | `5551234567` | `555-123-4567` |
| `GrandTotalField` | `<calculate>` (`Item1Price+Item2Price+Item3Price`) | `num{zzz,zz9.99}` | calculated `1875.50` | `1,875.50` |

## Files

- `08_picture_clause_formatting.template.xml` / `.datasets.xml` -- pre-split
  XFA packets, copied verbatim from the Delphi flavor's `.xdp` fixture.
- `08_picture_clause_formatting.py` -- the driver: `pdfNewPDF ->
  pdfCreateNewPDFA -> pdfCreateXFAStreamA` x2 `-> pdfSetXFAScriptEnabled(1)
  -> pdfRenderXFAForm -> pdfCloseFile`.

## How to run

```
python 08_picture_clause_formatting.py
```

Writes `08_picture_clause_formatting.pdf` alongside the script.

## Expected checklist (verified against the rendered PDF text via pypdf)

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

`pdfRenderXFAForm` returns page count `1`.

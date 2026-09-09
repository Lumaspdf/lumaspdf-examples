# 08 - Picture-Clause Formatting (C++)

C++ port of `examples\delphi\xfa\08_picture_clause_formatting`. Demonstrates
the XFA dynamic engine's `<format><picture>` formatter: real `num{}` /
`date{}` / `text{}` picture patterns applied both to plain **bound** data
values and to a value produced by a FormCalc **`<calculate>`** script,
proving the calculate-then-format pipeline order (the picture clause is
applied to the calc script's *result*, not skipped for calculated fields).

`08_picture_clause_formatting.template.xml` is a one-page "Purchase Receipt"
with:

| Field | Mechanism | Picture | Raw value | Rendered text |
|---|---|---|---|---|
| `CustomerNameField` | bound | *(none)* | `"Acme Corp"` | `Acme Corp` |
| `UnitPriceField` | bound | `num{zzz,zz9.99}` | `"1875.50"` | `1,875.50` |
| `DiscountField` | bound, negative | `num{($zzz,zz9.99)}` | `"-125.00"` | `($125.00)` |
| `PurchaseDateField` | bound | `date{MMMM DD, YYYY}` | `"2026-07-24"` | `July 24, 2026` |
| `PhoneField` | bound | `text{999-999-9999}` | `"5551234567"` | `555-123-4567` |
| `Item1Price`/`Item2Price`/`Item3Price` | bound | *(none)* | `845.25`/`620.00`/`410.25` | as-is |
| `GrandTotalField` | **`<calculate>`** (`Item1Price + Item2Price + Item3Price`) | `num{zzz,zz9.99}` | calculated `1875.50` | `1,875.50` |

`GrandTotalField` has no literal `<value>` of its own -- its rendered
`1,875.50` can only come from the calculate script actually running and the
picture formatter then being applied to that script's result.

## Files

- `08_picture_clause_formatting.cpp` -- console driver.
- `08_picture_clause_formatting.template.xml` / `.datasets.xml` -- pre-split
  XFA packets (raw bytes, no XML parsing needed).
- `LumasPdf.dll` -- a copy of the engine DLL.

## How to build and run

```bat
<repo root>\examples\cpp\xfa\build_xfa.bat
```

then run `08_picture_clause_formatting.exe` from its own directory. Writes
`08_picture_clause_formatting.pdf` alongside itself. Does not rebuild
`LumasPdf.dll`.

## Verified output

Ran for real: `pdfRenderXFAForm` returns `1` (one page). Extracted text via
pypdf matches exactly:

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

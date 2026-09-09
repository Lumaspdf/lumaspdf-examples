# 8 -- Picture-Clause Formatting (C)

C port of `examples\delphi\xfa\08_picture_clause_formatting`. Demonstrates
the XFA dynamic engine's `<format><picture>` formatter: real `num{}` /
`date{}` / `text{}` picture patterns applied both to plain **bound** data
values and to a value produced by a FormCalc **`<calculate>`** script,
proving the calculate-then-format pipeline order (the picture clause is
applied to the calc script's *result*, not skipped for calculated fields).

`GrandTotalField` has no literal `<value>` of its own -- its rendered
`1,875.50` can only come from the calculate script (`Item1Price +
Item2Price + Item3Price`) actually running and the picture formatter then
being applied to that script's result.

## Files

- `08_picture_clause_formatting.c` -- console driver. Explicitly calls
  `pdfSetXFAScriptEnabled(pdf, 1)` before rendering (belt-and-braces -- the
  engine defaults this on already, but this example's whole point is the
  calculate-then-format pipeline, so it does not rely on an implicit
  default).
- `08_picture_clause_formatting.template.xml` / `08_picture_clause_formatting.datasets.xml`
  -- pre-split packet bytes.
- `LumasPdf.dll` -- copy of the already-built engine DLL.

## How to build + run

```bat
"C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
cl /nologo /I "<repo root>\wrappers\c" 08_picture_clause_formatting.c /Fe:08_picture_clause_formatting.exe /link "<repo root>\wrappers\c\LumasPdf.x64.lib"
08_picture_clause_formatting.exe
```

Writes `08_picture_clause_formatting.pdf` alongside the exe.

## Expected checklist

| Field | Mechanism | Picture | Raw value | Rendered text |
|---|---|---|---|---|
| `CustomerNameField` | bound | *(none)* | `Acme Corp` | `Acme Corp` |
| `UnitPriceField` | bound | `num{zzz,zz9.99}` | `1875.50` | `1,875.50` |
| `DiscountField` | bound, negative | `num{($zzz,zz9.99)}` | `-125.00` | `($125.00)` |
| `PurchaseDateField` | bound | `date{MMMM DD, YYYY}` | `2026-07-24` | `July 24, 2026` |
| `PhoneField` | bound | `text{999-999-9999}` | `5551234567` | `555-123-4567` |
| `GrandTotalField` | `<calculate>` | `num{zzz,zz9.99}` | calculated `1875.50` | `1,875.50` |

Full expected extracted text:

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

## Verified

Built and run for real; `pdfRenderXFAForm` returned `1`. Independently
confirmed via `pypdf` text extraction -- the rendered text matches the block
above **exactly**, byte for byte, including `GrandTotalField`'s `1,875.50`
landing on the same displayed number as `UnitPriceField` despite one being a
plain bound value and the other a FormCalc sum -- proof the
calculate-then-format pipeline order is correct.

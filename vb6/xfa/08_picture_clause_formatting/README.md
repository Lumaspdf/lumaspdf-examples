# 08 - Picture-Clause Formatting (VB6)

VB6 port of `examples\delphi\xfa\08_picture_clause_formatting`. Demonstrates
the XFA dynamic engine's `<format><picture>` formatter: real `num{}` /
`date{}` / `text{}` picture patterns applied both to plain **bound** data
values and to a value produced by a FormCalc **`<calculate>`** script,
proving the calculate-then-format pipeline order.

| Field | Mechanism | Picture | Raw value | Rendered text |
|---|---|---|---|---|
| `CustomerNameField` | bound | *(none)* | `"Acme Corp"` | `Acme Corp` |
| `UnitPriceField` | bound | `num{zzz,zz9.99}` | `"1875.50"` | `1,875.50` |
| `DiscountField` | bound, negative | `num{($zzz,zz9.99)}` | `"-125.00"` | `($125.00)` |
| `PurchaseDateField` | bound | `date{MMMM DD, YYYY}` | `"2026-07-24"` | `July 24, 2026` |
| `PhoneField` | bound | `text{999-999-9999}` | `"5551234567"` | `555-123-4567` |
| `GrandTotalField` | `<calculate>` (`Item1Price + Item2Price + Item3Price`) | `num{zzz,zz9.99}` | calculated `1875.50` | `1,875.50` |

## Files

Same layout convention as every other example: pre-split
`08_picture_clause_formatting.template.xml`/`.datasets.xml` packets, a
native-C-API-style `08_picture_clause_formatting.bas` driver + `.vbp`
project file, and a bundled 32-bit `LumasPdf.dll`.

## How to build + run

```
"C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" /make 08_picture_clause_formatting.vbp
08_picture_clause_formatting.exe
```

Writes `08_picture_clause_formatting.pdf` alongside the exe.

Note: the `.vbp`'s internal `Name=` is the shortened `picture_clause_fmt`,
not the full folder name -- VB6 rejects any project `Name` that would make
a `Name.CPDFContentParser` Programmatic ID exceed 39 characters (a hard
VB6 IDE limit hit by the full `picture_clause_formatting` name). The
`.exe`/folder/file names are unaffected; only the internal project
identity is shortened.

## Verified output (rendered PDF page 1 text, via pypdf)

Built with `VB6.EXE /make`, run for real -- the extracted text is a
byte-for-byte match with the Delphi original's own verified output:

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
`1,875.50` can only come from the calculate script actually running and
the picture formatter then being applied to that script's result.

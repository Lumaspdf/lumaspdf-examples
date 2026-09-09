# 08 — Picture-Clause Formatting (ActiveX/COM)

ActiveX/COM port of `examples\delphi\xfa\08_picture_clause_formatting`. See
`..\README.md` for why this tour uses PowerShell rather than VBScript.

Demonstrates the XFA `<format><picture>` formatter: real `num{}`/`date{}`/
`text{}` picture patterns applied both to plain bound data values and to a
value produced by a FormCalc `<calculate>` script, proving the
calculate-then-format pipeline order (the picture clause is applied to the
calc script's *result*, not skipped for calculated fields).

`08_picture_clause_formatting.xdp` is a one-page "Purchase Receipt":

| Field | Mechanism | Picture | Raw value | Rendered text |
|---|---|---|---|---|
| `CustomerNameField` | bound | (none) | `"Acme Corp"` | `Acme Corp` |
| `UnitPriceField` | bound | `num{zzz,zz9.99}` | `"1875.50"` | `1,875.50` |
| `DiscountField` | bound, negative | `num{($zzz,zz9.99)}` | `"-125.00"` | `($125.00)` |
| `PurchaseDateField` | bound | `date{MMMM DD, YYYY}` | `"2026-07-24"` | `July 24, 2026` |
| `PhoneField` | bound | `text{999-999-9999}` | `"5551234567"` | `555-123-4567` |
| `GrandTotalField` | **`<calculate>`** (`Item1Price+Item2Price+Item3Price`) | `num{zzz,zz9.99}` | calculated `1875.50` | `1,875.50` |

## Run

```
powershell -File 08_picture_clause_formatting.ps1
```

## Verified output (pypdf text extraction of page 1)

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

Exact match with the Delphi reference's own checklist, including
`GrandTotalField` — which has no literal `<value>` of its own, so its
rendered `1,875.50` can only come from the calculate script actually running
and the picture formatter then being applied to that script's result.

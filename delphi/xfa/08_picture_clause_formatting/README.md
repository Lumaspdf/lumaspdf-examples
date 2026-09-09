# 8 — Picture-Clause Formatting

Demonstrates the XFA dynamic engine's `<format><picture>` formatter
(`XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md` sec 6.4, implemented in
`Lumas.Pdf.Xfa.Picture.pas`, wired into `Lumas.Pdf.Xfa.Bind.
XfaResolveDisplayText`): real `num{}` / `date{}` / `text{}` picture patterns
applied both to plain **bound** data values and to a value produced by a
FormCalc **`<calculate>`** script, proving the calculate-then-format
pipeline order (the picture clause is applied to the calc script's *result*,
not skipped for calculated fields).

`08_picture_clause_formatting.xdp` is a one-page "Purchase Receipt" with:

| Field | Mechanism | Picture | Raw value | Rendered text |
|---|---|---|---|---|
| `CustomerNameField` | bound | *(none — control case)* | `"Acme Corp"` | `Acme Corp` |
| `UnitPriceField` | bound | `num{zzz,zz9.99}` | `"1875.50"` | `1,875.50` |
| `DiscountField` | bound, **negative** | `num{($zzz,zz9.99)}` | `"-125.00"` | `($125.00)` |
| `PurchaseDateField` | bound | `date{MMMM DD, YYYY}` | `"2026-07-24"` | `July 24, 2026` |
| `PhoneField` | bound | `text{999-999-9999}` | `"5551234567"` | `555-123-4567` |
| `Item1Price`/`Item2Price`/`Item3Price` | bound | *(none — calc inputs)* | `845.25`/`620.00`/`410.25` | as-is |
| `GrandTotalField` | **`<calculate>`** (`Item1Price + Item2Price + Item3Price`) | `num{zzz,zz9.99}` | calculated `1875.50` | `1,875.50` |

`GrandTotalField` has no literal `<value>` of its own and a bound fallback of
`"0.00"` — its rendered `1,875.50` can only come from the calculate script
actually running and the picture formatter then being applied to that
script's result, which is the pipeline-order proof this example exists to
demonstrate. It deliberately lands on the exact same displayed number as
`UnitPriceField` (both `1,875.50`) despite one being a plain bound value and
the other a FormCalc sum — same picture pattern, two different value
pipelines, identical output.

Picture vocabulary used here is the real, spec-verified subset established
by this project's `xfa_fixtures\fx08_picture.xdp` / `fx09_combined.xdp` /
`fx15_pictureedge.xdp` and their `XFA_FIXTURE_EXPECTATIONS.md` sections:
`num{}` digit tokens `9`/`z`, group/decimal `,`/`.`, `$` currency, and `(`/`)`
negative-value parens; `date{}` `MMMM`/`DD`/`YYYY` tokens; `text{}` `9`
digit-slot tokens with literal `-` separators. It deliberately does **not**
use locale-suffixed segments (`num(en_US){...}`), multi-subpicture
`display|edit|dataFormat` triads, or the `cr`/`db` credit/debit num{} tokens
— all disclosed, not-yet-spec-verified gaps in `Lumas.Pdf.Xfa.Picture.pas`
(see that unit's own header), out of scope for this example.

## How to run

This is a standalone driver — it links only against the already-built
`wrappers\delphi\LumasPdf.pas` and the already-built `LumasPdf.dll`. It does
**not** call `tools\build_dll.bat` and does not rebuild the engine.

```
build_and_run.bat
```

or manually:

```
dcc64 -B -CC -Q "-U..\..\..\..\src;..\..\..\..\wrappers\delphi" 08_picture_clause_formatting.dpr
copy /y <repo root>\LumasPdf.dll .
08_picture_clause_formatting.exe
```

Expect `RESULT|08_picture_clause_formatting=1` (one page rendered) and
`08_picture_clause_formatting.pdf` written alongside the `.exe`. Verify with
any text extractor (e.g. `pypdf`) — the extracted text should read:

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

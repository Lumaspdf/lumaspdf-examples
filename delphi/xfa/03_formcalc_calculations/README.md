# 03 - FormCalc Calculations

Demonstrates LumasPDF's XFA **FormCalc engine** (lexer -> parser -> VM ->
38-builtin catalog, plan sec 4, Phase 3) end-to-end through the real
`pdfRenderXFAForm` export. The form is a realistic single-page "Order
Calculator" order summary: a customer/date header, a 3-line item table
(Widget/Gadget/Gizmo, each with bound quantity + unit price), and a
calculated summary block (line totals, subtotal, average price, item count,
a discount tier + discount amount, grand total), all wired up with
`<calculate><script contentType="application/x-formcalc">` bodies.

13 fields are bound to the `<xfa:datasets>` packet (`bind match="dataRef"`);
14 fields are calculate-only (`bind match="none"`) and hold a FormCalc
script each.

**Only the real v1 FormCalc builtins exist in this engine** (per
`xfa_fixtures/XFA_FIXTURE_EXPECTATIONS.md`'s fx03 scope note) — this example
uses exactly these 11, from 3 of the 4 catalog categories, plus core
arithmetic/comparison operators:

| Category | Builtins used here |
|---|---|
| Arithmetic | `Sum`, `Avg`, `Round`, `Count` |
| Logical | `If` |
| String | `Concat`, `Upper`, `Left` |
| Date/Time | `Date2Num`, `Num2Date`, `DateFmt` |
| Operators | `*`, `-`, `>=` |

No financial/`WordNum`/`Uuid`/`Encode`/`Decode` functions are used anywhere
— those simply do not exist in this engine's v1 catalog.

## Calculation graph

| Field | Script | Builtins/operators exercised |
|---|---|---|
| `Item1Total`/`Item2Total`/`Item3Total` | `ItemNQty * ItemNPrice` | `*` |
| `TotalQty` | `Sum(Item1Qty, Item2Qty, Item3Qty)` | `Sum()` over bound sibling fields |
| `Subtotal` | `Sum(Item1Total, Item2Total, Item3Total)` | `Sum()` over calculated sibling fields |
| `AvgUnitPrice` | `Round(Avg(Item1Price, Item2Price, Item3Price), 2)` | nested `Avg()` + `Round()` |
| `ItemCount` | `Count(Item1Qty, Item2Qty, Item3Qty)` | `Count()` |
| `DiscountLabel` | `If(Subtotal >= DiscountThreshold, "Bulk Discount", "Standard")` | `If()` + `>=`, data-driven threshold |
| `DiscountAmount` | `If(Subtotal >= DiscountThreshold, Round(Subtotal * 0.10, 2), 0)` | `If()` + `Round()` + `*` |
| `GrandTotal` | `Subtotal - DiscountAmount` | `-` |
| `FullName` | `Concat(CustomerFirstName, " ", CustomerLastName)` | `Concat()` |
| `CustomerInitial` | `Upper(Left(CustomerFirstName, 1))` | `Left()` + `Upper()` |
| `OrderDateNum` | `Date2Num(OrderDate)` | `Date2Num()` |
| `OrderDateFormatted` | `Num2Date(OrderDateNum, DateFmt(1))` | `Num2Date()` + `DateFmt()`, sibling ref |

## Dataset (`$data.Order`)

```
Customer: FirstName=Alex, LastName=Nguyen
OrderDate: "Jul 15, 2026"
DiscountThreshold: 100
Item1 (Widget): Qty=3, Price=12.50
Item2 (Gadget): Qty=2, Price=45.00
Item3 (Gizmo):  Qty=5, Price=8.00
```

## Hand-verification (expected vs. actual rendered text)

Computed by hand against the dataset above, then cross-checked against the
actual rendered PDF's text (extracted independently two ways: PyMuPDF's
`page.get_text()` and `pypdf`'s raw content-stream decompression — both
agree with each other and with the numbers below).

| Field | Hand-computed | Rendered | Match |
|---|---|---|---|
| `Item1Total` | 3 x 12.50 = 37.5 | `37.5` | yes |
| `Item2Total` | 2 x 45.00 = 90 | `90` | yes |
| `Item3Total` | 5 x 8.00 = 40 | `40` | yes |
| `TotalQty` | 3+2+5 = 10 | `10` | yes |
| `Subtotal` | 37.5+90+40 = 167.5 | `167.5` | yes |
| `AvgUnitPrice` | (12.50+45.00+8.00)/3 = 21.8333... -> round 2dp = 21.83 | `21.83` | yes |
| `ItemCount` | 3 non-null args | `3` | yes |
| `DiscountLabel` | 167.5 >= 100 is true -> "Bulk Discount" | `Bulk Discount` | yes |
| `DiscountAmount` | 167.5 x 0.10 = 16.75, round 2dp = 16.75 | `16.75` | yes |
| `GrandTotal` | 167.5 - 16.75 = 150.75 | `150.75` | yes |
| `FullName` | "Alex" + " " + "Nguyen" = "Alex Nguyen" | `Alex Nguyen` | yes |
| `CustomerInitial` | Upper(Left("Alex",1)) = Upper("A") = "A" | `A` | yes |
| `OrderDateNum` (underlying value) | `Date2Num("Jul 15, 2026")`, default picture `MMM D, YYYY`, epoch day1=Jan 1 1900 -> day **46217** (hand-verified: `(2026-07-15 - 1900-01-01).Days + 1 = 46217`, and independently cross-checked against the engine's own W3C-verified epoch rule, `Date2Num("Mar 15, 1996")=35138`, using the same day-count formula) | `2026-07-15` | yes |
| `OrderDateFormatted` | `Num2Date(46217, "M/D/YY")` -> `7/15/26` (`DateFmt(1)` is separately verified elsewhere in this engine's own test suite to equal `"M/D/YY"`) | `7/15/26` | yes |

### `OrderDateNum`'s displayed text — bug found here, FIXED 2026-07-24

The field's *underlying* FormCalc value was always correct — proof:
`OrderDateFormatted` re-derives `Date2Num`'s own sibling-field result
(`OrderDateNum`) through `Num2Date(OrderDateNum, DateFmt(1))` and gets the
exactly-right `7/15/26`, which could only happen if the stored day-count
really is 46217.

What was wrong was only the **auto-render of a raw, un-formatted `xvkDate`
value straight to page text**. `Lumas.Pdf.Xfa.Bind.pas`'s
`XfaValueDisplayText` (`xvkDate` branch) did
`FormatDateTime('yyyy-mm-dd', V.F, ...)` treating `V.F` (the FormCalc
day-count, epoch day1=Jan 1 1900) as if it were already a **Delphi**
`TDateTime` ordinal (epoch day0=Dec 30 1899) — it never converted through
`XfaFcDayToDelphiDate` the way `Num2Date` itself correctly does. Since the
two epochs differ, this yielded a date exactly one calendar day early
(`2026-07-14` instead of `2026-07-15`).

**Fixed**: `XfaValueDisplayText`'s `xvkDate` branch now converts `V.F`
through `XfaFcDayToDelphiDate` before formatting, matching `Num2Date`'s own
convention. `LumasPdf.dll` rebuilt; this example re-run and now shows the
correct `2026-07-15`.

## How to run

```
build_03_formcalc_calculations.bat
```

This compiles `03_formcalc_calculations.dpr` with `dcc64` against the
already-built `wrappers\delphi\LumasPdf.pas`/`src\Lumas.Pdf.Xml.pas` (no
engine rebuild), copies `<repo root>\LumasPdf.dll` next to the resulting
`.exe` (Windows DLL search order convention used by every `examples\*`
driver in this project), and runs it. It reads
`03_formcalc_calculations.xdp` from its own directory and writes
`03_formcalc_calculations.render.pdf` alongside it.

Or manually:

```
dcc64 -B -CC -Q "-U..\..\..\..\src;..\..\..\..\wrappers\delphi" 03_formcalc_calculations.dpr
copy /y <repo root>\LumasPdf.dll .
03_formcalc_calculations.exe
```

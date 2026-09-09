# 6 -- Multi-Page Pagination (C)

C port of `examples\delphi\xfa\06_pagination_multipage`. Demonstrates full
multi-page pagination: `pageSet`/`pageArea`/`contentArea`, forced overflow of
a repeating row template across several pages, and leader/trailer
"continued" banner subforms via `<overflow leader=... trailer=...>`.

Scenario: an "Invoice Line Items" report for Acme Robotics and Automation
Inc., invoice `INV-2026-0724`, with **70** line items (`Description`/`Qty`/
`Amount` per row, `occur min="1" max="-1"`), bound to
`$data.Invoice.LineItems.Line`. A one-time `InvoiceHeader` banner sits above
the table on page 1 only. `pageSet relation="orderedOccurrence"` has two
`pageArea`s: `Page1` (used once) and `Page2` (`<occur max="-1"/>`, repeats
for every continuation page).

## Hand-derived page-count arithmetic

`contentArea` is `400pt` tall (`x=36 y=36 w=540 h=400`), rows/leader/trailer
are `20pt` each. Trailer height is reserved on every page's capacity math
unconditionally; leader height is reserved on every page except the first.

- First page capacity = `floor((400-20)/20)` = **19** rows.
- Every continuation page capacity = `floor((400-20-20)/20)` = **18** rows.

Greedy simulation over 70 rows: `19 + 18 + 18 + 15 = 70` -> **4 pages total**.

This value (`4`) is hard-coded as `EXPECTED_PAGE_COUNT` in the C driver and
asserted against **both** the pre-flight `pdfXFAFormPageCount` call and the
actual `pdfRenderXFAForm` return value, mirroring the Delphi example's
`CheckPageCount=4` driver argument exactly.

## Files

- `06_pagination_multipage.c` -- console driver.
- `06_pagination_multipage.template.xml` / `06_pagination_multipage.datasets.xml`
  -- pre-split packet bytes (the datasets packet is ~8KB -- 70 `<Line>`
  records).
- `LumasPdf.dll` -- copy of the already-built engine DLL.

## How to build + run

```bat
"C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
cl /nologo /I "<repo root>\wrappers\c" 06_pagination_multipage.c /Fe:06_pagination_multipage.exe /link "<repo root>\wrappers\c\LumasPdf.x64.lib"
06_pagination_multipage.exe
```

Writes `06_pagination_multipage.pdf` (4 pages) alongside the exe.

## Expected checklist

| Page (0-based) | Row range | Row count | Leader? | Trailer? |
|---|---|---|---|---|
| 0 | 1-19 | 19 | no | yes |
| 1 | 20-37 | 18 | yes | yes |
| 2 | 38-55 | 18 | yes | yes |
| 3 | 56-70 | 15 | yes | no (true last page) |

Total pages: **4**.

## Verified

Built and run for real; `pdfXFAFormPageCount` (pre-flight) returned `4`,
matching the hand-derivation, and `pdfRenderXFAForm` also returned `4`,
agreeing with the pre-flight query. Independently confirmed via `pypdf`:
`len(reader.pages) == 4`, and per-page leader/trailer text presence matches
the table above exactly (leader on every page except the first, trailer on
every page except the last).

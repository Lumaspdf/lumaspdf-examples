# 06 - Multi-Page Pagination (C++)

C++ port of `examples\delphi\xfa\06_pagination_multipage`. Demonstrates full
multi-page pagination: `pageSet`/`pageArea`/`contentArea`, forced overflow of
a repeating row template across several pages, and leader/trailer
"continued" banner subforms via `<overflow leader=... trailer=...>`.

A realistic "Invoice Line Items" report for **Acme Robotics and Automation
Inc.**, invoice `INV-2026-0724`, with **70** line items
(`Description`/`Qty`/`Amount` per row, `occur min="1" max="-1"`), bound to
`$data.Invoice.LineItems.Line`. `contentArea` is 400pt tall, rows 20pt,
leader/trailer 20pt each.

## Hand-derived page-count arithmetic

- **First page** capacity = `floor((400-20)/20)` = **19** rows (trailer
  height always reserved, no leader).
- **Every continuation page** capacity = `floor((400-20-20)/20)` = **18**
  rows (both leader and trailer height reserved, even on the true last page).

| Page (0-based) | Row range | Row count | Leader? | Trailer box drawn? |
|---|---|---|---|---|
| 0 | 1-19  | 19 | no  | yes |
| 1 | 20-37 | 18 | yes | yes |
| 2 | 38-55 | 18 | yes | yes |
| 3 | 56-70 | 15 | yes | no (true last page) |

`19 + 18 + 18 + 15 = 70`. **Total pages: 4.**

## Files

- `06_pagination_multipage.cpp` -- console driver. Additionally calls
  `pdfXFAFormPageCount` as a pre-flight check (before `pdfRenderXFAForm`)
  and asserts it equals 4, mirroring the Delphi driver's
  `CheckPageCount=4` assertion.
- `06_pagination_multipage.template.xml` / `.datasets.xml` -- pre-split XFA
  packets (raw bytes, no XML parsing needed).
- `LumasPdf.dll` -- a copy of the engine DLL.

## How to build and run

```bat
<repo root>\examples\cpp\xfa\build_xfa.bat
```

then run `06_pagination_multipage.exe` from its own directory. Writes
`06_pagination_multipage.pdf` alongside itself. Does not rebuild
`LumasPdf.dll`.

## Verified output

Ran for real: `pdfXFAFormPageCount` (pre-flight) -> **4**, matching the
hand-derivation exactly. `pdfRenderXFAForm` -> **4**, agreeing with the
pre-flight query. PDF page count confirmed independently via
`pypdf.PdfReader` -> `len(reader.pages) == 4`.

Content-stream verification (via pypdf, in raw emission order):

| Page | Leader | Trailer | Description strings found | Row range |
|---|---|---|---|---|
| 0 | no  | yes | 19 | 1-19 |
| 1 | yes | yes | 18 | 20-37 |
| 2 | yes | yes | 18 | 38-55 |
| 3 | yes | no  | 15 | 56-70 |

Leader (`"(continued from previous page)"`) appears on every page except the
first; trailer text never appears on the last page. Concatenating every
page's `Description` strings in emission order and comparing against the 70
authored records: exact match, 70-for-70, no gaps, no duplicates, no
reordering.

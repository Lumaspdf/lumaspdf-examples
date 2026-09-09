# 06 - Multi-Page Pagination (Python)

Python (ctypes) port of `examples\delphi\xfa\06_pagination_multipage`.

Demonstrates full multi-page pagination: `pageSet`/`pageArea`/`contentArea`,
forced overflow of a repeating row template across several pages, and
leader/trailer "continued" banner subforms via
`<overflow leader=... trailer=...>`.

Scenario: an "Invoice Line Items" report for Acme Robotics and Automation
Inc., invoice `INV-2026-0724`, with **70** line items
(`Description`/`Qty`/`Amount` per row, `occur min="1" max="-1"`), bound to
`$data.Invoice.LineItems.Line`. Geometry: a 400pt-tall `contentArea`
(`x=36 y=36 w=540 h=400`), 20pt rows, 20pt leader/trailer.

## Files

- `06_pagination_multipage.template.xml` / `.datasets.xml` -- pre-split XFA
  packets, copied verbatim from the Delphi flavor's `.xdp` fixture.
- `06_pagination_multipage.py` -- the driver: `pdfNewPDF -> pdfCreateNewPDFA
  -> pdfCreateXFAStreamA` x2 `-> pdfXFAFormPageCount` (pre-flight) `->
  pdfRenderXFAForm -> pdfCloseFile`. Asserts the pre-flight page count and the
  actual render page count both equal `4`.

## How to run

```
python 06_pagination_multipage.py
```

Writes `06_pagination_multipage.pdf` alongside the script.

## Hand-derived page-count arithmetic

First page capacity = `floor((400-20)/20)` = **19** rows. Every continuation
page capacity = `floor((400-20-20)/20)` = **18** rows (trailer height is
reserved on every page unconditionally; leader height is reserved on every
page except the first).

| Page (0-based) | Row range | Row count | Leader? | Trailer drawn? |
|---|---|---|---|---|
| 0 | 1-19 | 19 | no | yes |
| 1 | 20-37 | 18 | yes | yes |
| 2 | 38-55 | 18 | yes | yes |
| 3 | 56-70 | 15 | yes | no (true last page) |

`19 + 18 + 18 + 15 = 70` -- matches the 70 authored `<Line>` records exactly.
**Total pages: 4.**

## Expected checklist

`pdfXFAFormPageCount` (pre-flight) -> `4`. `pdfRenderXFAForm` -> `4`. PDF page
count (independently confirmed via `pypdf.PdfReader`) -> `4`. Leader text
("...continued from previous page)") appears on every page except the first;
trailer text ("(continued on next page)") appears on every page except the
last. Concatenating every page's `Description` strings in emission order
matches the 70 authored records exactly, no gaps/duplicates/reordering.

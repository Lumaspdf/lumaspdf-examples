# 06 - Multi-Page Pagination (C#)

C# port of `examples\delphi\xfa\06_pagination_multipage`. Demonstrates full
multi-page pagination: `pageSet`/`pageArea`/`contentArea`, forced overflow of
a repeating row template across several pages, and leader/trailer "continued"
banner subforms via `<overflow leader=... trailer=...>`.

A realistic "Invoice Line Items" report for Acme Robotics and Automation
Inc., invoice `INV-2026-0724`, with **70** line items
(`Description`/`Qty`/`Amount` per row, `layout="row"`, `occur min="1"
max="-1"`), bound to `$data.Invoice.LineItems.Line`. A one-time
`InvoiceHeader` banner sits above the table on page 1 only.

`pageSet relation="orderedOccurrence"` has two `pageArea`s: `Page1` (used
once, first) and `Page2` (`<occur max="-1"/>`, repeats for every continuation
page). `LineItemsTable`'s `<overflow leader="ContinuedFromPrevious"
trailer="ContinuedOnNext"/>` names the two banner subforms.

## Hand-derived page-count arithmetic

Constants: `ContentY=36`, `ContentH=400`, `RowH=20`, `LeaderH=TrailerH=20`.
Trailer height is reserved on every page's capacity math unconditionally;
leader height is reserved on every page opened by an advance (all but the
first); the trailer box itself is only drawn when the paginator actually
advances further (so the true last page never shows it).

- First page capacity = `floor((400-20)/20)` = **19** rows.
- Every continuation page capacity = `floor((400-20-20)/20)` = **18** rows.

Greedy simulation over 70 rows: `19 + 18 + 18 + 15 = 70`. **Total pages: 4.**

## Files

- `06_pagination_multipage.cs` -- console driver (queries
  `pdfXFAFormPageCount` pre-flight, before `pdfRenderXFAForm`, and checks
  both against the expected page count of 4).
- `06_pagination_multipage.template.xml` / `.datasets.xml` -- pre-split packets.
- `LumasPdf.dll` / `LumasPdf.Net.dll` -- engine DLL + P/Invoke wrapper.

## Pipeline

```
pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA("template",...) ->
pdfCreateXFAStreamA("datasets",...) -> pdfXFAFormPageCount (pre-flight) ->
pdfRenderXFAForm -> pdfCloseFile
```

## Build + run

```
powershell -File ..\..\build_one.ps1 xfa\06_pagination_multipage 06_pagination_multipage.cs
.\06_pagination_multipage.exe
```

Writes `06_pagination_multipage.pdf` alongside the exe.

## Expected checklist

| Page (0-based) | Row range (1-based) | Row count | Leader? | Trailer drawn? |
|---|---|---|---|---|
| 0 | 1-19 | 19 | no | yes |
| 1 | 20-37 | 18 | yes | yes |
| 2 | 38-55 | 18 | yes | yes |
| 3 | 56-70 | 15 | yes | **no** (true last page) |

`19+18+18+15 = 70` line items, matching all 70 authored `<Line>` records.
`pdfXFAFormPageCount` (pre-flight) and `pdfRenderXFAForm` should both return
`4`.

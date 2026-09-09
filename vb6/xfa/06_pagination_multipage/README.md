# 06 - Multi-Page Pagination (VB6)

VB6 port of `examples\delphi\xfa\06_pagination_multipage`. Demonstrates
full multi-page pagination: `pageSet`/`pageArea`/`contentArea`, forced
overflow of a repeating row template across several pages, and
leader/trailer "continued" banner subforms via `<overflow leader=...
trailer=...>`.

A realistic "Invoice Line Items" report for Acme Robotics and Automation
Inc., invoice `INV-2026-0724`, with **70** line items bound to
`$data.Invoice.LineItems.Line`, geometry scaled up from the engine's own
`fx06_pagination.xdp` oracle fixture (400pt-tall `contentArea`, 20pt rows,
20pt leader/trailer) to force **4** pages of overflow.

Per the hand-derivation in the Delphi original's README (first page holds
19 rows, each continuation page holds 18, trailer space reserved
unconditionally on every page, leader drawn on every page except the
first, trailer box skipped only on the true last page): `19 + 18 + 18 + 15
= 70`, **4 pages total**.

This VB6 driver mirrors that check: it calls `pdf.XFAFormPageCount()`
**pre-flight** (before any page is appended -- same export the Delphi
driver calls, `pdfXFAFormPageCount`) and asserts it equals 4, then calls
`pdf.RenderXFAForm()` and asserts the actual page count also equals 4.

## Files

Same layout convention as every other example: pre-split
`06_pagination_multipage.template.xml`/`.datasets.xml` packets, a
native-C-API-style `06_pagination_multipage.bas` driver + `.vbp` project
file, and a bundled 32-bit `LumasPdf.dll`.

## How to build + run

```
"C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" /make 06_pagination_multipage.vbp
06_pagination_multipage.exe
```

Writes `06_pagination_multipage.pdf` alongside the exe.

## Verified output (via pypdf)

Built with `VB6.EXE /make`, run for real:

- `pdf.XFAFormPageCount()` pre-flight -> **4**, matching the hand-derivation.
- `pdf.RenderXFAForm()` -> **4**, agreeing with the pre-flight query.
- PDF page count confirmed independently via `pypdf.PdfReader` -> `len(reader.pages) == 4`.
- Content-stream check per page (leader/trailer banner presence):

| Page | Leader present | Trailer present |
|---|---|---|
| 0 | no | yes |
| 1 | yes | yes |
| 2 | yes | yes |
| 3 | yes | **no** (true last page) |

Leader appears on every page except the first; trailer appears on every
page except the last -- matches the Delphi original's own verified output
exactly.

# 06 - Multi-Page Pagination (VB.NET)

VB.NET port of `examples\delphi\xfa\06_pagination_multipage`. Demonstrates
full multi-page pagination: `pageSet`/`pageArea`/`contentArea`, forced
overflow of a repeating row template across several pages, and
leader/trailer "continued" banner subforms via
`<overflow leader=... trailer=...>`.

A realistic "Invoice Line Items" report for Acme Robotics and Automation
Inc., invoice `INV-2026-0724`, with **70** line items (`layout="row"`,
`occur min="1" max="-1"`), bound to `$data.Invoice.LineItems.Line`. A
one-time `InvoiceHeader` banner sits above the table on page 1 only.

## Hand-derived page-count arithmetic

`contentArea` 400pt tall, `20pt` rows, `20pt` leader/trailer. Trailer height
is reserved on every page's capacity math unconditionally; leader height is
reserved on every page except the first.

- First page capacity: `floor((400-20)/20)` = **19** rows.
- Continuation page capacity: `floor((400-20-20)/20)` = **18** rows.

Greedy simulation over 70 rows: page 0 = 19 rows (no leader, trailer drawn),
page 1 = 18 rows (leader+trailer), page 2 = 18 rows (leader+trailer), page 3
= 15 rows (leader, **no trailer** -- true last page). `19+18+18+15=70`.
**Total pages: 4.**

This driver calls `pdfXFAFormPageCount` (pre-flight, before any page is
appended) and asserts it equals 4 before calling `pdfRenderXFAForm`, then
asserts the render's own return value also equals 4 -- same
`CheckPageCount=4` convention as the Delphi original.

## Files

- `06_pagination_multipage.vb` -- console driver, reads the two pre-split
  packet files directly, calls `pdfXFAFormPageCount` pre-flight, then
  renders through `pdfRenderXFAForm -> pdfCloseFile`.
- `06_pagination_multipage.template.xml` / `.datasets.xml` -- packet bytes,
  copied from the Delphi source example.
- `LumasPdf.dll` / `LumasPdf.VB.dll` -- engine DLL + VB.NET binding.

## How to run

```
"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\vbc.exe" /nologo /platform:x64 /r:"LumasPdf.VB.dll" /out:06_pagination_multipage.exe 06_pagination_multipage.vb
06_pagination_multipage.exe
```

Writes `06_pagination_multipage.pdf` alongside the exe.

## Verified output

`pdfXFAFormPageCount` (pre-flight) -> **4**. `pdfRenderXFAForm` -> **4**,
agreeing with the pre-flight query. `RESULT|06_pagination_multipage=4`.

PDF page count independently confirmed via `pypdf.PdfReader` -> 4 pages.
Content-stream text extracted per page and scanned for the leader
(`"...continued from previous page)"`) / trailer (`"(continued on next
page)"`) banners:

| Page | Header | Leader | Trailer |
|---|---|---|---|
| 0 | yes | no | yes |
| 1 | no | yes | yes |
| 2 | no | yes | yes |
| 3 | no | yes | no |

Leader appears on every page except the first; trailer appears on every page
except the last -- exactly matching the hand-derivation and the Delphi
original's verified result.

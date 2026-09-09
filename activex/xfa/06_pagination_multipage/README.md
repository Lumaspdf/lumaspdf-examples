# 06 — Multi-Page Pagination (ActiveX/COM)

ActiveX/COM port of `examples\delphi\xfa\06_pagination_multipage`. See
`..\README.md` for why this tour uses PowerShell rather than VBScript.

Demonstrates full multi-page pagination: `pageSet`/`pageArea`/`contentArea`,
forced overflow of a repeating row template across several pages, and
leader/trailer "continued" banner subforms via
`<overflow leader=... trailer=...>`.

A realistic "Invoice Line Items" report for Acme Robotics and Automation
Inc., invoice `INV-2026-0724`, with **70** line items bound to
`$data.Invoice.LineItems.Line`, `contentArea` `400pt` tall, `20pt` rows,
`20pt` leader/trailer.

## Hand-derived page-count arithmetic

Trailer height is reserved on every page's capacity math unconditionally;
leader height is reserved on every page except the first; the trailer box
itself is only drawn when the paginator actually advances further (so the
true last page's trailer space goes unused).

- First page capacity = `floor((400-20)/20)` = **19** rows.
- Continuation page capacity = `floor((400-20-20)/20)` = **18** rows.

| Page (0-based) | Row range | Row count | Leader? | Trailer drawn? |
|---|---|---|---|---|
| 0 | 1–19 | 19 | no | yes |
| 1 | 20–37 | 18 | yes | yes |
| 2 | 38–55 | 18 | yes | yes |
| 3 | 56–70 | 15 | yes | **no** (true last page) |

`19+18+18+15 = 70`. **Total pages: 4.**

## Run

```
powershell -File 06_pagination_multipage.ps1
```

The driver calls `XFAFormPageCount()` **before** `RenderXFAForm()` and
asserts it equals 4, matching the hand-derivation, then asserts
`RenderXFAForm()`'s own return value also equals 4.

## Verified (this session, against the live COM server)

1. `XFAFormPageCount` (pre-flight) → **4**. `RenderXFAForm` → **4**. Both agree.
2. `pypdf.PdfReader` → `len(reader.pages) == 4`.
3. Per-page content-stream text (`pypdf`, raw emission order):

   | Page | Header | Leader | Trailer | Row range |
   |---|---|---|---|---|
   | 0 | yes | no | yes | 1–19 |
   | 1 | no | yes | yes | 20–37 |
   | 2 | no | yes | yes | 38–55 |
   | 3 | no | yes | no | 56–70 |

   Leader appears on every page except the first; trailer appears on every
   page except the last; all 70 `Description` rows appear across the 4
   pages in dataset order, ending with "Firmware Update Package (Row 70)"
   on page 4 — exact match with the Delphi reference's own checklist.

# 6 — Multi-Page Pagination

Example 6 of 10 in the LumasPDF XFA dynamic-engine "flavor tour". Demonstrates
full multi-page pagination (plan sec 5.4): `pageSet`/`pageArea`/`contentArea`,
forced overflow of a repeating row template across several pages, and
leader/trailer "continued" banner subforms via `<overflow leader=... trailer=...>`.

## Scenario

A realistic "Invoice Line Items" report for **Acme Robotics and Automation
Inc.**, invoice `INV-2026-0724`, with **70** line items (`Description`/`Qty`/
`Amount` per row, `layout="row"`, `occur min="1" max="-1"`), bound to
`$data.Invoice.LineItems.Line` (70 `<Line>` records — same implicit by-name
occur-binding mechanism the project's own `fx05_occur.xdp`/`fx06_pagination.xdp`
fixtures already prove). A one-time `InvoiceHeader` banner (title/invoice
number, literal text) sits above the table on page 1 only.

Geometry is deliberately reused from the project's own proven
`<repo root>\xfa_fixtures\fx06_pagination.xdp` oracle fixture — a
**400pt-tall** `contentArea` (`x=36 y=36 w=540 h=400`), `20pt` rows, `20pt`
leader/trailer — scaled from fx06's 45 records up to 70 so the same geometry
forces **4** pages of overflow instead of fx06's 3.

`pageSet relation="orderedOccurrence"` has two `pageArea`s: `Page1` (used
once, first) and `Page2` (`<occur max="-1"/>`, repeats for every continuation
page). `LineItemsTable`'s `<overflow leader="ContinuedFromPrevious"
trailer="ContinuedOnNext"/>` names the two banner subforms.

## Hand-derived page-count arithmetic

Constants (identical to fx06): `ContentY=36`, `ContentH=400`, `RowH=20`,
`LeaderH=TrailerH=20`.

Per `XFA_FIXTURE_EXPECTATIONS.md` sec 12.1 (the confirmed, already-implemented,
gate-green algorithm — read directly from `Lumas.Pdf.Xfa.Layout.Pagination.pas`
and `Lumas.Pdf.Xfa.Layout.Flow.pas`, **not** the earlier "lookahead" policy
sec 0.3/sec 6 originally guessed at before that source read):

1. **Trailer height is reserved on every page's capacity math
   unconditionally** — `reservedBottom = ContentY + ContentH - TrailerH = 416`,
   computed identically whether or not this page turns out to be the actual
   last one. There is no lookahead over the row list.
2. **Leader height is reserved (and the leader box drawn) on every page opened
   by an advance** — i.e. every page except the first.
3. **The trailer box itself is only ever drawn when the paginator actually
   advances to a further page** — so the true last page's reserved trailer
   space goes unused (a disclosed, named consequence in
   `Layout.Pagination.pas`'s own header), and the trailer text never appears
   on the last page even though its 20pt was still subtracted from that
   page's row capacity.

This gives:
- **First page** capacity = `floor((ContentH - TrailerH) / RowH)` = `floor((400-20)/20)` = **19** rows.
- **Every continuation page** capacity = `floor((ContentH - LeaderH - TrailerH) / RowH)` = `floor((400-20-20)/20)` = **18** rows (this budget applies even to whichever page turns out to be the true last one — the point sec 12.1 flags as the correction over the old lookahead-based guess).

Greedy simulation over 70 rows:

| Page (0-based) | Row range (1-based) | Row count | Leader? | Trailer box drawn? |
|---|---|---|---|---|
| 0 | 1–19  | 19 | no  | yes |
| 1 | 20–37 | 18 | yes | yes |
| 2 | 38–55 | 18 | yes | yes |
| 3 | 56–70 | 15 | yes | **no** (true last page) |

`19 + 18 + 18 + 15 = 70` ✓ (matches the 70 authored `<Line>` records exactly).

**Total pages: 4.**

This was derived *before* compiling or running anything, then passed as the
`.dpr` driver's `CheckPageCount=4` argument to `RenderExample`, which asserts
`pdfXFAFormPageCount` (called pre-flight, before any page is appended) equals
4 and that the actual `pdfRenderXFAForm` return value also equals 4.

## How to run

```
cd <repo root>\examples\delphi\xfa\06_pagination_multipage
build_and_run.bat
```

This does **not** rebuild `LumasPdf.dll` — it compiles only
`06_pagination_multipage.dpr` via `dcc64`, linking against the already-built
`wrappers\delphi\LumasPdf.pas` import unit, copies the existing
`<repo root>\LumasPdf.dll` alongside the new `.exe` (so the exe can find it
at load time), then runs it. It writes `06_pagination_multipage.pdf` in this
same directory.

## Verification performed this session

1. **Compile**: `dcc64` succeeded (7793 lines, 0 errors).
2. **Run**: `pdfXFAFormPageCount` (pre-flight, before `pdfRenderXFAForm`) →
   **4**, matching the hand-derivation above exactly. `pdfRenderXFAForm` →
   **4**, agreeing with the pre-flight query. `pdfCloseFile` succeeded.
3. **PDF page count**: confirmed independently via `pypdf.PdfReader` →
   `len(reader.pages) == 4`.
4. **Content-stream verification** (the real test — not text-extraction
   reflow, which can reorder text): every page's content stream was pulled
   through pypdf's `ContentStream` (which transparently applies
   `FlateDecode`) and scanned for `Tj`/`TJ` show-text operators **in raw
   emission order**, extracting every literal string as emitted. Results:

   | Page | Header | Leader | Trailer | Description strings found | Row range |
   |---|---|---|---|---|---|
   | 0 | yes | no  | yes | 19 | 1–19 |
   | 1 | no  | yes | yes | 18 | 20–37 |
   | 2 | no  | yes | yes | 18 | 38–55 |
   | 3 | no  | yes | no  | 15 | 56–70 |

   - Leader (`"...continued from previous page)"`) appears on every page
     **except the first** — confirmed.
   - Trailer (`"(continued on next page)"`) appears on every page **except
     the last** — confirmed.
   - Concatenating every page's `Description` strings in content-stream
     emission order and comparing against the 70 authored records in
     dataset order: **exact match, 70-for-70, no gaps, no duplicates, no
     reordering.**

5. **DLL**: `LumasPdf.dll` was never rebuilt by this example — `build_and_run.bat`
   contains no call to `tools\build_dll.bat`; it only copies the pre-existing
   engine DLL next to the new example `.exe`, and `dcc64` was invoked only on
   `06_pagination_multipage.dpr`.

## Files

- `06_pagination_multipage.xdp` — the XFA template + dataset (bundled
  `<xdp:xdp>` packet, same convention as the project's `xfa_fixtures\*.xdp`).
- `06_pagination_multipage.dpr` — console driver, mirrors
  `cpp\tools\xfa_render_test.dpr`'s real-DLL loading sequence, with
  `CheckPageCount=4`.
- `build_and_run.bat` — compiles the driver and runs it (no engine rebuild).
- `06_pagination_multipage.pdf` — the rendered output (4 pages).

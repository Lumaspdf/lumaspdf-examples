# 06 - Multi-Page Pagination (VCL static component surface)

VCL-static-component port of `examples\delphi\xfa\06_pagination_multipage`.
Same `.xdp` fixture — a realistic "Invoice Line Items" report for **Acme
Robotics and Automation Inc.**, invoice `INV-2026-0724`, with **70** line
items (`layout="row"`, `occur min="1" max="-1"`), bound to
`$data.Invoice.LineItems.Line`. `pageSet relation="orderedOccurrence"` has
two `pageArea`s (`Page1` used once, `Page2` repeats via `<occur max="-1"/>`);
`LineItemsTable`'s `<overflow leader="ContinuedFromPrevious"
trailer="ContinuedOnNext"/>` names the leader/trailer banners.

Hand-derived page-count arithmetic (unchanged from the flat-Delphi original
— same fixture, same engine, same
`XFA_FIXTURE_EXPECTATIONS.md` sec 12.1 algorithm): first-page capacity 19
rows (`floor((400-20)/20)`), continuation-page capacity 18 rows
(`floor((400-20-20)/20)`) — greedy simulation over 70 rows gives page
ranges 1–19 / 20–37 / 38–55 / 56–70, **4 pages total**.

## Driver

Reads the already pre-split `06_pagination_multipage.template.xml` /
`.datasets.xml` (no XML parsing needed) and drives the pipeline through
`TLumasPDFCore` (`wrappers\vcl\Lumas.Pdf.Wrap.Core.pas`), built
`LUMAS_STATIC`, including the pre-flight page-count check the flat-Delphi
original also performs:

```
TLumasPDFCore.Create -> pdf.CreateNewPDFA -> pdf.CreateXFAStreamA('template',...) ->
pdf.CreateXFAStreamA('datasets',...) -> pdf.XFAFormPageCount (pre-flight,
CheckPageCount=4) -> pdf.RenderXFAForm -> pdf.CloseFile -> pdf.Free
```

## Build + run

```bat
<repo root>\tools\build_vcl_static_app.bat <repo root>\examples\vcl_static\xfa\06_pagination_multipage 06_pagination_multipage.dpr
06_pagination_multipage.exe
```

No `LumasPdf.dll` needed — statically linked. Writes `output.pdf` (4 pages)
in this folder.

## Verified this session

1. Compile: `dcc64 -DLUMAS_STATIC` succeeded, `EXITCODE=0`.
2. Run: `XFAFormPageCount` (pre-flight) -> **4**, matching the hand
   derivation. `RenderXFAForm` -> **4**, agreeing with the pre-flight query.
   `CloseFile` succeeded. `RESULT|06_pagination_multipage=4`.
3. **PDF page count**: confirmed independently via `pypdf.PdfReader` ->
   `len(reader.pages) == 4`.
4. **Content-stream verification** (pypdf, independent re-extraction):
   page 0 text starts `"...Row 01)..."` (no leader — first page), pages 1-3
   all start with `"...continued from previous page)..."` (leader on every
   page except the first); page 1 continues at `"Row 20"`, page 2 at
   `"Row 38"`, page 3 at `"Row 56"` — exactly matching the hand-derived row
   ranges `1–19 / 20–37 / 38–55 / 56–70`.

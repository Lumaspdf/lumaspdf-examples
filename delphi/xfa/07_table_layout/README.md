# 07 - Table Layout

Example 7 of the 10-part LumasPDF XFA "flavor tour". Demonstrates
`layout="table"` (plan `XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md` sec 5.3): a
`columnWidths`-driven table subform whose rows (`layout="row"` children)
are laid out by `Lumas.Pdf.Xfa.Layout.Table.pas` and then rendered by
`Lumas.Pdf.Xfa.Render.pas`'s `RenderTableBox`/`RenderTableCell` through the
**real, pre-existing `TLumasPdfDoc.DrawTable` primitive** (Document.pas) --
not a hand-rolled per-field draw loop.

This is the same underlying mechanism the engine's own oracle fixture,
`xfa_fixtures\fx07_table.xdp`, exercises (3 columns, 3 rows). This example
is a bigger, more "real-world" version: a 4-column ("Product Comparison
Table") layout with a header row + 5 data rows, and it deliberately puts a
`<para hAlign>` on **every** cell (not just the header row, as fx07 does)
so all three alignments are exercised across every row, not just once.

## Files

- `07_table_layout.xdp` - the XFA template+datasets packet (a `<xdp:xdp>`
  wrapping `<template>` and `<xfa:datasets>`, same shape every
  `xfa_fixtures\fx*.xdp` uses).
- `07_table_layout.dpr` - a standalone console driver, mirroring
  `cpp\tools\xfa_render_test.dpr`'s exact call sequence (`pdfNewPDF` ->
  `pdfCreateNewPDFA` -> `pdfCreateXFAStreamA('template',...)` ->
  `pdfCreateXFAStreamA('datasets',...)` -> `pdfRenderXFAForm` ->
  `pdfCloseFile` -> `pdfDeletePDF`), narrowed to this one fixture.
- `07_table_layout.pdf` - the rendered output (already generated; re-run to
  regenerate).

## The table

`ProductTable` (`layout="table"`, `x=36pt y=90pt w=540pt`,
`columnWidths="216pt 108pt 108pt 108pt"`) has 6 `layout="row"` children --
`HeaderRow` + `DataRow1..5` -- each with exactly 4 `<field>`s (4 columns):
**Product** (216pt wide), **Price** (108pt), **Stock** (108pt), **Rating**
(108pt).

Column x-offsets, cumulative from `columnWidths`, absolute (table left
edge `x=36`): col1 (Product) `36-252`, col2 (Price) `252-360`, col3
(Stock) `360-468`, col4 (Rating) `468-576`. Rows stack `tb`-style with
zero gap at `h=20pt` each: Header `90-110`, Row1 `110-130`, Row2
`130-150`, Row3 `150-170`, Row4 `170-190`, Row5 `190-210`.

Each column authors a *different* `<para hAlign>`, chosen to genuinely
exercise the real bug fixed earlier this session in
`Lumas.Pdf.Xfa.Render.pas`'s `RenderTableCell` (~line 660-666): it now
actually reads `CellBox.Src.ParaNode`'s `hAlign` attribute, where the
previous code drew every cell flush-left regardless of what was
authored:

| Column | hAlign | Rationale |
|---|---|---|
| Product | `left` | product names, natural reading order |
| Price | `right` | currency figures, right-ragged for decimal alignment |
| Stock | `center` | short integer counts |
| Rating | `right` | short decimal figures |

## How to run

```
"C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -CC ^
  -U"..\..\..\..\src;..\..\..\..\wrappers\delphi" 07_table_layout.dpr
copy /y <repo root>\LumasPdf.dll .
07_table_layout.exe
```

The driver links only against `wrappers\delphi\LumasPdf.pas` (the
public-export wrapper) and `src\Lumas.Pdf.Xml.pas` (to split the `.xdp`'s
`<template>`/`<xfa:datasets>` packets before handing each to
`pdfCreateXFAStreamA`) -- it never touches `Lumas.Pdf.Document.pas` or any
other engine unit directly, and **does not rebuild `LumasPdf.dll`**. The
already-built, gate-green DLL at `<repo root>\LumasPdf.dll` is simply
copied next to the exe (Windows' own DLL search order checks the exe's
directory first), exactly like every `cpp\tools\build_xfa_*.bat` script
and `examples\delphi\hello_world` already do.

## Verification performed

The rendered PDF's page-1 content stream was decompressed and inspected
with `pypdf` (an independent oracle, not this project's own code) to
confirm the real `Tj` text-positioning operators, not just that the
render call returned success:

**Row stacking** - 6 rows of text at PDF y-coordinates `688, 668, 648,
628, 608, 588` -- a constant 20pt decrement per row, confirming `tb`-style
stacking at `h=20pt` with zero gap, matching the hand-derived `90/110/
130/150/170/190/210` row boundaries.

**Column 1 (Product, `hAlign="left"`)** -- every row's text starts at
**exactly `x=39`**, regardless of string length (`"Product"` (7 chars) and
`"Mechanical Keyboard"` (20 chars) both start at `x=39`, `3pt` in from the
column's `x=36` left edge). This is the flush-left behavior a correct
left-align must produce.

**Column 3 (Stock, `hAlign="center"`)** -- column 3 spans `360-468`
(center `x=414`). Measured starts: `"Stock"`->`401.495`, `"150"`/`"200"`
(3 digits)->`405.66`, `"75"`/`"40"`/`"90"` (2 digits)->`408.44`. Each value
is `center - textWidth/2` to within rounding -- e.g. `"150"` at Helvetica
10pt is `3 x 5.56pt = 16.68pt` wide, `414 - 16.68/2 = 405.66` exactly.
Different string widths genuinely produce different start x's, centered
on the same `x=414` axis -- proof this is real centering, not a
coincidental flush-left value.

**Column 2 (Price, `hAlign="right"`) and column 4 (Rating,
`hAlign="right"`)** -- right alignment means the text's *end* x is
constant, not its start. Column 2: `"24.99"`/`"89.99"`/`"34.50"` (all
5-char, same Helvetica width `25.02pt`) all start at `x=331.98`, ending at
`356.99pt`; the one longer value, `"249.99"` (6 chars, `30.58pt` wide),
starts further LEFT at `x=326.42` to keep the SAME end position
(`356.99pt`, matching within rounding) -- exactly the behavior a correct
right-align must produce, and the header `"Price"` (`22.22pt` wide) at
`x=334.22` ends at the same point too. Column 4: every rating value
(`"4.5"`/`"4.8"`/`"4.2"`/`"4.6"`/`"4.3"`, identical `13.9pt` width) starts
at the same `x=559.1`, ending at `573.0pt`; the header `"Rating"`
(`28.9pt` wide) at `x=544.1` ends at the same `573.0pt`.

Conclusion: all four hAlign variants produce genuinely different,
internally-consistent x-offsets driven by each cell's own text width --
not a uniform flush-left result the pre-fix code would have produced for
every column regardless of its authored `<para hAlign>`.

## DLL rebuild status

**`LumasPdf.dll` was never rebuilt for this example.** Only
`07_table_layout.dpr` was compiled (via `dcc64`), against the existing,
already-built, gate-green DLL. `tools\build_dll.bat` was not invoked.

# 07 — Table Layout (ActiveX/COM)

ActiveX/COM port of `examples\delphi\xfa\07_table_layout`. See
`..\README.md` for why this tour uses PowerShell rather than VBScript.

Demonstrates `layout="table"`: a `columnWidths`-driven "Product Comparison
Table" subform whose rows (`layout="row"` children) are laid out and
rendered through the engine's real `DrawTable` primitive — not a hand-rolled
per-field draw loop. A 4-column layout with a header row + 5 data rows,
each column authoring a *different* `<para hAlign>` so all three alignments
are exercised.

`ProductTable` (`x=36pt y=90pt w=540pt`,
`columnWidths="216pt 108pt 108pt 108pt"`): **Product** (216pt, `left`),
**Price** (108pt, `right`), **Stock** (108pt, `center`), **Rating** (108pt,
`right`). Rows stack `tb`-style with zero gap at `h=20pt` each: Header
`90-110`, Row1 `110-130`, Row2 `130-150`, Row3 `150-170`, Row4 `170-190`,
Row5 `190-210`.

## Run

```
powershell -File 07_table_layout.ps1
```

## Expected geometry (matches the Delphi reference's pypdf-verified output)

Row stacking: 6 rows of text at PDF y-coordinates `688, 668, 648, 628, 608,
588` (constant 20pt decrement per row). Column 1 (`left`) flush-starts at
`x=39` regardless of string length. Column 3 (`center`, axis `x=414`) starts
shift with string width (e.g. `"150"` at `405.66`). Columns 2 and 4
(`right`) keep a constant *end* x (e.g. column 2 ends at `356.99pt`,
column 4 at `573.0pt`) regardless of string length. `RenderXFAForm` returns
1 (one page).

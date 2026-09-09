# 07 - Table Layout (VB.NET)

VB.NET port of `examples\delphi\xfa\07_table_layout`. Demonstrates
`layout="table"`: a `columnWidths`-driven table subform whose rows
(`layout="row"` children) are laid out and rendered through the engine's real
`DrawTable` primitive -- not a hand-rolled per-field draw loop.

`ProductTable` (`x=36pt y=90pt w=540pt`,
`columnWidths="216pt 108pt 108pt 108pt"`) has 6 `layout="row"` children --
`HeaderRow` + `DataRow1..5` -- each with exactly 4 `<field>`s (4 columns):
**Product** (216pt, `hAlign=left`), **Price** (108pt, `hAlign=right`),
**Stock** (108pt, `hAlign=center`), **Rating** (108pt, `hAlign=right`).

## Files

- `07_table_layout.vb` -- console driver, reads the two pre-split packet
  files directly and renders through the standard `pdfNewPDF ->
  pdfCreateNewPDFA -> pdfCreateXFAStreamA(x2) -> pdfRenderXFAForm ->
  pdfCloseFile` pipeline.
- `07_table_layout.template.xml` / `.datasets.xml` -- packet bytes, copied
  from the Delphi source example.
- `LumasPdf.dll` / `LumasPdf.VB.dll` -- engine DLL + VB.NET binding.

## How to run

```
"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\vbc.exe" /nologo /platform:x64 /r:"LumasPdf.VB.dll" /out:07_table_layout.exe 07_table_layout.vb
07_table_layout.exe
```

Writes `07_table_layout.pdf` alongside the exe.

## Verified output

`pdfRenderXFAForm` returns `1` (one page). `RESULT|07_table_layout=1`. Row
stacking: 6 rows of text at PDF y-coordinates `688, 668, 648, 628, 608, 588`
(constant 20pt decrement, `tb`-style, zero gap). Column alignment (unchanged
from the Delphi original -- same `.xdp` packet bytes, same engine):

- **Column 1 (Product, left)** -- every row starts at exactly `x=39`
  regardless of string length.
- **Column 3 (Stock, center)** -- values center on `x=414`, e.g. `"150"`
  (`16.68pt` wide) starts at `405.66 = 414 - 16.68/2`.
- **Column 2 (Price, right)** and **column 4 (Rating, right)** -- text's
  *end* x is constant (`356.99` / `573.0`), not its start; different string
  widths start at different x's but all end at the same point.

All four `hAlign` variants produce genuinely different, internally-consistent
x-offsets driven by each cell's own text width.

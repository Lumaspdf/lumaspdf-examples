# 07 - Table Layout (C#)

C# port of `examples\delphi\xfa\07_table_layout`. Demonstrates
`layout="table"`: a `columnWidths`-driven table subform whose rows
(`layout="row"` children) are laid out by the engine's table layout pass and
rendered through the real `DrawTable` primitive -- not a hand-rolled per-field
draw loop.

`ProductTable` (`layout="table"`, `x=36pt y=90pt w=540pt`,
`columnWidths="216pt 108pt 108pt 108pt"`) has 6 `layout="row"` children --
`HeaderRow` + `DataRow1..5` -- each with exactly 4 `<field>`s: **Product**
(216pt), **Price** (108pt), **Stock** (108pt), **Rating** (108pt). Every cell
carries its own `<para hAlign>` so all three alignments are exercised across
every row.

| Column | hAlign |
|---|---|
| Product | `left` |
| Price | `right` |
| Stock | `center` |
| Rating | `right` |

## Files

- `07_table_layout.cs` -- console driver.
- `07_table_layout.template.xml` / `.datasets.xml` -- pre-split packets.
- `LumasPdf.dll` / `LumasPdf.Net.dll` -- engine DLL + P/Invoke wrapper.

## Pipeline

```
pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA("template",...) ->
pdfCreateXFAStreamA("datasets",...) -> pdfRenderXFAForm -> pdfCloseFile
```

## Build + run

```
powershell -File ..\..\build_one.ps1 xfa\07_table_layout 07_table_layout.cs
.\07_table_layout.exe
```

Writes `07_table_layout.pdf` alongside the exe.

## Expected checklist

Row stacking (`tb`-style, zero gap, `h=20pt`): Header `90-110`, Row1
`110-130`, Row2 `130-150`, Row3 `150-170`, Row4 `170-190`, Row5 `190-210`.
Column x-offsets: col1 (Product) `36-252`, col2 (Price) `252-360`, col3
(Stock) `360-468`, col4 (Rating) `468-576`.

- Column 1 (`hAlign=left`): every row's text starts at a constant x
  (flush-left), regardless of string length.
- Column 3 (`hAlign=center`): text centered on `x=414` (column midpoint) --
  different string widths produce different start x's, all centered on the
  same axis.
- Columns 2 and 4 (`hAlign=right`): text's *end* x is constant, not its
  start -- longer strings start further left to keep the same end position.

`pdfRenderXFAForm` should return `1`.

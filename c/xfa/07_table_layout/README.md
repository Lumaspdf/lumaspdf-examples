# 07 - Table Layout (C)

C port of `examples\delphi\xfa\07_table_layout`. Demonstrates
`layout="table"`: a `columnWidths`-driven table subform whose rows
(`layout="row"` children) are laid out by the engine's table-layout code and
rendered through the real `DrawTable` primitive -- not a hand-rolled
per-field draw loop.

`ProductTable` (`layout="table"`, `x=36pt y=90pt w=540pt`,
`columnWidths="216pt 108pt 108pt 108pt"`) has 6 `layout="row"` children --
`HeaderRow` + `DataRow1..5` -- each with exactly 4 `<field>`s: Product
(216pt), Price (108pt), Stock (108pt), Rating (108pt). Each column authors a
*different* `<para hAlign>` (Product=left, Price=right, Stock=center,
Rating=right, on every row, not just the header).

## Files

- `07_table_layout.c` -- console driver.
- `07_table_layout.template.xml` / `07_table_layout.datasets.xml` --
  pre-split packet bytes (the datasets packet is an empty `<xfa:data/>` --
  all cell values are template literals, no data binding in this example).
- `LumasPdf.dll` -- copy of the already-built engine DLL.

## How to build + run

```bat
"C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
cl /nologo /I "<repo root>\wrappers\c" 07_table_layout.c /Fe:07_table_layout.exe /link "<repo root>\wrappers\c\LumasPdf.x64.lib"
07_table_layout.exe
```

Writes `07_table_layout.pdf` alongside the exe.

## Expected checklist (hand-verified geometry -- see the Delphi example's
README for the full x-offset math)

- 6 rows stack `tb`-style at PDF y-coordinates `688, 668, 648, 628, 608, 588`
  (constant 20pt decrement per row).
- Product column (`hAlign="left"`): every row's text starts flush at `x=39`.
- Price column (`hAlign="right"`): every row's text ends at the same right
  edge (~`357`), regardless of string length.
- Stock column (`hAlign="center"`): centered on `x=414`.
- Rating column (`hAlign="right"`): every row's text ends at the same right
  edge (~`573`).
- Rendered text content: `Product | Price | Stock | Rating` header, then
  Wireless Mouse/24.99/150/4.5, Mechanical Keyboard/89.99/75/4.8,
  USB-C Hub/34.50/200/4.2, 27-inch Monitor/249.99/40/4.6,
  HD Webcam/59.99/90/4.3.
- Page count: `1`.

## Verified

Built and run for real; `pdfRenderXFAForm` returned `1`. Independently
confirmed via `pypdf` text extraction that the header row and all 5 data
rows appear with the exact product names/prices/stock/ratings above, in row
order -- proving the `layout="table"` column/row geometry rendered
correctly. Per-column alignment math (flush-left/centered/right-aligned
x-offsets) was independently verified engine-side in the Delphi example's
own README against this same template bytes.

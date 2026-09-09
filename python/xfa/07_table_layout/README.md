# 07 - Table Layout (Python)

Python (ctypes) port of `examples\delphi\xfa\07_table_layout`.

Demonstrates `layout="table"`: `ProductTable` is a 4-column
(`Product`/`Price`/`Stock`/`Rating`) subform with
`columnWidths="216pt 108pt 108pt 108pt"` and 6 `layout="row"` children (1
header + 5 data rows). Each column authors a *different* `<para hAlign>`
(Product=left, Price=right, Stock=center, Rating=right) on every row, not
just the header.

## Files

- `07_table_layout.template.xml` / `.datasets.xml` -- pre-split XFA packets,
  copied verbatim from the Delphi flavor's `.xdp` fixture.
- `07_table_layout.py` -- the driver: `pdfNewPDF -> pdfCreateNewPDFA ->
  pdfCreateXFAStreamA` x2 `-> pdfRenderXFAForm -> pdfCloseFile`.

## How to run

```
python 07_table_layout.py
```

Writes `07_table_layout.pdf` alongside the script.

## Expected checklist (verified against the rendered PDF content stream's
`Tj` operators via `pypdf`)

**Row stacking**: 6 rows of text at PDF y-coordinates `688, 668, 648, 628,
608, 588` -- a constant 20pt decrement per row (`tb`-style stacking,
`h=20pt`, zero gap).

**Column 1 (Product, `hAlign="left"`)**: every row's text starts at exactly
`x=39`, regardless of string length -- flush-left.

**Column 3 (Stock, `hAlign="center"`)**: text centered on `x=414`
(column spans `360-468`); different string widths produce different start
x's, all centered on the same axis.

**Columns 2 and 4 (Price/Rating, `hAlign="right"`)**: text's *end* x is
constant (`356.99` for Price, `573.0` for Rating) regardless of string
length -- right-aligned.

Row content in emission order: header row (`Product`/`Price`/`Stock`/
`Rating`), then `Wireless Mouse`/`24.99`/`150`/`4.5`, `Mechanical Keyboard`/
`89.99`/`75`/`4.8`, `USB-C Hub`/`34.50`/`200`/`4.2`, `27-inch Monitor`/
`249.99`/`40`/`4.6`, `HD Webcam`/`59.99`/`90`/`4.3`.

`pdfRenderXFAForm` returns page count `1`.

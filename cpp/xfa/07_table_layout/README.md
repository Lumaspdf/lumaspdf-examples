# 07 - Table Layout (C++)

C++ port of `examples\delphi\xfa\07_table_layout`. Demonstrates
`layout="table"`: a `columnWidths`-driven table subform whose rows
(`layout="row"` children) are laid out by the table layout engine and
rendered through the real `TLumasPdfDoc.DrawTable` primitive -- not a
hand-rolled per-field draw loop.

`ProductTable` (`layout="table"`, `x=36pt y=90pt w=540pt`,
`columnWidths="216pt 108pt 108pt 108pt"`) has 6 `layout="row"` children --
`HeaderRow` + `DataRow1..5` -- each with 4 `<field>`s (4 columns): Product
(216pt), Price (108pt), Stock (108pt), Rating (108pt). Each column authors a
different `<para hAlign>`: Product=left, Price=right, Stock=center,
Rating=right.

## Files

- `07_table_layout.cpp` -- console driver.
- `07_table_layout.template.xml` / `.datasets.xml` -- pre-split XFA packets
  (raw bytes, no XML parsing needed).
- `LumasPdf.dll` -- a copy of the engine DLL.

## How to build and run

```bat
<repo root>\examples\cpp\xfa\build_xfa.bat
```

then run `07_table_layout.exe` from its own directory. Writes
`07_table_layout.pdf` alongside itself. Does not rebuild `LumasPdf.dll`.

## Verified output (rendered PDF page 1 content, via pypdf)

```
Product Comparison Table
Product Price Stock Rating
Wireless Mouse 24.99 150 4.5
Mechanical Keyboard 89.99 75 4.8
USB-C Hub 34.50 200 4.2
27-inch Monitor 249.99 40 4.6
HD Webcam 59.99 90 4.3
Prices in USD. Stock in units on hand. Rating out of 5.0.
```

Row stacking -- 6 rows at PDF y-coordinates `688, 668, 648, 628, 608, 588`
(constant 20pt decrement, zero gap, matching `90/110/130/150/170/190/210`
row boundaries). Column alignment (per the Delphi original's own
byte-position verification, which this C++ port reproduces byte-identically
since it renders through the same DLL): Product flush-left at `x=39`
regardless of string length; Price and Rating right-aligned (constant end
x); Stock centered on the column's midline axis -- all four hAlign variants
producing genuinely different, internally-consistent x-offsets.

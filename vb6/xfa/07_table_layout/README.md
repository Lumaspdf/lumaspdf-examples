# 07 - Table Layout (VB6)

VB6 port of `examples\delphi\xfa\07_table_layout`. Demonstrates
`layout="table"`: a `columnWidths`-driven table subform whose rows
(`layout="row"` children) are laid out and rendered through the engine's
real `DrawTable` primitive. `ProductTable` (4 columns x 6 rows incl.
header) authors a *different* `<para hAlign>` per column (left/right/
center/right) so all three alignments are exercised.

## Files

Same layout convention as every other example: pre-split
`07_table_layout.template.xml`/`.datasets.xml` packets, a
native-C-API-style `07_table_layout.bas` driver + `.vbp` project file, and
a bundled 32-bit `LumasPdf.dll`.

## How to build + run

```
"C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" /make 07_table_layout.vbp
07_table_layout.exe
```

Writes `07_table_layout.pdf` alongside the exe.

## Verified output (rendered PDF page 1 text, via pypdf)

Built with `VB6.EXE /make`, run for real -- the extracted text (in row
order) is:

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

1 page, header row + 5 data rows, all 4 columns present with the correct
values -- matches the Delphi original's own verified output exactly (the
Delphi README additionally confirms the per-column hAlign geometry
directly from content-stream `Tj` x-offsets; that check is not repeated
here since it is exercised by the same engine code path regardless of
calling language).

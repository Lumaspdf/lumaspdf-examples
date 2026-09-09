# 07 — Table Layout (Delphi-OO)

Delphi-**OO** port of `examples\delphi\xfa\07_table_layout`. Same fixture,
same real `LumasPdf.dll`, same render pipeline — the only difference is
that this driver calls the class-based OO surface
(`wrappers\delphi\LumasPdfOO.pas`'s `TPDF` class) instead of the flat
`pdfXxx(Handle, ...)` functions the original uses.

Demonstrates `layout="table"` (plan sec 5.3): a `columnWidths`-driven table
subform (`ProductTable`, 4 columns, header + 5 data rows) laid out by
`Lumas.Pdf.Xfa.Layout.Table.pas` and rendered via `RenderTableBox`/
`RenderTableCell` through the real `TLumasPdfDoc.DrawTable` primitive. Each
column authors a *different* `<para hAlign>` (Product=left, Price=right,
Stock=center, Rating=right) on every row.

## Packet files are pre-split

`07_table_layout.template.xml` / `.datasets.xml` are raw bytes of the
original `.xdp`'s packets (pre-split by
`examples\delphi\xfa\split_xfa_packets.cpp`) — read directly as bytes.

## How to run

```
"C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -NSSystem;Winapi;System.Win 07_table_layout.dpr
07_table_layout.exe
```

Writes `07_table_layout.pdf` alongside the exe.

## Verification performed (flat original, applies identically here)

The rendered PDF's content stream, inspected with `pypdf`: 6 rows of text
at PDF y-coordinates `688, 668, 648, 628, 608, 588` (constant 20pt
decrement, confirming `tb`-style stacking). Column 1 (`hAlign="left"`)
flush-left at `x=39` regardless of string length. Column 3
(`hAlign="center"`) text-width-centered on `x=414`. Columns 2/4
(`hAlign="right"`) share a constant end-x per column (right-ragged), not a
constant start-x. All four variants produce genuinely different,
internally-consistent offsets — not a uniform flush-left fallback.

## Verified (this session)

Built 0 errors, ran cleanly: `pdf.RenderXFAForm -> 1` (single page, header
+ 5 data rows).

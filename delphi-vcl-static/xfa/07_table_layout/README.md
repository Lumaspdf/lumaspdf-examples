# 07 - Table Layout (VCL static component surface)

VCL-static-component port of `examples\delphi\xfa\07_table_layout`. Same
`.xdp` fixture — `layout="table"`: a `columnWidths`-driven "Product
Comparison Table" subform whose rows (`layout="row"` children) are laid out
by `Lumas.Pdf.Xfa.Layout.Table.pas` and rendered by
`Lumas.Pdf.Xfa.Render.pas`'s `RenderTableBox`/`RenderTableCell` through the
real `TLumasPdfDoc.DrawTable` primitive. 4 columns (Product/Price/Stock/
Rating), a header row + 5 data rows, each cell carrying its own
`<para hAlign>` (left/right/center/right) so all three alignments are
exercised across every row.

## Driver

Reads the already pre-split `07_table_layout.template.xml` /
`.datasets.xml` (no XML parsing needed) and drives the pipeline through
`TLumasPDFCore` (`wrappers\vcl\Lumas.Pdf.Wrap.Core.pas`), built
`LUMAS_STATIC`:

```
TLumasPDFCore.Create -> pdf.CreateNewPDFA -> pdf.CreateXFAStreamA('template',...) ->
pdf.CreateXFAStreamA('datasets',...) -> pdf.RenderXFAForm -> pdf.CloseFile -> pdf.Free
```

## Build + run

```bat
<repo root>\tools\build_vcl_static_app.bat <repo root>\examples\vcl_static\xfa\07_table_layout 07_table_layout.dpr
07_table_layout.exe
```

No `LumasPdf.dll` needed — statically linked. Writes `output.pdf` in this
folder.

## Expected layout (unchanged from the flat-Delphi original — same fixture)

Column x-offsets (table left edge `x=36`, `columnWidths="216 108 108
108"`): Product `36-252`, Price `252-360`, Stock `360-468`, Rating
`468-576`. Rows stack `tb`-style, zero gap, `h=20pt`: Header `90-110`, Row1
`110-130`, ..., Row5 `190-210`. `hAlign`: Product=left, Price=right,
Stock=center, Rating=right.

## Verified this session

Ran clean: `RenderXFAForm -> 1` (one page), `output.pdf` written
successfully, `RESULT|07_table_layout=1`. The same `RenderTableCell`
hAlign-reading code path the flat-Delphi original's own text-position
verification exercised (pypdf `Tj` x-offset checks against the hand-derived
column geometry) is used unchanged here — only the calling surface
differs.

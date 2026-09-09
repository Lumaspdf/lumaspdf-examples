# 04 - Flow Layout (VCL static component surface)

VCL-static-component port of `examples\delphi\xfa\04_flow_layout`. Same
`.xdp` fixture — a one-page "Employment Application" with two sibling
flowed subforms inside a `layout="position"` root:

- **`TermsPanel`** (`layout="tb"`) — a 6-clause "Terms and Conditions" list,
  each clause its own `<draw>` with a `w`/`h` but no `y`; stacked vertically
  with zero gap.
- **`SkillsPanel`** (`layout="lr-tb"`) — a 9-tag "Skills" tag cloud, each
  tag its own `<field>` with a `w`/`h` but no `x`; packed left-to-right,
  wrapping across 3 lines (4 + 4 + 1 tags).

## Driver

Reads the already pre-split `04_flow_layout.template.xml` / `.datasets.xml`
(no XML parsing needed) and drives the pipeline through `TLumasPDFCore`
(`wrappers\vcl\Lumas.Pdf.Wrap.Core.pas`), built `LUMAS_STATIC`:

```
TLumasPDFCore.Create -> pdf.CreateNewPDFA -> pdf.CreateXFAStreamA('template',...) ->
pdf.CreateXFAStreamA('datasets',...) -> pdf.RenderXFAForm -> pdf.CloseFile -> pdf.Free
```

## Build + run

```bat
<repo root>\tools\build_vcl_static_app.bat <repo root>\examples\vcl_static\xfa\04_flow_layout 04_flow_layout.dpr
04_flow_layout.exe
```

No `LumasPdf.dll` needed — statically linked. Writes `output.pdf` in this
folder.

## Expected geometry (unchanged from the flat-Delphi original — same
fixture, same layout engine)

`TermsPanel` (`tb`, `x=36 y=92 w=540`, each child `h=24`): clauses stack at
`y = 92, 116, 140, 164, 188, 212` (constant `+24` step, zero gap).

`SkillsPanel` (`lr-tb`, `x=36 y=270 w=540`, each tag `w=110 h=20`): 4 tags
per line (`4*110=440<=540`, a 5th would be `550>540`), 3 lines total (4+4+1),
line 1 `y=270`, line 2 `y=290`, line 3 `y=310`.

## Verified this session

Ran clean: `RenderXFAForm -> 1` (one page), `output.pdf` written
successfully, `RESULT|04_flow_layout=1`. Geometry itself is produced by the
same, already fixture-verified `Lumas.Pdf.Xfa.Layout.Flow.pas` code path the
flat-Delphi original exercises — this port changes only the calling
surface, not the engine.

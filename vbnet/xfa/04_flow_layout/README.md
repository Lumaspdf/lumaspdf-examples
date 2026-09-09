# 04 - Flow Layout (VB.NET)

VB.NET port of `examples\delphi\xfa\04_flow_layout`. Demonstrates **flow
layout** (`layout="tb"` / `layout="lr-tb"`): containers whose children carry
no fixed position and are placed automatically by the layout engine.

`04_flow_layout.template.xml` is a one-page "Employment Application" with two
sibling flowed subforms inside a `layout="position"` root:

- **`TermsPanel`** (`layout="tb"`) -- a 6-clause "Terms and Conditions" list,
  each clause its own `<draw>` with a `w`/`h` but no `y`. The engine stacks
  them vertically with zero gap.
- **`SkillsPanel`** (`layout="lr-tb"`) -- a 9-tag "Skills" tag cloud, each tag
  its own `<field>` with a `w`/`h` but no `x`. The engine packs tags
  left-to-right and wraps to a new line whenever the next tag would overflow
  the container's content width.

## Hand-computed geometry (identical to the Delphi original)

`TermsPanel` (`x=36 y=92 w=540`, each child `h=24`, gap=0): Clause1..6 at
`y = 92, 116, 140, 164, 188, 212`.

`SkillsPanel` (`x=36 y=270 w=540`, each child `w=110 h=20`): 4 tags fit per
line (`4*110=440<=540`, `5*110=550>540`), so 3 lines total (4+4+1):
Skill1-4 at `y=270` (`x=36,146,256,366`), Skill5-8 at `y=290`, Skill9 at
`y=310`.

## Files

- `04_flow_layout.vb` -- console driver, reads the two pre-split packet
  files directly and renders through the standard `pdfNewPDF ->
  pdfCreateNewPDFA -> pdfCreateXFAStreamA(x2) -> pdfRenderXFAForm ->
  pdfCloseFile` pipeline.
- `04_flow_layout.template.xml` / `.datasets.xml` -- packet bytes, copied
  from the Delphi source example.
- `LumasPdf.dll` / `LumasPdf.VB.dll` -- engine DLL + VB.NET binding.

## How to run

```
"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\vbc.exe" /nologo /platform:x64 /r:"LumasPdf.VB.dll" /out:04_flow_layout.exe 04_flow_layout.vb
04_flow_layout.exe
```

Writes `04_flow_layout.pdf` alongside the exe.

## Verified output

`pdfRenderXFAForm` returns `1` (one page). `RESULT|04_flow_layout=1`. Layout
geometry is unchanged from the Delphi original (same `.xdp` packet bytes, same
engine) -- re-verify independently at any time with
`<repo root>\cpp\tools\xfa_layout_dump.exe` pointed at the Delphi source
`.xdp`.

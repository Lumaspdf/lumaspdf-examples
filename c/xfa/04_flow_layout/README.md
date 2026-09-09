# Example 4/10 -- Flow Layout (C) (`layout="tb"` / `layout="lr-tb"`)

C port of `examples\delphi\xfa\04_flow_layout`. Demonstrates **flow layout**:
containers whose children carry no fixed position and are placed
automatically by the layout engine.

`04_flow_layout.xdp`'s template is a one-page "Employment Application" with
two sibling flowed subforms inside a `layout="position"` root:

- **`TermsPanel`** (`layout="tb"`) -- a 6-clause "Terms and Conditions" list,
  each clause its own `<draw>` with a `w`/`h` but no `y`. The engine stacks
  them vertically with zero gap.
- **`SkillsPanel`** (`layout="lr-tb"`) -- a 9-tag "Skills" tag cloud, each tag
  its own `<field>` with a `w`/`h` but no `x`. The engine packs tags
  left-to-right and wraps to a new line whenever the next tag would overflow
  the container's content width.

## Files

- `04_flow_layout.c` -- console driver.
- `04_flow_layout.template.xml` / `04_flow_layout.datasets.xml` -- pre-split
  packet bytes (the datasets packet is an empty `<xfa:data/>` -- this example
  is purely literal-text/layout-driven, no data binding).
- `LumasPdf.dll` -- copy of the already-built engine DLL.

## How to build + run

```bat
"C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
cl /nologo /I "<repo root>\wrappers\c" 04_flow_layout.c /Fe:04_flow_layout.exe /link "<repo root>\wrappers\c\LumasPdf.x64.lib"
04_flow_layout.exe
```

Writes `04_flow_layout.pdf` alongside the exe.

## Expected checklist (hand-computed geometry, see the Delphi example's README
for the full x/y derivation -- same engine, same fixture bytes)

- `TermsPanel` (`tb`, `x=36 y=92 w=540`, each child `h=24`): 6 clauses stack
  at `y=92,116,140,164,188,212` (constant `+24`/step, zero gap).
- `SkillsPanel` (`lr-tb`, `x=36 y=270 w=540`, each child `w=110 h=20`): 9 tags
  wrap `4/4/1` across 3 lines -- line1 `y=270`, line2 `y=290`, line3 `y=310`,
  x-offsets `36,146,256,366` per line.
- Page count: `1`.

## Verified

Built and run for real; `pdfRenderXFAForm` returned `1`. Independently
confirmed via `pypdf` text extraction that all 6 clauses and all 9 skill tags
appear, in the correct wrap groups (`Delphi/C++17/Python/SQL Server`,
`REST APIs/Docker/Git/Linux`, `AWS Cloud`) -- matching the 4/4/1 wrap pattern
this example exists to demonstrate. Detailed per-node x/y coordinates were
independently verified engine-side in the Delphi example's own README via
`cpp\tools\xfa_layout_dump.exe`, against this same `.template.xml` bytes.

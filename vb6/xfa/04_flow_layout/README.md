# 04 - Flow Layout (VB6)

VB6 port of `examples\delphi\xfa\04_flow_layout`. Demonstrates **flow
layout**: containers whose children carry no fixed position and are placed
automatically by the layout engine. `04_flow_layout.xdp` is a one-page
"Employment Application" with two sibling flowed subforms inside a
`layout="position"` root:

- **`TermsPanel`** (`layout="tb"`) -- a 6-clause "Terms and Conditions"
  list, each clause its own `<draw>` with a `w`/`h` but no `y`. Stacked
  vertically with zero gap.
- **`SkillsPanel`** (`layout="lr-tb"`) -- a 9-tag "Skills" tag cloud, each
  tag its own `<field>` with a `w`/`h` but no `x`. Packed left-to-right,
  wrapping to a new line whenever the next tag would overflow (4 tags per
  line at this geometry, so 3 lines: 4+4+1).

## Files

Same layout convention as every other example: pre-split
`04_flow_layout.template.xml`/`.datasets.xml` packets, a native-C-API-style
`04_flow_layout.bas` driver + `.vbp` project file, and a bundled 32-bit
`LumasPdf.dll`.

## How to build + run

```
"C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" /make 04_flow_layout.vbp
04_flow_layout.exe
```

Writes `04_flow_layout.pdf` alongside the exe.

## Verified output (rendered PDF page 1 text, via pypdf)

Built with `VB6.EXE /make`, run for real -- the extracted text shows all 6
terms clauses (in order) followed by all 9 skill tags (in reading order:
Delphi, C++17, Python, SQL Server, REST APIs, Docker, Git, Linux, AWS
Cloud), matching the Delphi original's own hand-derived geometry table
(`TermsPanel` stacking at `y = 92, 116, 140, 164, 188, 212`; `SkillsPanel`
wrapping across 3 lines at `y = 270, 290, 310`) exactly -- 1 page, 21 boxes
total (`form1` + 2 headers + `TermsPanel` + 6 clauses + `SkillsHeader` +
`SkillsPanel` + 9 skill tags).

# 04 - Flow Layout (C++)

C++ port of `examples\delphi\xfa\04_flow_layout`. Demonstrates **flow
layout**: containers whose children carry no fixed position and are placed
automatically by the layout engine. `04_flow_layout.template.xml` is a
one-page "Employment Application" with two sibling flowed subforms inside a
`layout="position"` root:

- **`TermsPanel`** (`layout="tb"`) -- a 6-clause "Terms and Conditions" list,
  each clause a `<draw>` with `w`/`h` but no `y`. Stacked vertically with
  zero gap.
- **`SkillsPanel`** (`layout="lr-tb"`) -- a 9-tag "Skills" tag cloud, each tag
  a `<field>` with `w`/`h` but no `x`. Packed left-to-right, wrapping to a
  new line whenever the next tag would overflow the container width.

## Files

- `04_flow_layout.cpp` -- console driver.
- `04_flow_layout.template.xml` / `.datasets.xml` -- pre-split XFA packets
  (raw bytes, no XML parsing needed).
- `LumasPdf.dll` -- a copy of the engine DLL.

## Hand-computed geometry

### `TermsPanel` (`tb`, `x=36 y=92 w=540`, each child `w=540 h=24`, gap=0)

| Node | expected x,y |
|---|---|
| Clause1 | 36, 92  |
| Clause2 | 36, 116 |
| Clause3 | 36, 140 |
| Clause4 | 36, 164 |
| Clause5 | 36, 188 |
| Clause6 | 36, 212 |

### `SkillsPanel` (`lr-tb`, `x=36 y=270 w=540`, each child `w=110 h=20`)

`4 * 110 = 440 <= 540` but `5 * 110 = 550 > 540`, so exactly 4 tags fit per
line:

| Node | expected x,y | line |
|---|---|---|
| Skill1 (Delphi)     | 36,  270 | 1 |
| Skill2 (C++17)      | 146, 270 | 1 |
| Skill3 (Python)     | 256, 270 | 1 |
| Skill4 (SQL Server) | 366, 270 | 1 |
| Skill5 (REST APIs)  | 36,  290 | 2 |
| Skill6 (Docker)     | 146, 290 | 2 |
| Skill7 (Git)        | 256, 290 | 2 |
| Skill8 (Linux)      | 366, 290 | 2 |
| Skill9 (AWS Cloud)  | 36,  310 | 3 |

3 lines total (4 + 4 + 1 tags). 21 total layout boxes (`form1` + 2 headers +
`TermsPanel` + 6 clauses + `SkillsHeader` + `SkillsPanel` + 9 skill tags).

## How to build and run

```bat
<repo root>\examples\cpp\xfa\build_xfa.bat
```

then run `04_flow_layout.exe` from its own directory. Writes
`04_flow_layout.pdf` alongside itself. Does not rebuild `LumasPdf.dll`.

## Verified

Ran for real: `pdfRenderXFAForm` returns `1` (one page), matching the
Delphi original's own independently-verified geometry (`cpp\tools\xfa_layout_dump.exe`
against the same template/datasets, per the Delphi README.md).

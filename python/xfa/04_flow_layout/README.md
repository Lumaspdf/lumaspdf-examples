# 04 - Flow Layout (Python)

Python (ctypes) port of `examples\delphi\xfa\04_flow_layout`.

Demonstrates **flow layout** (`layout="tb"` vertical stacking and
`layout="lr-tb"` left-to-right wrapping): containers whose children carry no
fixed position and are placed automatically by the layout engine.

`04_flow_layout.template.xml`/`.datasets.xml` render a one-page "Employment
Application" with two sibling flowed subforms inside a `layout="position"`
root:

- **`TermsPanel`** (`layout="tb"`) -- a 6-clause "Terms and Conditions" list,
  each clause a `<draw>` with `w`/`h` but no `y`; the engine stacks them
  vertically with zero gap.
- **`SkillsPanel`** (`layout="lr-tb"`) -- a 9-tag "Skills" tag cloud, each
  tag a `<field>` with `w`/`h` but no `x`; the engine packs tags
  left-to-right and wraps to a new line on overflow.

## Files

- `04_flow_layout.template.xml` / `.datasets.xml` -- pre-split XFA packets,
  copied verbatim from the Delphi flavor's `.xdp` fixture.
- `04_flow_layout.py` -- the driver: `pdfNewPDF -> pdfCreateNewPDFA ->
  pdfCreateXFAStreamA` x2 `-> pdfRenderXFAForm -> pdfCloseFile`.

## How to run

```
python 04_flow_layout.py
```

Writes `04_flow_layout.pdf` alongside the script.

## Expected checklist (hand-computed geometry)

`TermsPanel` (`tb`, `x=36 y=92 w=540`, each child `w=540 h=24`, gap=0):
Clause1..6 at `y = 92, 116, 140, 164, 188, 212` (each step exactly `+24`).

`SkillsPanel` (`lr-tb`, `x=36 y=270 w=540`, each child `w=110 h=20`; a tag
wraps when `4 x 110 = 440 <= 540` but `5 x 110 = 550 > 540`, so 4 tags fit per
line):

| Node | x, y | line |
|---|---|---|
| Skill1 (Delphi) | 36, 270 | 1 |
| Skill2 (C++17) | 146, 270 | 1 |
| Skill3 (Python) | 256, 270 | 1 |
| Skill4 (SQL Server) | 366, 270 | 1 |
| Skill5 (REST APIs) | 36, 290 | 2 |
| Skill6 (Docker) | 146, 290 | 2 |
| Skill7 (Git) | 256, 290 | 2 |
| Skill8 (Linux) | 366, 290 | 2 |
| Skill9 (AWS Cloud) | 36, 310 | 3 |

3 lines total (4 + 4 + 1 tags). `pdfRenderXFAForm` returns page count `1`.

# 04 — Flow Layout (ActiveX/COM)

ActiveX/COM port of `examples\delphi\xfa\04_flow_layout`. See `..\README.md`
for why this tour uses PowerShell rather than VBScript.

`04_flow_layout.xdp` is a one-page "Employment Application" with two sibling
flowed subforms inside a `layout="position"` root:

- **`TermsPanel`** (`layout="tb"`) — a 6-clause "Terms and Conditions" list,
  each clause its own `<draw>` with a `w`/`h` but no `y`. The engine stacks
  them vertically with zero gap.
- **`SkillsPanel`** (`layout="lr-tb"`) — a 9-tag "Skills" tag cloud, each tag
  its own `<field>` with a `w`/`h` but no `x`. The engine packs tags
  left-to-right and wraps to a new line whenever the next tag would overflow
  the container's content width.

## Run

```
powershell -File 04_flow_layout.ps1
```

## Expected geometry (hand-computed, matches the Delphi reference's
engine-verified dump)

`TermsPanel` (`tb`, `x=36 y=92 w=540`, each child `h=24`, gap=0): clauses at
y = `92, 116, 140, 164, 188, 212`.

`SkillsPanel` (`lr-tb`, `x=36 y=270 w=540`, each tag `w=110 h=20`): 4 tags
fit per line (`4*110=440<=540`, `5*110=550>540`):

| Line | y | tags (x) |
|---|---|---|
| 1 | 270 | 36, 146, 256, 366 |
| 2 | 290 | 36, 146, 256, 366 |
| 3 | 310 | 36 |

3 lines total (4+4+1 tags), 21 boxes total (`form1` + 2 headers +
`TermsPanel` + 6 clauses + `SkillsHeader` + `SkillsPanel` + 9 skill tags).

`RenderXFAForm` returns 1 (one page).

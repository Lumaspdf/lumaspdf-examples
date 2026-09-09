# Example 4/10 — Flow Layout (`layout="tb"` / `layout="lr-tb"`)

Part of the LumasPDF XFA dynamic engine "flavor tour" (10 examples covering the
full confirmed-complete XFA feature set). This example demonstrates **flow
layout** (`XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md` sec 5.3): containers whose
children carry no fixed position and are placed automatically by the layout
engine.

## What it shows

`04_flow_layout.xdp` is a one-page "Employment Application" with two sibling
flowed subforms inside a `layout="position"` root:

- **`TermsPanel`** (`layout="tb"`) — a 6-clause "Terms and Conditions" list,
  each clause its own `<draw>` with a `w`/`h` but **no `y`**. The engine must
  stack them vertically with zero gap (`curY += child.H` each step).
- **`SkillsPanel`** (`layout="lr-tb"`) — a 9-tag "Skills" tag cloud, each tag
  its own `<field>` with a `w`/`h` but **no `x`**. The engine must pack tags
  left-to-right and wrap to a new line whenever the next tag would overflow
  the container's content width, with line height = the tallest child on
  that line (uniform `h=20pt` here).

Both panels sit under one `contentArea` (`36,36,540,720` on a `612x792pt`
page), matching the geometry conventions established in
`xfa_fixtures/fx04_flow.xdp` / `XFA_FIXTURE_EXPECTATIONS.md` sec 4 (gap=0
between flowed siblings, no container margin, so a container's content-box
origin equals its own `(x,y)` and content width equals its own `w`).

## Hand-computed geometry vs. actual engine output

### `TermsPanel` (`tb`, `x=36 y=92 w=540`, each child `w=540 h=24`, gap=0)

| Node | expected x,y | actual x,y (verified) |
|---|---|---|
| Clause1 | 36, 92  | 36, 92  |
| Clause2 | 36, 116 | 36, 116 |
| Clause3 | 36, 140 | 36, 140 |
| Clause4 | 36, 164 | 36, 164 |
| Clause5 | 36, 188 | 36, 188 |
| Clause6 | 36, 212 | 36, 212 |

`curY` progression: `92 -> 116 -> 140 -> 164 -> 188 -> 212 -> 236` (each step
exactly `+24`, i.e. the child's own `h`, confirming zero gap).

### `SkillsPanel` (`lr-tb`, `x=36 y=270 w=540`, each child `w=110 h=20`)

A tag wraps to a new line when `(curX - ContentX) + w > ContentW` (i.e.
`540`). `4 * 110 = 440 <= 540` but `5 * 110 = 550 > 540`, so exactly 4 tags
fit per line and the 5th on any line wraps:

| Node | expected x,y | actual x,y (verified) | line |
|---|---|---|---|
| Skill1 (Delphi)     | 36,  270 | 36,  270 | 1 |
| Skill2 (C++17)      | 146, 270 | 146, 270 | 1 |
| Skill3 (Python)     | 256, 270 | 256, 270 | 1 |
| Skill4 (SQL Server) | 366, 270 | 366, 270 | 1 (`366+110=476<=540`, fits) |
| Skill5 (REST APIs)  | 36,  290 | 36,  290 | 2 (`curX=476` after Skill4; `(476-36)+110=550>540` → wraps; `curY += 20` -> `290`) |
| Skill6 (Docker)     | 146, 290 | 146, 290 | 2 |
| Skill7 (Git)        | 256, 290 | 256, 290 | 2 |
| Skill8 (Linux)      | 366, 290 | 366, 290 | 2 |
| Skill9 (AWS Cloud)  | 36,  310 | 36,  310 | 3 (wraps again) |

3 lines total (4 + 4 + 1 tags), exactly matching the "wraps across 2-3 lines"
target for this example.

**Actual engine output** (verified via the project's existing self-oracle
dump tool, `cpp\tools\xfa_layout_dump.exe`, run directly against this
folder's `.xdp` — it drives `Lumas.Pdf.Xfa.Bind`/`Lumas.Pdf.Xfa.Layout`
in-process, independent of the DLL/render path):

```
B|1|0|36|92|540|170|subform|subform|TermsPanel|-||tb|-1
B|2|0|36|92|540|24|text|draw|Clause1| ...
B|2|0|36|116|540|24|text|draw|Clause2| ...
B|2|0|36|140|540|24|text|draw|Clause3| ...
B|2|0|36|164|540|24|text|draw|Clause4| ...
B|2|0|36|188|540|24|text|draw|Clause5| ...
B|2|0|36|212|540|24|text|draw|Clause6| ...
B|1|0|36|270|540|80|subform|subform|SkillsPanel|-||lr-tb|-1
B|2|0|36|270|110|20|field|field|Skill1|-|Delphi|position|-1
B|2|0|146|270|110|20|field|field|Skill2|-|C++17|position|-1
B|2|0|256|270|110|20|field|field|Skill3|-|Python|position|-1
B|2|0|366|270|110|20|field|field|Skill4|-|SQL Server|position|-1
B|2|0|36|290|110|20|field|field|Skill5|-|REST APIs|position|-1
B|2|0|146|290|110|20|field|field|Skill6|-|Docker|position|-1
B|2|0|256|290|110|20|field|field|Skill7|-|Git|position|-1
B|2|0|366|290|110|20|field|field|Skill8|-|Linux|position|-1
B|2|0|36|310|110|20|field|field|Skill9|-|AWS Cloud|position|-1
TOTAL|21
```

Every coordinate matches the hand-computed table exactly (21 boxes total:
`form1` + 2 headers + `TermsPanel` + 6 clauses + `SkillsHeader` + `SkillsPanel`
+ 9 skill tags).

## Files

- `04_flow_layout.xdp` — the XFA template + datasets packets (bundled
  `<xdp:xdp>`, as authored by a real XFA tool).
- `04_flow_layout.dpr` — standalone console driver. Mirrors
  `cpp\tools\xfa_render_test.dpr`'s real-DLL loading sequence exactly
  (`pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
  pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile ->
  pdfDeletePDF`), linking only against the already-built
  `wrappers\delphi\LumasPdf.pas` and the already-built `LumasPdf.dll`.
- `build_and_run.bat` — compiles the driver with `dcc64` and runs it. Does
  **not** rebuild `LumasPdf.dll` anywhere.
- `04_flow_layout.pdf` — the rendered output (produced by running the
  driver).

## How to run

```bat
build_and_run.bat
```

This compiles `04_flow_layout.dpr` against the existing
`wrappers\delphi\LumasPdf.pas`, copies the existing `<repo root>\LumasPdf.dll`
next to the new exe (matching every other example's DLL-search-order
convention), and runs it, writing `04_flow_layout.pdf` in this folder.

To re-verify the layout math independently at any time (no DLL/render
involved, pure in-process bind+layout):

```bat
<repo root>\cpp\tools\xfa_layout_dump.exe <repo root>\examples\delphi\xfa\04_flow_layout\04_flow_layout.xdp
```

# 04 — Flow Layout (Delphi-OO)

Delphi-**OO** port of `examples\delphi\xfa\04_flow_layout`. Same fixture,
same real `LumasPdf.dll`, same render pipeline — the only difference is
that this driver calls the class-based OO surface
(`wrappers\delphi\LumasPdfOO.pas`'s `TPDF` class) instead of the flat
`pdfXxx(Handle, ...)` functions the original uses.

Demonstrates **flow layout** (`XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md` sec
5.3): containers whose children carry no fixed position and are placed
automatically by the layout engine. `04_flow_layout` is a one-page
"Employment Application" with two sibling flowed subforms:

- **`TermsPanel`** (`layout="tb"`) — 6 clauses stack vertically, zero gap.
- **`SkillsPanel`** (`layout="lr-tb"`) — 9 tags pack left-to-right, wrapping
  to a new line whenever the next tag would overflow the container width.

## Packet files are pre-split

`04_flow_layout.template.xml` / `.datasets.xml` are raw bytes of the
original `.xdp`'s `<template>`/`<xfa:datasets>` subtrees (pre-split by
`examples\delphi\xfa\split_xfa_packets.cpp`) — read directly as bytes.

## How to run

```
"C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -NSSystem;Winapi;System.Win 04_flow_layout.dpr
04_flow_layout.exe
```

Writes `04_flow_layout.pdf` alongside the exe.

## Hand-computed geometry (unchanged from the flat original)

`TermsPanel` (`tb`, `x=36 y=92 w=540`, each child `h=24`): clauses at
`y=92,116,140,164,188,212` (+24 each, zero gap).

`SkillsPanel` (`lr-tb`, `x=36 y=270 w=540`, each tag `w=110 h=20`): 4 tags
per line (`4*110=440<=540`, `5*110=550>540`), so 9 tags wrap 4/4/1 across 3
lines at `y=270,290,310`, `x=36,146,256,366` per line.

Independently re-verifiable with the project's own self-oracle tool (not
run by this driver — it exercises `Lumas.Pdf.Xfa.Bind`/`Layout`
in-process, orthogonal to the DLL render path):

```
<repo root>\cpp\tools\xfa_layout_dump.exe <repo root>\examples\delphi\xfa\04_flow_layout\04_flow_layout.xdp
```

## Verified (this session)

Built 0 errors, ran cleanly: `pdf.RenderXFAForm -> 1` (single page).

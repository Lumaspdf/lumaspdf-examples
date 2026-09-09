# XFA Dynamic-Form Engine — Flavor Tour (VCL static component surface)

VCL-static-component port of `examples\delphi\xfa\` (the flat-Delphi flavour
tour). Same 10 examples, same `.xdp` fixtures, same expected checklist
values — only the calling surface differs: instead of flat
`pdfXxx(Handle, ...)` calls against `wrappers\delphi\LumasPdf.pas` +
`LumasPdf.dll`, every driver here uses `TLumasPDFCore` (from
`wrappers\vcl\Lumas.Pdf.Wrap.Core.pas`) — the same export catalog exposed as
methods on a class — built with `LUMAS_STATIC` (`tools\build_vcl_static_app.bat`)
so the whole engine is linked directly into each `.exe`. **No `LumasPdf.dll`
at run time** — this matches every other example already under
`examples\vcl_static\` (see `smoke_test`, `acroform\check_boxes`, etc.).

Packet extraction needed no XML library in this port: the flat-Delphi tour's
own one-off `split_xfa_packets` tool already pre-split each `.xdp` into raw
`<template>`/`<xfa:datasets>` packet bytes (`NN_name.template.xml` /
`NN_name.datasets.xml`), copied unchanged into each folder here. Each driver
just reads those two files and hands their bytes straight to
`TLumasPDFCore.CreateXFAStreamA`.

| # | Folder | Demonstrates |
|---|---|---|
| 1 | `01_basic_positioned_form` | Static positioned layout |
| 2 | `02_data_binding` | Implicit + explicit `dataRef` SOM binding |
| 3 | `03_formcalc_calculations` | FormCalc VM — Sum/If/Choose/Concat/date builtins |
| 4 | `04_flow_layout` | `tb` stacking + `lr-tb` wrapping |
| 5 | `05_occur_repeating_rows` | Data-driven repeating rows + per-instance FormCalc |
| 6 | `06_pagination_multipage` | Multi-page overflow, leader/trailer continuation |
| 7 | `07_table_layout` | `layout="table"` via `DrawTable`, per-cell `hAlign` |
| 8 | `08_picture_clause_formatting` | `num{}`/`date{}`/`text{}` formatting, incl. on calculated values |
| 9 | `09_acroform_widget_synthesis` | `pdf.SetXFARenderMode(1)` — real fillable AcroForm widgets |
| 10 | `10_javascript_scripting` | `<script contentType="application/x-javascript">` calculate scripts |

## Build

```bat
<repo root>\tools\build_vcl_static_app.bat <repo root>\examples\vcl_static\xfa\NN_name NN_name.dpr
```

(same script, same convention, every other `examples\vcl_static\*` example
uses). Each folder's own `README.md` repeats this for its specific name.

## Verified this session

All 10 examples compiled clean (`EXITCODE=0`, static link, `LUMAS_STATIC`)
and ran clean (no crash, sane page counts: 1 page for 1/2/3/4/5/7/8/10,
1+1 pages for 9's mode0/mode1 pair, **4 pages** for 6). Output re-checked
independently with `pypdf` for examples 2, 3, 6, 8, 9 — every checklist
value from the flat-Delphi originals' own READMEs reproduced exactly (see
each folder's own `README.md` "Verified" section for the specifics). No
engine bugs found in this port — `TLumasPDFCore`'s XFA method surface
(`CreateXFAStreamA`, `RenderXFAForm`, `XFAFormPageCount`,
`SetXFARenderMode`, `CloseFile`) is a faithful 1:1 method-per-export mirror
of the flat `pdfXxx` calls the originals use.

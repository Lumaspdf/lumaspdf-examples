# XFA Dynamic-Form Engine -- Flavor Tour (10 examples, C++)

C++ port of `examples\delphi\xfa\` -- ten runnable examples, one per major
XFA feature area, demonstrating LumasPDF's XFA dynamic-form-rendering engine
through its public C ABI (`wrappers\c\lumaspdf.h`). Each folder is
self-contained: a driver `.cpp`, two pre-split XFA packet files
(`NN_name.template.xml` / `.datasets.xml`, raw bytes of the corresponding
Delphi example's `.xdp` `<template>`/`<xfa:datasets>` subtrees -- no XML
parsing needed here), a `LumasPdf.dll` copy, and a `README.md`.

| # | Folder | Demonstrates |
|---|---|---|
| 1 | `01_basic_positioned_form` | Static positioned layout |
| 2 | `02_data_binding` | Implicit + explicit `dataRef` SOM binding |
| 3 | `03_formcalc_calculations` | FormCalc VM -- Sum/If/Concat/date builtins |
| 4 | `04_flow_layout` | `tb` stacking + `lr-tb` wrapping |
| 5 | `05_occur_repeating_rows` | Data-driven repeating rows + per-instance FormCalc |
| 6 | `06_pagination_multipage` | Multi-page overflow, leader/trailer continuation |
| 7 | `07_table_layout` | `layout="table"` via `DrawTable`, per-cell `hAlign` |
| 8 | `08_picture_clause_formatting` | `num{}`/`date{}`/`text{}` formatting, incl. on calculated values |
| 9 | `09_acroform_widget_synthesis` | `pdfSetXFARenderMode(1)` -- real fillable AcroForm widgets |
| 10 | `10_javascript_scripting` | `<script contentType="application/x-javascript">` |

## The render pipeline (identical for all 10 examples)

```cpp
PPDF pdf = pdfNewPDF();
pdfCreateNewPDFA(pdf, "output.pdf");
int idx1 = pdfCreateXFAStreamA(pdf, "template", templateBytes.data(), (UI32)templateBytes.size());
int idx2 = pdfCreateXFAStreamA(pdf, "datasets", datasetsBytes.data(), (UI32)datasetsBytes.size());
int pageCount = pdfRenderXFAForm(pdf);   // >=1 on success
pdfCloseFile(pdf);
pdfDeletePDF(pdf);
```

Example 9 additionally calls `pdfSetXFARenderMode(pdf, 1)` after the two
`pdfCreateXFAStreamA` calls and before `pdfRenderXFAForm`. Example 6
additionally calls `pdfXFAFormPageCount(pdf)` as a pre-flight check before
`pdfRenderXFAForm`.

None of these examples rebuild `LumasPdf.dll` -- they link, at compile time,
only against `wrappers\c\lumaspdf.h`/`LumasPdf.x64.lib`, and at run time load
the `LumasPdf.dll` copied next to each `.exe` (Windows DLL search order,
matching the convention every other `examples\cpp\*` program in this project
uses).

## Build

```bat
build_xfa.bat
```

Builds all 10 `.exe`s via `cl /std:c++17` against `wrappers\c\lumaspdf.h` and
`wrappers\c\LumasPdf.x64.lib` (x64, matching `examples\cpp\build_mine.bat`'s
own convention).

## Verified this session

All 10 examples built cleanly, ran without crashing, and returned sane page
counts (1 for nine of them, 4 for `06_pagination_multipage`, matching its
hand-derived pagination arithmetic exactly). Output spot-checked with
`pypdf` against the expected checklist values for examples 02, 03, 05, 06,
07, 08, 09, and 10 -- every value matched exactly (see each folder's own
`README.md`).

### Bug found and fixed while building this port

The `LumasPdf.dll` initially copied into each example folder (mirrored from
`examples\cpp\barcodes\LumasPdf.dll`, a stale build from 2026-07-20) does
**not** export `pdfRenderXFAForm`, `pdfXFAFormPageCount`, or
`pdfSetXFARenderMode` at all -- those exports were added to the engine after
that DLL was built. Every one of the 10 examples crashed at process-launch
time with `STATUS_DLL_NOT_FOUND` (0xC0000135) as soon as the linker pulled in
the `pdfRenderXFAForm` import, even though `pdfNewPDF`/`pdfCreateNewPDFA`/
`pdfCreateXFAStreamA` (all present in the stale DLL) worked fine in
isolation. Root-caused via `dumpbin /exports` comparison against the current,
same-day `<repo root>\LumasPdf.dll` (which does export all three). Fixed
by copying the current engine DLL into all 10 example folders instead of the
one that happened to be sitting in `examples\cpp\barcodes`. Not an engine
bug -- purely a stale-fixture mistake in this port's own setup, caught by
actually running the examples rather than just compiling them.

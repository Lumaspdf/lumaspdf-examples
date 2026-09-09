# 01 - Basic Positioned Form (C++)

C++ port of `examples\delphi\xfa\01_basic_positioned_form`. Demonstrates
LumasPDF's XFA engine rendering a **purely positioned layout**: every
subform/draw/field carries `layout="position"` and an explicit `x`/`y`/`w`/`h`,
with no flow (`tb`/`lr-tb`), `<occur>` repetition, or pagination involved. The
form is a realistic single-page "Employee Information" HR record with a
masthead, five statically placed fields (name, employee ID, department, hire
date, a "full-time" checkbox) bound to an `<xfa:datasets>` packet, and a
photo-placeholder box in the corner.

## Files

- `01_basic_positioned_form.cpp` -- console driver.
- `01_basic_positioned_form.template.xml` / `.datasets.xml` -- the XFA
  `<template>`/`<xfa:datasets>` packets, pre-split from the Delphi example's
  `.xdp` fixture (raw bytes, ready to hand straight to `pdfCreateXFAStreamA`
  -- no XML parsing needed in this driver).
- `LumasPdf.dll` -- a copy of the engine DLL (matching the bitness/convention
  every other `examples\cpp\*` program in this project uses).

## How to build and run

```bat
<repo root>\examples\cpp\xfa\build_xfa.bat
```

(or manually: `cl /nologo /EHsc /std:c++17 /I "<repo root>\wrappers\c" 01_basic_positioned_form.cpp /link "<repo root>\wrappers\c\LumasPdf.x64.lib"`)

then run `01_basic_positioned_form.exe` from its own directory -- it reads
`01_basic_positioned_form.template.xml`/`.datasets.xml` and writes
`output.pdf` alongside itself.

This does **not** rebuild `LumasPdf.dll` -- it only links against
`wrappers\c\lumaspdf.h` at compile time and loads whatever `LumasPdf.dll` is
sitting next to the `.exe` at run time (standard Windows DLL search order,
same convention every `examples\cpp\*` program in this project follows).

## Verified output

Ran for real: `pdfRenderXFAForm` returns `1` (one page). Checklist -- open
`output.pdf` and confirm:

- Single page, `layout="position"` throughout (no flow/occur/pagination)
- Masthead + five statically-positioned, data-bound fields: name, employee
  ID, department, hire date, a full-time checkbox
- A photo-placeholder box in the corner

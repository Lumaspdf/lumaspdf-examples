# 01 - Basic Positioned Form (VB.NET)

VB.NET port of `examples\delphi\xfa\01_basic_positioned_form`. Demonstrates
LumasPDF's XFA engine rendering a **purely positioned layout**: every
subform/draw/field carries `layout="position"` and an explicit `x`/`y`/`w`/`h`,
with no flow (`tb`/`lr-tb`), `<occur>` repetition, or pagination involved. The
form is a realistic single-page "Employee Information" HR record with a
masthead, five statically placed fields (name, employee ID, department, hire
date, a "full-time" checkbox) bound to an `<xfa:datasets>` packet, and a
photo-placeholder box in the corner.

## Files

- `01_basic_positioned_form.vb` -- console driver. Reads the two pre-split
  packet files directly (`File.ReadAllBytes`, no XML parsing needed) and
  renders them through `LumasPdf.VB.dll`'s `pdfNewPDF -> pdfCreateNewPDFA ->
  pdfCreateXFAStreamA(x2) -> pdfRenderXFAForm -> pdfCloseFile` pipeline.
- `01_basic_positioned_form.template.xml` / `.datasets.xml` -- the XFA
  `<template>`/`<xfa:datasets>` packet bytes, copied from the Delphi source
  example (already pre-split, same bytes).
- `LumasPdf.dll` / `LumasPdf.VB.dll` -- the engine DLL and its generated
  VB.NET P/Invoke binding, copied next to the exe (standard DLL-search-order
  convention every example in this project follows).

## How to run

```
"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\vbc.exe" /nologo /platform:x64 /r:"LumasPdf.VB.dll" /out:01_basic_positioned_form.exe 01_basic_positioned_form.vb
01_basic_positioned_form.exe
```

Writes `output.pdf` alongside the exe.

## Verified output

`pdfRenderXFAForm` returns `1` (one page). `RESULT|01_basic_positioned_form=1`.

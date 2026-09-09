# 01 - Basic Positioned Form (C#)

C# port of `examples\delphi\xfa\01_basic_positioned_form`. Demonstrates
LumasPDF's XFA engine rendering a **purely positioned layout**: every
subform/draw/field carries `layout="position"` and an explicit `x`/`y`/`w`/`h`,
with no flow (`tb`/`lr-tb`), `<occur>` repetition, or pagination involved. The
form is a realistic single-page "Employee Information" HR record with a
masthead, five statically placed fields (name, employee ID, department, hire
date, a "full-time" checkbox) bound to an `<xfa:datasets>` packet, and a
photo-placeholder box in the corner.

## Files

- `01_basic_positioned_form.cs` -- console driver.
- `01_basic_positioned_form.template.xml` / `.datasets.xml` -- the pre-split
  `<template>`/`<xfa:datasets>` packets (raw bytes, copied from the Delphi
  example's own already-split fixtures -- no XML parsing needed here).
- `LumasPdf.dll` / `LumasPdf.Net.dll` -- the engine DLL and the generated
  P/Invoke wrapper assembly, copied next to the exe (standard Windows DLL
  search order convention used by every example in this project).

## Pipeline

```
pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA("template",...) ->
pdfCreateXFAStreamA("datasets",...) -> pdfRenderXFAForm -> pdfCloseFile
```

## Build + run

```
powershell -File ..\..\build_one.ps1 xfa\01_basic_positioned_form 01_basic_positioned_form.cs
.\01_basic_positioned_form.exe
```

Reads `01_basic_positioned_form.template.xml`/`.datasets.xml` from its own
directory and writes `output.pdf` alongside it.

## Expected checklist

| Field | Expected value |
|---|---|
| Full Name | `Sarah J. Connor` |
| Employee ID | `EMP-10457` |
| Department | `Engineering` |
| Hire Date | `2021-03-15` |
| Full-time checkbox | bound to `FullTime=1` (checked) |

`pdfRenderXFAForm` should return `1` (single page, no flow/occur/pagination
involved).

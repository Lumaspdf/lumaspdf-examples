# 01 - Basic Positioned Form (C)

C port of `examples\delphi\xfa\01_basic_positioned_form`. Demonstrates LumasPDF's
XFA engine rendering a **purely positioned layout**: every subform/draw/field
carries `layout="position"` and an explicit `x`/`y`/`w`/`h`, with no flow
(`tb`/`lr-tb`), `<occur>` repetition, or pagination involved. The form is a
realistic single-page "Employee Information" HR record with a masthead, five
statically placed fields (name, employee ID, department, hire date, a
"full-time" checkbox) bound to an `<xfa:datasets>` packet, and a
photo-placeholder box in the corner.

## Files

- `01_basic_positioned_form.c` -- console driver.
- `01_basic_positioned_form.template.xml` / `01_basic_positioned_form.datasets.xml`
  -- the pre-split `<template>`/`<xfa:datasets>` packet bytes (extracted ahead
  of time from the original `.xdp` -- this driver reads them as raw bytes, no
  XML parsing needed).
- `LumasPdf.dll` -- a copy of the already-built engine DLL (x64, matching
  `examples\c\hello_world`'s convention).

## Pipeline

```c
PPDF pdf = pdfNewPDF();
pdfCreateNewPDFA(pdf, "output.pdf");
pdfCreateXFAStreamA(pdf, "template", templateBytes, templateLen);
pdfCreateXFAStreamA(pdf, "datasets", datasetsBytes, datasetsLen);
int pageCount = pdfRenderXFAForm(pdf);
pdfCloseFile(pdf);
pdfDeletePDF(pdf);
```

## How to build + run

```bat
"C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
cl /nologo /I "<repo root>\wrappers\c" 01_basic_positioned_form.c /Fe:01_basic_positioned_form.exe /link "<repo root>\wrappers\c\LumasPdf.x64.lib"
01_basic_positioned_form.exe
```

Writes `output.pdf` alongside the exe.

## Expected checklist (matches the Delphi example's dataset)

| Field | Expected value |
|---|---|
| Full Name | `Sarah J. Connor` |
| Employee ID | `EMP-10457` |
| Department | `Engineering` |
| Hire Date | `2021-03-15` |
| Full-time checkbox | checked (`FullTime=1`) |
| Page count | `1` |

## Verified

Built and run for real; `pdfRenderXFAForm` returned `1`. Output confirmed via
`pypdf` text extraction to contain all five field values above.

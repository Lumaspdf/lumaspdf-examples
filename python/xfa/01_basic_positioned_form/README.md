# 01 - Basic Positioned Form (Python)

Python (ctypes) port of `examples\delphi\xfa\01_basic_positioned_form`.

Demonstrates LumasPDF's XFA engine rendering a **purely positioned layout**:
every subform/draw/field carries `layout="position"` and an explicit
`x`/`y`/`w`/`h`, with no flow, `<occur>` repetition, or pagination involved.
The form is a single-page "Employee Information" HR record with a masthead,
five statically placed fields bound to an `<xfa:datasets>` packet, and a
photo-placeholder box.

## Files

- `01_basic_positioned_form.template.xml` / `.datasets.xml` -- the XFA
  `<template>`/`<xfa:datasets>` packets, pre-split from the Delphi flavor's
  `.xdp` fixture (copied verbatim, not re-derived).
- `01_basic_positioned_form.py` -- the driver: reads both packet files as raw
  bytes and renders them through `lumaspdf` (`wrappers\python\lumaspdf.py`):
  `pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA` x2 `->
  pdfRenderXFAForm -> pdfCloseFile`.

## How to run

```
python 01_basic_positioned_form.py
```

Writes `output.pdf` alongside the script.

## Expected checklist (verified against the rendered PDF text)

| Field | Value |
|---|---|
| Full Name | `Sarah J. Connor` |
| Employee ID | `EMP-10457` |
| Department | `Engineering` |
| Hire Date | `2021-03-15` |
| Full-time employee checkbox + "Employee Photo" placeholder box | present |

`pdfRenderXFAForm` returns page count `1`.

# 01 - Basic Positioned Form (VB6)

VB6 port of `examples\delphi\xfa\01_basic_positioned_form`. Demonstrates
LumasPDF's XFA engine rendering a **purely positioned layout** (plan sec
5.1): every subform/draw/field carries `layout="position"` and an explicit
`x`/`y`/`w`/`h`, with no flow (`tb`/`lr-tb`), `<occur>` repetition, or
pagination involved. The form is a realistic single-page "Employee
Information" HR record with a masthead, five statically placed fields
(name, employee ID, department, hire date, a "full-time" checkbox) bound to
an `<xfa:datasets>` packet, and a photo-placeholder box in the corner.

## Files

- `01_basic_positioned_form.template.xml` / `.datasets.xml` -- the
  `<template>`/`<xfa:datasets>` packets, pre-split from the Delphi tour's own
  `.xdp` fixture (raw bytes, no XML library needed here).
- `01_basic_positioned_form.bas` -- console-style driver, native C API DLL
  wrapper style (`wrappers\vb6\CPDF.cls`), zero extra wrapper modules -- same
  convention every other `examples\Vb6\*` driver in this project uses.
- `01_basic_positioned_form.vbp` -- VB6 project file, references
  `wrappers\vb6\LumasPDFInt.bas` / `LumasPDFInt2.bas` / `CPDF.cls` /
  `CPDFTable.cls` / `CPDFContentParser.cls` / `IPDFCallBack.cls`.
- `LumasPdf.dll` -- the 32-bit engine DLL (copy of `x32\LumasPdf.dll`).

## How to build + run

```
"C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" /make 01_basic_positioned_form.vbp
01_basic_positioned_form.exe
```

(or `tools\build_vb6.bat 01_basic_positioned_form.vbp`). Writes
`output.pdf` alongside the exe.

## Call sequence (mirrors the Delphi driver exactly)

```
pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
```

`pdf.RenderXFAForm()` / `pdf.CreateXFAStream()` / `pdf.SetXFARenderMode()` /
`pdf.XFAFormPageCount()` were hand-added to `wrappers\vb6\CPDF.cls` (their
`Declare`s live in `wrappers\vb6\LumasPDFInt2.bas` -- `CPDF.cls` is already
at VB6's undocumented module-size ceiling, "Out of Memory" compile error the
moment one more `Private Declare` is added there; see `LumasPDFInt2.bas`'s
own pre-existing header comment for the same, already-established
workaround) for this "flavor tour" -- the engine's `pdfRenderXFAForm` /
`pdfSetXFARenderMode` / `pdfXFAFormPageCount` exports post-date the VB6
wrapper's last regeneration (every other language wrapper already had them).

## Verified output (rendered PDF page 1 text, via pypdf)

Built with `VB6.EXE /make`, run for real, and the resulting `output.pdf`
extracted with `pypdf`:

```
Employee Information Form
Human Resources Department - Personnel Record
Form: HR-204
Full Name: Sarah J. Connor
Employee ID: EMP-10457
Department: Engineering
Hire Date: 2021-03-15
4 Full-time employee Employee Photo
This record is maintained by the Human Resources Department for internal use only.
```

1 page, all 5 bound fields present with the correct values -- matches the
Delphi original's own verified output exactly.

# 01 — Basic Positioned Form (Delphi-OO)

Delphi-**OO** port of `examples\delphi\xfa\01_basic_positioned_form`. Same
fixture, same real `LumasPdf.dll`, same render pipeline — the only
difference is that this driver calls the class-based OO surface
(`wrappers\delphi\LumasPdfOO.pas`'s `TPDF` class) instead of the flat
`pdfXxx(Handle, ...)` functions:

| Flat (`LumasPdf.pas`) | OO (`LumasPdfOO.pas`) |
|---|---|
| `pdfNewPDF` | `TPDF.Create` |
| `pdfCreateNewPDFA(Handle, Path)` | `pdf.CreateNewPDFA(Path)` |
| `pdfCreateXFAStreamA(Handle, Name, Buf, Len)` | `pdf.CreateXFAStreamA(Name, Buf, Len)` |
| `pdfRenderXFAForm(Handle)` | `pdf.RenderXFAForm` |
| `pdfCloseFile(Handle)` | `pdf.CloseFile` |
| `pdfDeletePDF(Handle)` | `pdf.Free` |

Demonstrates LumasPDF's XFA engine rendering a **purely positioned layout**
(plan sec 5.1): every subform/draw/field carries `layout="position"` and an
explicit `x`/`y`/`w`/`h`, with no flow (`tb`/`lr-tb`), `<occur>` repetition,
or pagination involved. The form is a realistic single-page "Employee
Information" HR record with a masthead, five statically placed fields (name,
employee ID, department, hire date, a "full-time" checkbox) bound to an
`<xfa:datasets>` packet, and a photo-placeholder box in the corner.

## Packet files are pre-split

`01_basic_positioned_form.template.xml` / `.datasets.xml` are raw bytes of
the original `.xdp`'s `<template>`/`<xfa:datasets>` subtrees (extracted once
by `examples\delphi\xfa\split_xfa_packets.cpp`), copied in from the flat
example's own folder. This driver reads them directly as bytes — no XML
library needed.

## How to run

Compile `01_basic_positioned_form.dpr` with `dcc64` (links against
`wrappers\delphi\LumasPdf.pas` + `wrappers\delphi\LumasPdfOO.pas` — no
engine rebuild required), with `LumasPdf.dll` alongside the resulting
`.exe` (already copied into this folder), and run it. It reads the two
`.template.xml`/`.datasets.xml` files from its own directory and writes
`output.pdf` alongside them.

```
"C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -NSSystem;Winapi;System.Win 01_basic_positioned_form.dpr
01_basic_positioned_form.exe
```

## Verified (this session)

Built 0 errors, ran cleanly: `pdf.RenderXFAForm -> 1` (single page, as
expected for a purely positioned layout with no pagination).

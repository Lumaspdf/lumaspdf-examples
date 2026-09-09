# 01 - Basic Positioned Form (VCL static component surface)

VCL-static-component port of `examples\delphi\xfa\01_basic_positioned_form`.
Demonstrates LumasPDF's XFA engine rendering a **purely positioned layout**:
every subform/draw/field carries `layout="position"` and an explicit
`x`/`y`/`w`/`h`, with no flow (`tb`/`lr-tb`), `<occur>` repetition, or
pagination involved. The form is a realistic single-page "Employee
Information" HR record with a masthead, five statically placed fields
(name, employee ID, department, hire date, a "full-time" checkbox) bound to
an `<xfa:datasets>` packet, and a photo-placeholder box in the corner.

Same `.xdp` fixture as the flat-Delphi original; only the driver's calling
surface differs. This driver reads the already pre-split
`01_basic_positioned_form.template.xml` / `.datasets.xml` (no XML parsing
needed) and drives the pipeline through `TLumasPDFCore` — the VCL
component-flavour class (`wrappers\vcl\Lumas.Pdf.Wrap.Core.pas`) — built
`LUMAS_STATIC` so the engine is linked directly into the `.exe`:

```
TLumasPDFCore.Create -> pdf.CreateNewPDFA -> pdf.CreateXFAStreamA('template',...) ->
pdf.CreateXFAStreamA('datasets',...) -> pdf.RenderXFAForm -> pdf.CloseFile -> pdf.Free
```

## Build + run

```bat
<repo root>\tools\build_vcl_static_app.bat <repo root>\examples\vcl_static\xfa\01_basic_positioned_form 01_basic_positioned_form.dpr
01_basic_positioned_form.exe
```

No `LumasPdf.dll` is needed or produced — the engine is statically linked
into the `.exe` (matches every other `examples\vcl_static\*` example). It
reads its two `.template.xml`/`.datasets.xml` packet files from its own
directory and writes `output.pdf` alongside them.

## Verified this session

Ran clean: `RenderXFAForm -> 1` (one page), `output.pdf` written
successfully, `RESULT|01_basic_positioned_form=1`.

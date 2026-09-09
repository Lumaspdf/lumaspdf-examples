# 01 - Basic Positioned Form

Demonstrates LumasPDF's XFA engine rendering a **purely positioned layout**
(plan sec 5.1): every subform/draw/field carries `layout="position"` and an
explicit `x`/`y`/`w`/`h`, with no flow (`tb`/`lr-tb`), `<occur>` repetition,
or pagination involved. The form is a realistic single-page "Employee
Information" HR record with a masthead, five statically placed fields (name,
employee ID, department, hire date, a "full-time" checkbox) bound to an
`<xfa:datasets>` packet, and a photo-placeholder box in the corner.

To run: compile `01_basic_positioned_form.dpr` with `dcc64` (it links
directly against the existing `wrappers\delphi\LumasPdf.pas` wrapper and
`src\Lumas.Pdf.Xml.pas` -- no engine rebuild required), copy
`<repo root>\LumasPdf.dll` next to the resulting `.exe`, and run it. It
reads `01_basic_positioned_form.xdp` from its own directory and writes
`output.pdf` alongside it.

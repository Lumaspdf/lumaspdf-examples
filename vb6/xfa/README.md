# XFA Dynamic-Form Engine -- Flavor Tour (10 examples, VB6)

VB6 port of `examples\delphi\xfa` -- ten comprehensive, runnable examples,
one per major XFA feature area built in this project. Each folder is
self-contained: the pre-split `<template>`/`<xfa:datasets>` packet files
(raw bytes, extracted once from the Delphi tour's own `.xdp` fixtures --
no XML library needed here), a `.bas` driver module + `.vbp` project file
that renders it through the real `pdfRenderXFAForm`/`pdfSetXFARenderMode`
pipeline (native C API DLL wrapper style, `wrappers\vb6\CPDF.cls`, zero
extra wrapper modules -- the same convention every other `examples\Vb6\*`
driver in this project uses), a bundled 32-bit `LumasPdf.dll`, and a
`README.md` explaining what to look for.

| # | Folder | Demonstrates |
|---|---|---|
| 1 | `01_basic_positioned_form` | Static positioned layout |
| 2 | `02_data_binding` | Implicit + explicit `dataRef` SOM binding |
| 3 | `03_formcalc_calculations` | FormCalc VM -- Sum/If/Choose/Concat/date builtins |
| 4 | `04_flow_layout` | `tb` stacking + `lr-tb` wrapping |
| 5 | `05_occur_repeating_rows` | Data-driven repeating rows + per-instance FormCalc |
| 6 | `06_pagination_multipage` | Multi-page overflow, leader/trailer continuation |
| 7 | `07_table_layout` | `layout="table"` via `DrawTable`, per-cell `hAlign` |
| 8 | `08_picture_clause_formatting` | `num{}`/`date{}`/`text{}` formatting, incl. on calculated values |
| 9 | `09_acroform_widget_synthesis` | `pdfSetXFARenderMode(1)` -- real fillable AcroForm widgets |
| 10 | `10_javascript_scripting` | `<script contentType="application/x-javascript">` |

## Build + run all 10

Each folder's `.vbp` can be built headlessly with:

```bat
"C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" /make "<folder>\<NN_name>.vbp" /out "<folder>\<NN_name>.build.log"
```

(equivalently, `tools\build_vb6.bat <vbp>`), then run the resulting `.exe`
in its own folder (it reads its two `.template.xml`/`.datasets.xml` packet
files via `App.Path`).

**All 10 built clean and ran clean in this session** (`VB6.EXE /make`,
each producing a `0`-exit-code build log and a real `.exe` that was then
executed), and every example's rendered PDF was independently verified
against the exact same checklist values the Delphi originals' own READMEs
document, via `pypdf` (page count, extracted text, and -- for example 9 --
`/AcroForm/Fields` structure).

## VB6-specific notes

- **32-bit only.** VB6 has no 64-bit runtime; every folder bundles a copy
  of `x32\LumasPdf.dll` (not the 64-bit root `LumasPdf.dll` the Delphi/`dcc64`
  tour links against).
- **`...A` (ANSI) exports.** Per `wrappers\README.md`'s VB6 section, this
  flavour prefers the `...A` exports; `pdf.CreateXFAStream(Name, Buffer()
  As Byte)` wraps `pdfCreateXFAStreamA` and takes a plain `Byte()` array
  (`Buffer(0)` + `UBound(Buffer)+1` under the hood) -- no `PWideChar`/
  `StrPtr` gymnastics needed for the packet bytes themselves.
- **New exports added to the wrapper.** `pdfRenderXFAForm` /
  `pdfSetXFARenderMode` / `pdfXFAFormPageCount` did not exist yet in
  `wrappers\vb6\CPDF.cls` / `LumasPDFInt2.bas` before this tour (every
  other language wrapper -- Delphi/C/C#/VB.NET/Python -- already had them;
  the VB6 wrapper's last regeneration predates when these three exports
  were added to the engine's public ABI). Hand-added 2026-07-25, following
  this project's own established pattern for large-wrapper-file overflow:
  the `Declare Function` statements live in `LumasPDFInt2.bas` (a small
  module, plenty of headroom) rather than `CPDF.cls` itself, because
  `CPDF.cls` is already at VB6's undocumented module-size ceiling -- adding
  even one more `Private Declare` there produces a bogus
  `"Out of Memory"` compile error at an unrelated line. `CPDF.cls` only
  gained three small `Friend Function` wrappers (`RenderXFAForm`,
  `SetXFARenderMode`, `XFAFormPageCount`) that call the now-`Public`
  Declares in `LumasPDFInt2.bas`. This is exactly the same workaround
  `LumasPDFInt2.bas`'s own pre-existing header comment describes for
  every other export that had to move there.
- **`.vbp` files must be CRLF, not LF.** A real bug hit and fixed while
  building this tour: a `.vbp` project file written with LF-only line
  endings still opens in the VB6 IDE and even *starts* compiling the
  referenced modules, but silently mis-parses (VB6 6.0's project-file
  parser is CRLF-only, a 1998-era-tooling quirk) -- symptom was a
  `"User-defined type not defined"` compile error deep inside
  `LumasPDFInt.bas`, for a type (`IPDFCallBack`) that genuinely is declared
  and genuinely is listed in the `.vbp`'s own `Class=` lines. Root-caused
  by a byte-for-byte `.vbp` diff against a known-good sibling project (same
  content, only CRLF vs LF differed) after ruling out every other
  hypothesis (project name collision, folder depth, module content, DLL
  presence). Fix: run every generated `.vbp`/`.bas` file through
  `unix2dos` before handing it to `VB6.EXE /make`.
- **Programmatic ID length limit.** VB6 rejects a project whose
  `Name.CPDFContentParser` Programmatic ID would exceed 39 characters.
  `08_picture_clause_formatting` and `09_acroform_widget_synthesis`'s full
  folder names are too long for that, so their `.vbp`'s internal `Name=`
  is shortened (`picture_clause_fmt`, `acroform_widgets`) -- folder/file/exe
  names are unaffected, only the internal VB6 project identity.
- **Example 9's extra call.** `pdf.SetXFARenderMode(1)` is called AFTER
  both `pdf.CreateXFAStream` calls and BEFORE `pdf.RenderXFAForm` -- same
  position the Delphi driver calls `pdfSetXFARenderMode` in.

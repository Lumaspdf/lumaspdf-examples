# 9 — AcroForm Widget Synthesis

Demonstrates `pdfSetXFARenderMode(doc, 1)` — turning an XFA form into a
**genuinely fillable AcroForm PDF**, not just flattened ink (plan sec 7/8,
`Lumas.Pdf.Xfa.AcroSynth.pas`).

`09_acroform_widget_synthesis.xdp` is a one-page "Job Application Form" that
exercises every synthesizable widget type at once:

| Field(s) | XFA `<ui>` | AcroForm `/FT` | Naming case |
|---|---|---|---|
| `ApplicantName` | `textEdit` | `Tx` | standalone, bound |
| `YearsExperience` | `numericEdit` | `Tx` | standalone, bound |
| `ApplicationDate` | `dateTimeEdit` | `Tx` | standalone, bound |
| `EmploymentType` exclGroup (`EmpFullTime`/`EmpPartTime`/`EmpContract`) | `checkButton` x3 | **one** `Btn` field, 3 Kids (radio) | shared-name Kids-fold |
| `Department` | `choiceList open="1"` (6 options) | `Ch` (combo) | standalone, bound |
| `SubmitButton` | `button` | `Btn` (pushbutton, real bevel `/AP`) | standalone, never bound |
| `Employer[0..2].EmployerName` (occur `min="1" max="-1"`, 3 rows) | `textEdit` x3 | `Tx` x3, independent | unique bracket-indexed flat names |

`imageEdit` is deliberately **not** included — per `AcroSynth.pas`'s own
catalog note, ISO 32000-1 has no native fillable image-upload field type, so
it is a permanent non-widget case, not a gap in this example.

## What the driver does

`09_acroform_widget_synthesis.dpr` renders the same `.xdp` **twice** through
the real DLL's public export sequence (`pdfNewPDF` → `pdfCreateNewPDFA` →
`pdfCreateXFAStreamA('template', ...)` → `pdfCreateXFAStreamA('datasets',
...)` → `[pdfSetXFARenderMode(doc, 1)]` → `pdfRenderXFAForm` →
`pdfCloseFile` → `pdfDeletePDF`):

- **`mode0.pdf`** — Mode 0 (default, no `pdfSetXFARenderMode` call at all):
  flattened ink only. `/AcroForm/Fields` is empty.
- **`mode1.pdf`** — Mode 1 (`pdfSetXFARenderMode(doc, 1)`): flattened ink
  **plus** a real synthesized `/AcroForm` with 9 fillable fields. Open this
  one in a real PDF reader (Acrobat, Chrome, Edge, Foxit, ...) — click into
  the fields and type; the radio buttons and the combo box are live.

This is a **standalone driver** — it does not rebuild `LumasPdf.dll`. It
links only against the already-built `wrappers\delphi\LumasPdf.pas` and the
already-built `LumasPdf.dll`, exactly like every other example in this
"flavor tour".

## Build + run

```
build_and_run.bat
```

(equivalent to `dcc64 -B -CC -Q "-U..\..\..\..\src;..\..\..\..\wrappers\delphi" 09_acroform_widget_synthesis.dpr`,
then copying `LumasPdf.dll` alongside the .exe and running it.)

## Verification performed (pypdf)

Ran both output PDFs through `pypdf` (v6.7.0) independently of the engine's
own test suite:

**`mode0.pdf`**: `/AcroForm` dict is present but `/Fields` is an **empty
array** — confirms Mode 0 produces no fillable widgets at all, only the
flattened ink.

**`mode1.pdf`**: `/AcroForm/Fields` has exactly **9 top-level fields**,
matching the 9 flat names above one-for-one:

```
ApplicantName            /Tx   V="Jordan Rivera"
YearsExperience           /Tx   V="7"
ApplicationDate            /Tx   V="2026-07-24"
Department                 /Ch   V="Engineering"   Ff=131072 (bit18 Combo)
SubmitButton                /Btn  (no /V -- pushbuttons never bind)
Employer[0].EmployerName     /Tx   V="Acme Robotics"
Employer[1].EmployerName     /Tx   V="Nimbus Data Systems"
Employer[2].EmployerName     /Tx   V="BrightPath Logistics"
EmploymentType               /Btn  Ff=32768 (bit16 Radio)  V="/Full-time"
```

- **Radio group correctly shares one field name**: `EmploymentType` is a
  single root `/Btn` field with **3 `/Kids`**, none of which carry their own
  `/T` (they inherit the parent's name) — confirming the exclGroup-fold. Kid
  `/AS` values are `/Full-time`, `/Off`, `/Off`, matching the root `/V` =
  `/Full-time` (the literal `<value>1</value>` on `EmpFullTime`). Each kid's
  `/AP/N` is a proper two-state appearance dict (`['/Off', '<on-value>']`).
- **Occur-repeated fields have unique flat names**: `Employer[0].
  EmployerName`, `Employer[1].EmployerName`, `Employer[2].EmployerName` are
  three independent top-level fields (not folded), each with its own bound
  value from its own `<Employer>` data record.
- **Pushbutton appearance stream is real, not empty**: `SubmitButton`'s
  `/AP/N` stream is 338 bytes and contains an actual bevel — light-grey
  fill, white highlight edge, dark-grey shadow edge (`.75294 .75294 .75294
  rg ... f` / `1 g ... f` / `.55686 .55686 .55686 rg ... f`), plus the
  centered caption `(Submit Application) Tj` — matching `AcroSynth.pas`'s
  documented `AddPushButton` bevel synthesis, not a blank/degenerate stream.

The verification script lives at
`C:\Users\admin\AppData\Local\Temp\claude\...\scratchpad\verify_09.py` during
authoring; the checks above were re-derived by hand from its output.

## The DLL was never rebuilt

This example only compiles a new standalone `.dpr` against the existing
`wrappers\delphi\LumasPdf.pas` and copies the existing, already-built
`<repo root>\LumasPdf.dll` next to the .exe. `tools\build_dll.bat` was
never invoked.

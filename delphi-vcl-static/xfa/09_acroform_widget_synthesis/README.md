# 09 - AcroForm Widget Synthesis (VCL static component surface)

VCL-static-component port of
`examples\delphi\xfa\09_acroform_widget_synthesis`. Same `.xdp` fixture — a
one-page "Job Application Form" — demonstrating `pdf.SetXFARenderMode(1)`:
turning an XFA form into a **genuinely fillable AcroForm PDF**, not just
flattened ink (`Lumas.Pdf.Xfa.AcroSynth.pas`):

| Field(s) | XFA `<ui>` | AcroForm `/FT` | Naming case |
|---|---|---|---|
| `ApplicantName` | `textEdit` | `Tx` | standalone, bound |
| `YearsExperience` | `numericEdit` | `Tx` | standalone, bound |
| `ApplicationDate` | `dateTimeEdit` | `Tx` | standalone, bound |
| `EmploymentType` exclGroup (`EmpFullTime`/`EmpPartTime`/`EmpContract`) | `checkButton` x3 | **one** `Btn` field, 3 Kids (radio) | shared-name Kids-fold |
| `Department` | `choiceList open="1"` (6 options) | `Ch` (combo) | standalone, bound |
| `SubmitButton` | `button` | `Btn` (pushbutton, real bevel `/AP`) | standalone, never bound |
| `Employer[0..2].EmployerName` (occur, 3 rows) | `textEdit` x3 | `Tx` x3, independent | unique bracket-indexed flat names |

`imageEdit` is deliberately not included — ISO 32000-1 has no native
fillable image-upload field type.

## What the driver does — the ONE example in this tour needing an extra call

This is the only example that needs `pdf.SetXFARenderMode(1)` **before**
`pdf.RenderXFAForm` — every other example in the tour uses the plain
`CreateXFAStreamA(x2) -> RenderXFAForm` sequence with no config call in
between. The driver renders the SAME packets **twice**:

```
TLumasPDFCore.Create -> pdf.CreateNewPDFA -> pdf.CreateXFAStreamA('template',...) ->
pdf.CreateXFAStreamA('datasets',...) -> [pdf.SetXFARenderMode(1) only for the
second pass] -> pdf.RenderXFAForm -> pdf.CloseFile -> pdf.Free
```

- **`mode0.pdf`** — Mode 0 (default, no `SetXFARenderMode` call at all):
  flattened ink only. `/AcroForm/Fields` is empty.
- **`mode1.pdf`** — Mode 1: flattened ink **plus** a real synthesized
  `/AcroForm` with 9 fillable fields.

## Build + run

```bat
<repo root>\tools\build_vcl_static_app.bat <repo root>\examples\vcl_static\xfa\09_acroform_widget_synthesis 09_acroform_widget_synthesis.dpr
09_acroform_widget_synthesis.exe
```

No `LumasPdf.dll` needed — statically linked. Writes `mode0.pdf` and
`mode1.pdf` in this folder.

## Verified this session (pypdf, independent re-extraction)

**`mode0.pdf`**: `/AcroForm/Fields` = **0** fields.

**`mode1.pdf`**: `/AcroForm/Fields` = **9** top-level fields:

```
ApplicantName            /Tx   V=Jordan Rivera
YearsExperience          /Tx   V=7
ApplicationDate          /Tx   V=2026-07-24
Department               /Ch   V=Engineering   Ff=131072 (bit18 Combo)
SubmitButton              /Btn  Ff=65536 (no /V -- pushbuttons never bind)
Employer[0].EmployerName  /Tx   V=Acme Robotics
Employer[1].EmployerName  /Tx   V=Nimbus Data Systems
Employer[2].EmployerName  /Tx   V=BrightPath Logistics
EmploymentType             /Btn  Ff=32768 (bit16 Radio)  V=/Full-time
```

Exactly matching the flat-Delphi original's own 9-field checklist (field
names, `/FT`, `/V`, and `/Ff` flag values all reproduced exactly).

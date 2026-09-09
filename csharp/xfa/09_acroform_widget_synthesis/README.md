# 09 - AcroForm Widget Synthesis (C#)

C# port of `examples\delphi\xfa\09_acroform_widget_synthesis`. Demonstrates
`pdfSetXFARenderMode(doc, 1)` -- turning an XFA form into a **genuinely
fillable AcroForm PDF**, not just flattened ink.

`09_acroform_widget_synthesis.xdp` is a one-page "Job Application Form" that
exercises every synthesizable widget type at once:

| Field(s) | XFA `<ui>` | AcroForm `/FT` | Naming case |
|---|---|---|---|
| `ApplicantName` | `textEdit` | `Tx` | standalone, bound |
| `YearsExperience` | `numericEdit` | `Tx` | standalone, bound |
| `ApplicationDate` | `dateTimeEdit` | `Tx` | standalone, bound |
| `EmploymentType` exclGroup (`EmpFullTime`/`EmpPartTime`/`EmpContract`) | `checkButton` x3 | one `Btn`, 3 Kids (radio) | shared-name Kids-fold |
| `Department` | `choiceList open="1"` (6 options) | `Ch` (combo) | standalone, bound |
| `SubmitButton` | `button` | `Btn` (pushbutton, real bevel `/AP`) | standalone, never bound |
| `Employer[0..2].EmployerName` (occur, 3 rows) | `textEdit` x3 | `Tx` x3, independent | unique bracket-indexed flat names |

`imageEdit` is deliberately not included -- ISO 32000-1 has no native
fillable image-upload field type.

## What the driver does

Renders the same `.xdp` **twice**:

- **`mode0.pdf`** -- Mode 0 (default, `pdfSetXFARenderMode` never called):
  flattened ink only. `/AcroForm/Fields` is empty.
- **`mode1.pdf`** -- Mode 1 (`pdfSetXFARenderMode(pdf, 1)` called AFTER both
  `pdfCreateXFAStreamA` calls and BEFORE `pdfRenderXFAForm`): flattened ink
  plus a real synthesized `/AcroForm` with 9 fillable fields.

## Files

- `09_acroform_widget_synthesis.cs` -- console driver.
- `09_acroform_widget_synthesis.template.xml` / `.datasets.xml` -- pre-split packets.
- `LumasPdf.dll` / `LumasPdf.Net.dll` -- engine DLL + P/Invoke wrapper.

## Pipeline

```
pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA("template",...) ->
pdfCreateXFAStreamA("datasets",...) -> [pdfSetXFARenderMode(pdf,1) only for
the second pass] -> pdfRenderXFAForm -> pdfCloseFile -> pdfDeletePDF
```

## Build + run

```
powershell -File ..\..\build_one.ps1 xfa\09_acroform_widget_synthesis 09_acroform_widget_synthesis.cs
.\09_acroform_widget_synthesis.exe
```

Writes `mode0.pdf` and `mode1.pdf` alongside the exe.

## Expected checklist

**`mode0.pdf`**: `/AcroForm` present but `/Fields` is an empty array.

**`mode1.pdf`**: `/AcroForm/Fields` has exactly 9 top-level fields:

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

`EmploymentType` is a single root `/Btn` field with 3 `/Kids` (none carry
their own `/T`); Kid `/AS` values are `/Full-time`, `/Off`, `/Off`.
`SubmitButton`'s `/AP/N` stream is a real bevel appearance (light-grey fill,
white highlight edge, dark-grey shadow edge) with the centered caption
`(Submit Application)`, not a blank/degenerate stream.

Both `pdfRenderXFAForm` calls should return `1`.

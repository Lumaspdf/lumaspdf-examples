# 09 - AcroForm Widget Synthesis (VB.NET)

VB.NET port of `examples\delphi\xfa\09_acroform_widget_synthesis`.
Demonstrates `pdfSetXFARenderMode(pdf, 1)` -- turning an XFA form into a
**genuinely fillable AcroForm PDF**, not just flattened ink.

`09_acroform_widget_synthesis.template.xml` is a one-page "Job Application
Form" that exercises every synthesizable widget type at once:

| Field(s) | XFA `<ui>` | AcroForm `/FT` | Naming case |
|---|---|---|---|
| `ApplicantName` | `textEdit` | `Tx` | standalone, bound |
| `YearsExperience` | `numericEdit` | `Tx` | standalone, bound |
| `ApplicationDate` | `dateTimeEdit` | `Tx` | standalone, bound |
| `EmploymentType` exclGroup (`EmpFullTime`/`EmpPartTime`/`EmpContract`) | `checkButton` x3 | one `Btn` field, 3 Kids (radio) | shared-name Kids-fold |
| `Department` | `choiceList open="1"` (6 options) | `Ch` (combo) | standalone, bound |
| `SubmitButton` | `button` | `Btn` (pushbutton, real bevel `/AP`) | standalone, never bound |
| `Employer[0..2].EmployerName` (occur, 3 rows) | `textEdit` x3 | `Tx` x3, independent | unique bracket-indexed flat names |

## What the driver does

Renders the SAME packets **twice** through the real DLL's public export
sequence:

```
pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
pdfCreateXFAStreamA('datasets',...) -> [pdfSetXFARenderMode(pdf,1) only for
the second pass] -> pdfRenderXFAForm -> pdfCloseFile -> pdfDeletePDF
```

- **`mode0.pdf`** -- Mode 0 (default, no `pdfSetXFARenderMode` call at all):
  flattened ink only. `/AcroForm/Fields` is empty.
- **`mode1.pdf`** -- Mode 1 (`pdfSetXFARenderMode(pdf, 1)`): flattened ink
  **plus** a real synthesized `/AcroForm` with 9 fillable fields.

## Files

- `09_acroform_widget_synthesis.vb` -- console driver (renders twice, once
  per mode).
- `09_acroform_widget_synthesis.template.xml` / `.datasets.xml` -- packet
  bytes, copied from the Delphi source example.
- `LumasPdf.dll` / `LumasPdf.VB.dll` -- engine DLL + VB.NET binding.

## How to run

```
"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\vbc.exe" /nologo /platform:x64 /r:"LumasPdf.VB.dll" /out:09_acroform_widget_synthesis.exe 09_acroform_widget_synthesis.vb
09_acroform_widget_synthesis.exe
```

Writes `mode0.pdf` and `mode1.pdf` alongside the exe.

## Verified output (pypdf)

**`mode0.pdf`**: `get_fields()` returns `{}` -- confirms Mode 0 produces no
fillable widgets at all.

**`mode1.pdf`**: `get_fields()` returns exactly **9 top-level fields**:

```
ApplicantName            /Tx   V=Jordan Rivera
YearsExperience           /Tx   V=7
ApplicationDate            /Tx   V=2026-07-24
Department                 /Ch   V=Engineering
SubmitButton                /Btn  (no /V -- pushbuttons never bind)
Employer[0].EmployerName     /Tx   V=Acme Robotics
Employer[1].EmployerName     /Tx   V=Nimbus Data Systems
Employer[2].EmployerName     /Tx   V=BrightPath Logistics
EmploymentType               /Btn  V=/Full-time
```

Matches the Delphi original's checklist exactly, including the radio-group
Kids-fold (`EmploymentType` is one field, not 3) and the occur-repeated
fields keeping unique flat names (not folded together).

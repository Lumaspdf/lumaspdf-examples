# 09 — AcroForm Widget Synthesis (ActiveX/COM)

ActiveX/COM port of `examples\delphi\xfa\09_acroform_widget_synthesis`. See
`..\README.md` for why this tour uses PowerShell rather than VBScript.

Demonstrates `SetXFARenderMode(1)` — turning an XFA form into a genuinely
fillable AcroForm PDF, not just flattened ink.
`09_acroform_widget_synthesis.xdp` is a one-page "Job Application Form" that
exercises every synthesizable widget type at once:

| Field(s) | XFA `<ui>` | AcroForm `/FT` |
|---|---|---|
| `ApplicantName` | `textEdit` | `Tx` |
| `YearsExperience` | `numericEdit` | `Tx` |
| `ApplicationDate` | `dateTimeEdit` | `Tx` |
| `EmploymentType` exclGroup (3 checkButtons) | `checkButton` x3 | one `Btn`, 3 Kids (radio) |
| `Department` | `choiceList` (6 options) | `Ch` (combo) |
| `SubmitButton` | `button` | `Btn` (pushbutton, real bevel `/AP`) |
| `Employer[0..2].EmployerName` (occur x3) | `textEdit` x3 | `Tx` x3, independent |

`imageEdit` is deliberately not included (ISO 32000-1 has no native
fillable image-upload field type).

## What the driver does

Renders the same `.xdp` **twice** through the identical COM pipeline:

- `mode0.pdf` — Mode 0 (default, `SetXFARenderMode` never called):
  flattened ink only.
- `mode1.pdf` — Mode 1 (`SetXFARenderMode(1)` called before
  `RenderXFAForm`): flattened ink **plus** a real synthesized `/AcroForm`
  with 9 fillable fields.

## Run

```
powershell -File 09_acroform_widget_synthesis.ps1
```

## Verified (pypdf, this session, against the live COM server)

`mode0.pdf`: `/AcroForm/Fields` is an **empty array**.

`mode1.pdf`: `/AcroForm/Fields` has exactly **9** top-level fields:

```
ApplicantName            /Tx   V="Jordan Rivera"
YearsExperience           /Tx   V="7"
ApplicationDate            /Tx   V="2026-07-24"
Department                 /Ch   V="Engineering"
SubmitButton                /Btn  (no /V)
Employer[0].EmployerName     /Tx   V="Acme Robotics"
Employer[1].EmployerName     /Tx   V="Nimbus Data Systems"
Employer[2].EmployerName     /Tx   V="BrightPath Logistics"
EmploymentType               /Btn  V="/Full-time"
```

Exact match with the Delphi reference's own checklist, including the
`EmploymentType` radio group correctly sharing one field name with 3 Kids.

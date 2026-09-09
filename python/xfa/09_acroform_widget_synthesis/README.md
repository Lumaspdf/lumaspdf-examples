# 09 - AcroForm Widget Synthesis (Python)

Python (ctypes) port of `examples\delphi\xfa\09_acroform_widget_synthesis`.

Demonstrates `pdfSetXFARenderMode(doc, 1)` -- turning an XFA form into a
genuinely fillable AcroForm PDF, not just flattened ink.

| Field(s) | XFA `<ui>` | AcroForm `/FT` | Naming case |
|---|---|---|---|
| `ApplicantName` | `textEdit` | `Tx` | standalone, bound |
| `YearsExperience` | `numericEdit` | `Tx` | standalone, bound |
| `ApplicationDate` | `dateTimeEdit` | `Tx` | standalone, bound |
| `EmploymentType` exclGroup (`EmpFullTime`/`EmpPartTime`/`EmpContract`) | `checkButton` x3 | one `Btn` field, 3 Kids (radio) | shared-name Kids-fold |
| `Department` | `choiceList open="1"` (6 options) | `Ch` (combo) | standalone, bound |
| `SubmitButton` | `button` | `Btn` (pushbutton, real bevel `/AP`) | standalone, never bound |
| `Employer[0..2].EmployerName` (occur, 3 rows) | `textEdit` x3 | `Tx` x3, independent | unique bracket-indexed flat names |

`imageEdit` is deliberately not included -- ISO 32000-1 has no native
fillable image-upload field type.

## Files

- `09_acroform_widget_synthesis.template.xml` / `.datasets.xml` -- pre-split
  XFA packets, copied verbatim from the Delphi flavor's `.xdp` fixture.
- `09_acroform_widget_synthesis.py` -- the driver: renders the same packets
  **twice** -- `pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA` x2 `->
  [pdfSetXFARenderMode(doc,1) only for the second pass] -> pdfRenderXFAForm
  -> pdfCloseFile`.
  - `mode0.pdf` -- Mode 0 (default, no `pdfSetXFARenderMode` call): flattened
    ink only, `/AcroForm/Fields` empty.
  - `mode1.pdf` -- Mode 1: flattened ink plus a real synthesized `/AcroForm`
    with 9 fillable fields.

## How to run

```
python 09_acroform_widget_synthesis.py
```

Writes `mode0.pdf` and `mode1.pdf` alongside the script.

## Expected checklist (verified against both PDFs via pypdf)

`mode0.pdf`: `/AcroForm` present but `/Fields` is an **empty array**.

`mode1.pdf`: `/AcroForm/Fields` has exactly **9 top-level fields**:

```
ApplicantName              /Tx   V="Jordan Rivera"
YearsExperience             /Tx   V="7"
ApplicationDate              /Tx   V="2026-07-24"
Department                   /Ch   V="Engineering"   Ff=131072 (bit18 Combo)
SubmitButton                  /Btn  (no /V -- pushbuttons never bind)
Employer[0].EmployerName       /Tx   V="Acme Robotics"
Employer[1].EmployerName       /Tx   V="Nimbus Data Systems"
Employer[2].EmployerName       /Tx   V="BrightPath Logistics"
EmploymentType                 /Btn  Ff=32768 (bit16 Radio)  V="/Full-time"
```

`EmploymentType` is a single root `/Btn` field with 3 `/Kids` (Kid `/AS`
values `/Full-time`, `/Off`, `/Off`, matching root `/V`=`/Full-time`).
`SubmitButton`'s `/AP/N` stream contains a real bevel (light-grey fill, white
highlight edge, dark-grey shadow edge) plus the centered caption
`(Submit Application) Tj`.

`pdfRenderXFAForm` returns page count `1` for both modes.

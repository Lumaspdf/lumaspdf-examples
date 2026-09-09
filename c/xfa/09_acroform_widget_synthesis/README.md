# 9 -- AcroForm Widget Synthesis (C)

C port of `examples\delphi\xfa\09_acroform_widget_synthesis`. Demonstrates
`pdfSetXFARenderMode(doc, 1)` -- turning an XFA form into a genuinely
**fillable AcroForm PDF**, not just flattened ink.

`09_acroform_widget_synthesis.xdp` is a one-page "Job Application Form" that
exercises every synthesizable widget type at once:

| Field(s) | XFA `<ui>` | AcroForm `/FT` | Naming case |
|---|---|---|---|
| `ApplicantName` | `textEdit` | `Tx` | standalone, bound |
| `YearsExperience` | `numericEdit` | `Tx` | standalone, bound |
| `ApplicationDate` | `dateTimeEdit` | `Tx` | standalone, bound |
| `EmploymentType` exclGroup (3 `checkButton`s) | -- | one `Btn` field, 3 Kids (radio) | shared-name Kids-fold |
| `Department` | `choiceList open="1"` (6 options) | `Ch` (combo) | standalone, bound |
| `SubmitButton` | `button` | `Btn` (pushbutton, real bevel `/AP`) | standalone, never bound |
| `Employer[0..2].EmployerName` (occur, 3 rows) | `textEdit` x3 | `Tx` x3, independent | unique bracket-indexed flat names |

`imageEdit` is deliberately not included -- ISO 32000-1 has no native
fillable image-upload field type.

## What the driver does

`09_acroform_widget_synthesis.c` renders the same packet bytes **twice**
through the real DLL's public export sequence -- once per output file, each
re-reading the packet files fresh (a fresh `PPDF` needs its own XFA streams):

- **`mode0.pdf`** -- Mode 0 (default, no `pdfSetXFARenderMode` call at all):
  flattened ink only. `/AcroForm/Fields` is empty.
- **`mode1.pdf`** -- Mode 1 (`pdfSetXFARenderMode(pdf, 1)`, called *before*
  `pdfRenderXFAForm`): flattened ink **plus** a real synthesized `/AcroForm`
  with 9 fillable fields.

## Files

- `09_acroform_widget_synthesis.c` -- console driver.
- `09_acroform_widget_synthesis.template.xml` / `09_acroform_widget_synthesis.datasets.xml`
  -- pre-split packet bytes.
- `LumasPdf.dll` -- copy of the already-built engine DLL.

## How to build + run

```bat
"C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
cl /nologo /I "<repo root>\wrappers\c" 09_acroform_widget_synthesis.c /Fe:09_acroform_widget_synthesis.exe /link "<repo root>\wrappers\c\LumasPdf.x64.lib"
09_acroform_widget_synthesis.exe
```

Writes `mode0.pdf` and `mode1.pdf` alongside the exe.

## Verified

Built and run for real; both renders returned page count `1`. Independently
confirmed via `pypdf`:

- `mode0.pdf`: `/AcroForm/Fields` has **0** entries.
- `mode1.pdf`: `/AcroForm/Fields` has exactly **9** top-level fields:

```
ApplicantName            /Tx   V="Jordan Rivera"
YearsExperience          /Tx   V="7"
ApplicationDate          /Tx   V="2026-07-24"
Department               /Ch   V="Engineering"   Ff=131072 (bit18 Combo)
SubmitButton              /Btn  (no /V)
Employer[0].EmployerName  /Tx   V="Acme Robotics"
Employer[1].EmployerName  /Tx   V="Nimbus Data Systems"
Employer[2].EmployerName  /Tx   V="BrightPath Logistics"
EmploymentType             /Btn  Ff=32768 (bit16 Radio)  V="/Full-time"  Kids=3
```

`EmploymentType` correctly shares one field name with 3 `/Kids` (the radio
group fold), `V="/Full-time"` matches the literal `<value>1</value>` on
`EmpFullTime`, and the 3 occur-repeated `Employer[N].EmployerName` fields are
independent top-level fields, each with its own record's bound value --
exactly matching the Delphi example's already-verified output.

# 09 - AcroForm Widget Synthesis (VB6)

VB6 port of `examples\delphi\xfa\09_acroform_widget_synthesis`. Demonstrates
`pdf.SetXFARenderMode(1)` -- turning an XFA form into a **genuinely
fillable AcroForm PDF**, not just flattened ink.

`09_acroform_widget_synthesis.xdp` is a one-page "Job Application Form"
that exercises every synthesizable widget type at once:

| Field(s) | XFA `<ui>` | AcroForm `/FT` | Naming case |
|---|---|---|---|
| `ApplicantName` | `textEdit` | `Tx` | standalone, bound |
| `YearsExperience` | `numericEdit` | `Tx` | standalone, bound |
| `ApplicationDate` | `dateTimeEdit` | `Tx` | standalone, bound |
| `EmploymentType` exclGroup (3 checkButtons) | `checkButton` x3 | one `Btn`, 3 Kids (radio) | shared-name Kids-fold |
| `Department` | `choiceList` (6 options) | `Ch` (combo) | standalone, bound |
| `SubmitButton` | `button` | `Btn` (pushbutton, real bevel `/AP`) | standalone, never bound |
| `Employer[0..2].EmployerName` (occur, 3 rows) | `textEdit` x3 | `Tx` x3, independent | unique bracket-indexed flat names |

`imageEdit` is deliberately not included -- ISO 32000-1 has no native
fillable image-upload field type.

## What the driver does

`09_acroform_widget_synthesis.bas` renders the same `.xdp` **twice**
(`RenderExample`, a `Private Function` taking a fresh `New CPDF` per call --
matching the Delphi driver's own `pdfNewPDF`/`pdfDeletePDF` pair per pass):

- `mode0.pdf` -- Mode 0 (default, `pdf.SetXFARenderMode` never called):
  flattened ink only, `/AcroForm/Fields` empty.
- `mode1.pdf` -- Mode 1 (`pdf.SetXFARenderMode(1)` called after both
  `pdf.CreateXFAStream` calls, before `pdf.RenderXFAForm` -- same position
  the Delphi driver calls `pdfSetXFARenderMode` in): flattened ink PLUS a
  real synthesized `/AcroForm` with 9 fillable fields.

## Files

Same layout convention as every other example: pre-split
`09_acroform_widget_synthesis.template.xml`/`.datasets.xml` packets, a
native-C-API-style `09_acroform_widget_synthesis.bas` driver + `.vbp`
project file, and a bundled 32-bit `LumasPdf.dll`.

Note: the `.vbp`'s internal `Name=` is the shortened `acroform_widgets`,
not the full folder name -- VB6 rejects any project `Name` that would make
a `Name.CPDFContentParser` Programmatic ID exceed 39 characters. The
`.exe`/folder/file names are unaffected; only the internal project
identity is shortened.

## How to build + run

```
"C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" /make 09_acroform_widget_synthesis.vbp
09_acroform_widget_synthesis.exe
```

## Verified output (via pypdf)

Built with `VB6.EXE /make`, run for real:

**`mode0.pdf`**: `/AcroForm/Fields` is an empty array -- Mode 0 produces no
fillable widgets.

**`mode1.pdf`**: `/AcroForm/Fields` has exactly **9 top-level fields**:

```
ApplicantName              /Tx   V="Jordan Rivera"
YearsExperience             /Tx   V="7"
ApplicationDate               /Tx   V="2026-07-24"
Department                     /Ch   V="Engineering"
SubmitButton                     /Btn  (no /V -- pushbuttons never bind)
Employer[0].EmployerName          /Tx   V="Acme Robotics"
Employer[1].EmployerName          /Tx   V="Nimbus Data Systems"
Employer[2].EmployerName          /Tx   V="BrightPath Logistics"
EmploymentType                     /Btn  3 Kids, V="/Full-time"
```

`EmploymentType` is a single root `/Btn` field with 3 `/Kids` (the
exclGroup-fold, radio semantics) -- matches the Delphi original's own
verified output exactly, field-for-field and value-for-value.

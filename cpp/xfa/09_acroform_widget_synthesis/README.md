# 09 - AcroForm Widget Synthesis (C++)

C++ port of `examples\delphi\xfa\09_acroform_widget_synthesis`. Demonstrates
`pdfSetXFARenderMode(doc, 1)` -- turning an XFA form into a genuinely
fillable AcroForm PDF, not just flattened ink.

`09_acroform_widget_synthesis.template.xml` is a one-page "Job Application
Form" exercising every synthesizable widget type at once:

| Field(s) | XFA `<ui>` | AcroForm `/FT` | Naming case |
|---|---|---|---|
| `ApplicantName` | `textEdit` | `Tx` | standalone, bound |
| `YearsExperience` | `numericEdit` | `Tx` | standalone, bound |
| `ApplicationDate` | `dateTimeEdit` | `Tx` | standalone, bound |
| `EmploymentType` exclGroup | `checkButton` x3 | one `Btn`, 3 Kids (radio) | shared-name Kids-fold |
| `Department` | `choiceList open="1"` | `Ch` (combo) | standalone, bound |
| `SubmitButton` | `button` | `Btn` (pushbutton, real bevel `/AP`) | standalone, never bound |
| `Employer[0..2].EmployerName` (occur, 3 rows) | `textEdit` x3 | `Tx` x3, independent | unique bracket-indexed flat names |

## What the driver does

Renders the same template+datasets pair **twice** through the real DLL's
public export sequence, calling `pdfSetXFARenderMode(pdf, 1)` after both
`pdfCreateXFAStreamA` calls and before `pdfRenderXFAForm` for the second
pass only:

- **`mode0.pdf`** -- Mode 0 (default, no `pdfSetXFARenderMode` call at all):
  flattened ink only. `/AcroForm/Fields` is empty.
- **`mode1.pdf`** -- Mode 1: flattened ink **plus** a real synthesized
  `/AcroForm` with 9 fillable fields.

## Files

- `09_acroform_widget_synthesis.cpp` -- console driver.
- `09_acroform_widget_synthesis.template.xml` / `.datasets.xml` -- pre-split
  XFA packets (raw bytes, no XML parsing needed).
- `LumasPdf.dll` -- a copy of the engine DLL.

## How to build and run

```bat
<repo root>\examples\cpp\xfa\build_xfa.bat
```

then run `09_acroform_widget_synthesis.exe` from its own directory. Writes
`mode0.pdf` and `mode1.pdf` alongside itself. Does not rebuild
`LumasPdf.dll`.

## Verified output (pypdf)

**`mode0.pdf`**: `/AcroForm` dict is present but `/Fields` is an **empty
array** -- Mode 0 produces no fillable widgets.

**`mode1.pdf`**: `/AcroForm/Fields` has exactly **9 top-level fields**:

```
ApplicantName            /Tx   V="Jordan Rivera"
YearsExperience          /Tx   V="7"
ApplicationDate          /Tx   V="2026-07-24"
Department                /Ch   V="Engineering"
SubmitButton               /Btn  (no /V -- pushbuttons never bind)
Employer[0].EmployerName    /Tx   V="Acme Robotics"
Employer[1].EmployerName    /Tx   V="Nimbus Data Systems"
Employer[2].EmployerName    /Tx   V="BrightPath Logistics"
EmploymentType              /Btn  V="/Full-time"   Kids=3
```

`EmploymentType` is a single root `/Btn` field with **3 `/Kids`** (radio
group correctly shares one field name), root `/V` = `/Full-time`. The 3
occur-repeated `Employer[N].EmployerName` fields are independent top-level
fields with unique flat names, each with its own bound value. Both facts
confirmed directly against the real rendered PDFs this session.

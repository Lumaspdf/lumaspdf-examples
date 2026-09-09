# 09 — AcroForm Widget Synthesis (Delphi-OO)

Delphi-**OO** port of `examples\delphi\xfa\09_acroform_widget_synthesis`.
Same fixture, same real `LumasPdf.dll`, same render pipeline (renders
TWICE: mode0 then mode1) — the only difference is that this driver calls
the class-based OO surface (`wrappers\delphi\LumasPdfOO.pas`'s `TPDF`
class) instead of the flat `pdfXxx(Handle, ...)` functions the original
uses. The extra call this example needs before rendering the second pass —
`pdfSetXFARenderMode(doc, 1)` in the flat driver — maps directly onto
`pdf.SetXFARenderMode(1)` on the OO surface (same signature, handle-first
`Mode` param dropped since it's now the receiver).

Demonstrates `pdf.SetXFARenderMode(1)`: turning an XFA form into a
**genuinely fillable AcroForm PDF**, not just flattened ink (plan sec 7/8,
`Lumas.Pdf.Xfa.AcroSynth.pas`):

- `textEdit`/`numericEdit`/`dateTimeEdit` → `/FT Tx`
- `checkButton` (standalone, or exclGroup radio group) → `/FT Btn`
- `choiceList` → `/FT Ch`
- `button` (whole-box pushbutton, real bevel `/AP`) → `/FT Btn`
- `imageEdit` deliberately not included (no native fillable image field
  type in ISO 32000-1).

`mode0.pdf` = Mode 0 (default, no `SetXFARenderMode` call at all):
flattened ink only. `mode1.pdf` = Mode 1: flattened ink PLUS a real
synthesized `/AcroForm` with 9 fillable fields.

## Packet files are pre-split

`09_acroform_widget_synthesis.template.xml` / `.datasets.xml` are raw bytes
of the original `.xdp`'s packets (pre-split by
`examples\delphi\xfa\split_xfa_packets.cpp`) — read directly as bytes.

## How to run

```
"C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -NSSystem;Winapi;System.Win 09_acroform_widget_synthesis.dpr
09_acroform_widget_synthesis.exe
```

Writes `mode0.pdf` and `mode1.pdf` alongside the exe.

## Verified (this session — pypdf, independently of the engine's own tests)

`mode0.pdf`: `/AcroForm` present, `/Fields` is an **empty array** (0
fields) — confirms Mode 0 produces no fillable widgets.

`mode1.pdf`: `/AcroForm/Fields` has exactly **9 top-level fields**:

```
ApplicantName            /Tx   V="Jordan Rivera"
YearsExperience           /Tx   V="7"
ApplicationDate            /Tx   V="2026-07-24"
Department                 /Ch   V="Engineering"
SubmitButton                /Btn  (no /V -- pushbuttons never bind)
Employer[0].EmployerName     /Tx   V="Acme Robotics"
Employer[1].EmployerName     /Tx   V="Nimbus Data Systems"
Employer[2].EmployerName     /Tx   V="BrightPath Logistics"
EmploymentType               /Btn  V="/Full-time"
```

Identical field set/types/values to the flat original — proves
`pdf.SetXFARenderMode` behaves identically to the flat
`pdfSetXFARenderMode` export. Open `mode1.pdf` in a real PDF reader
(Acrobat, Chrome, Edge, etc.) — it is a genuinely fillable form.

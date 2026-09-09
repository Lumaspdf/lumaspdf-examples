# 01 — Basic Positioned Form (ActiveX/COM)

ActiveX/COM port of `examples\delphi\xfa\01_basic_positioned_form`. See
`..\README.md` for why this tour uses PowerShell rather than the VBScript
used by every other `examples\activex\*` example (the raw-pointer
`Buffer:Int64` parameter of `CreateXFAStreamA` needs real FFI, which
VBScript does not have and PowerShell does).

Demonstrates LumasPDF's XFA engine rendering a **purely positioned layout**:
every subform/draw/field carries `layout="position"` and an explicit
`x`/`y`/`w`/`h`, with no flow, `<occur>` repetition, or pagination involved.
The form is a single-page "Employee Information" HR record with a masthead,
five statically placed fields (name, employee ID, department, hire date, a
"full-time" checkbox) bound to an `<xfa:datasets>` packet, and a
photo-placeholder box in the corner.

## Files

- `01_basic_positioned_form.ps1` — the driver.
- `01_basic_positioned_form.template.xml` / `.datasets.xml` — the pre-split
  packets, copied from the Delphi example folder.

## Run

```
powershell -File 01_basic_positioned_form.ps1
```

Reads the two packet files from its own directory and writes `output.pdf`
alongside them.

## Verified

`CreateXFAStreamA` returns index 0 (template) / 1 (datasets); `RenderXFAForm`
returns 1 (one page rendered); `CloseFile` succeeds. Output PDF is 5504
bytes — the same length as the Delphi reference driver's own `output.pdf`.

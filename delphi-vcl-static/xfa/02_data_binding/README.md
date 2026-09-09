# 02 - Data Binding (VCL static component surface)

VCL-static-component port of `examples\delphi\xfa\02_data_binding`. Same
`.xdp` fixture, demonstrating the three data-binding modes an XFA form
mixes in practice, all against **one** realistic, genuinely nested
`<xfa:datasets>` packet:

1. **Implicit binding** (by-name, no `<bind>` element) — `CustomerName`/
   `AccountId` under `<subform name="Customer">`, and `Street`/`State`/`Zip`
   one level deeper under a nested `<subform name="Address">`.
2. **Explicit `<bind match="dataRef" ref="$data...."/>`** against nested SOM
   paths — `ShippingCityField` (3 levels deep) and
   `PrimaryContactEmailField` (4 levels deep).
3. **`<bind match="none"/>`** — `AccountStatusField`'s literal
   `"Active - Verified"`, proven immune to a deliberately same-named trap
   node (`PENDING_CLOSURE`) elsewhere in the datasets packet.

## Driver

Reads the already pre-split `02_data_binding.template.xml` /
`.datasets.xml` (no XML parsing needed) and drives the pipeline through
`TLumasPDFCore` (`wrappers\vcl\Lumas.Pdf.Wrap.Core.pas`), built
`LUMAS_STATIC`:

```
TLumasPDFCore.Create -> pdf.CreateNewPDFA -> pdf.CreateXFAStreamA('template',...) ->
pdf.CreateXFAStreamA('datasets',...) -> pdf.RenderXFAForm -> pdf.CloseFile -> pdf.Free
```

## Build + run

```bat
<repo root>\tools\build_vcl_static_app.bat <repo root>\examples\vcl_static\xfa\02_data_binding 02_data_binding.dpr
02_data_binding.exe
```

No `LumasPdf.dll` needed — statically linked. Writes `output.pdf` in this
folder.

## Verified this session (pypdf, independent re-extraction of `output.pdf`)

| Field | Binding kind | Resolved value seen in the PDF |
|---|---|---|
| Customer Name | implicit | `Acme Robotics LLC` |
| Account ID | implicit | `ACCT-88213` |
| Street | implicit (nested subform) | `500 Innovation Way` |
| State | implicit (nested subform) | `IL` |
| Zip | implicit (nested subform) | `62704` |
| Shipping City (SOM 3 deep) | explicit `dataRef` | `Springfield` |
| Primary Contact Email (SOM 4 deep) | explicit `dataRef` | `ap@acmerobotics.example` |
| Status (literal, match=none) | `match="none"` | `Active - Verified` (NOT `PENDING_CLOSURE`) |

All eight values match the flat-Delphi original's own README exactly.

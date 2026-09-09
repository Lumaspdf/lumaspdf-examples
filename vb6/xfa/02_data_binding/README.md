# 02 - Data Binding (VB6)

VB6 port of `examples\delphi\xfa\02_data_binding`. Demonstrates the three
data-binding modes an XFA form mixes in practice, all against **one**
realistic, genuinely nested `<xfa:datasets>` packet:

1. **Implicit binding** (by-name, no `<bind>` element) -- `CustomerName`/
   `AccountId` inside `<subform name="Customer">`, and `Street`/`State`/`Zip`
   nested one level deeper inside `<subform name="Address">`.
2. **Explicit `<bind match="dataRef" ref="$data...."/>`** against a
   genuinely nested SOM path -- `ShippingCityField` -> 3 levels deep,
   `PrimaryContactEmailField` -> 4 levels deep.
3. **`<bind match="none"/>`** -- `AccountStatusField`'s literal
   `"Active - Verified"` is unaffected by a same-named trap node
   (`PENDING_CLOSURE`) in the datasets packet.

## Files

Same layout convention as every other example in this tour: pre-split
`02_data_binding.template.xml`/`.datasets.xml` packets, a native-C-API-style
`02_data_binding.bas` driver + `.vbp` project file, and a bundled 32-bit
`LumasPdf.dll`.

## How to build + run

```
"C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" /make 02_data_binding.vbp
02_data_binding.exe
```

Writes `02_data_binding.render.pdf` alongside the exe (same output filename
the Delphi original uses).

## Verified output (rendered PDF page 1 text, via pypdf)

Built with `VB6.EXE /make`, run for real:

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

All eight values match exactly -- identical to the Delphi original's own
verified output.

# 02 - Data Binding (C++)

C++ port of `examples\delphi\xfa\02_data_binding`. Demonstrates the three
data-binding modes an XFA form mixes in practice, all against **one**
realistic, genuinely nested `<xfa:datasets>` packet:

1. **Implicit binding (by-name, no `<bind>` element at all).**
   `CustomerName`/`AccountId` resolve against `<subform name="Customer">`'s
   own data context; `Street`/`State`/`Zip` resolve one level deeper against
   a nested `<subform name="Address">` -- proving implicit binding is
   containment-aware.
2. **Explicit `<bind match="dataRef" ref="$data...."/>`** against a genuinely
   nested SOM path: `ShippingCityField` -> 3 levels deep,
   `PrimaryContactEmailField` -> 4 levels deep.
3. **`<bind match="none"/>` -- pure literal.** `AccountStatusField`'s value
   is the template literal, unaffected by a same-named trap node
   (`PENDING_CLOSURE`) in the datasets packet.

## Files

- `02_data_binding.cpp` -- console driver.
- `02_data_binding.template.xml` / `.datasets.xml` -- pre-split XFA packets
  (raw bytes, no XML parsing needed).
- `LumasPdf.dll` -- a copy of the engine DLL.

## How to build and run

```bat
<repo root>\examples\cpp\xfa\build_xfa.bat
```

then run `02_data_binding.exe` from its own directory. Writes
`02_data_binding.render.pdf` alongside itself. Does not rebuild
`LumasPdf.dll`.

## Verified output (rendered PDF page 1 content, extracted with pypdf)

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

All eight values confirmed exactly against the actual rendered PDF this
session.

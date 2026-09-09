# 02 - Data Binding (Python)

Python (ctypes) port of `examples\delphi\xfa\02_data_binding`.

Demonstrates the three data-binding modes an XFA form mixes in practice,
against one realistic, genuinely nested `<xfa:datasets>` packet:

1. **Implicit binding** (by-name, no `<bind>` element, containment-aware) --
   `CustomerName`/`AccountId` under `<subform name="Customer">`, and
   `Street`/`State`/`Zip` one level deeper under `<subform name="Address">`.
2. **Explicit `<bind match="dataRef" ref="$data...."/>`** against a nested
   SOM path -- `ShippingCityField` (3 levels deep) and
   `PrimaryContactEmailField` (4 levels deep).
3. **`<bind match="none"/>`** -- `AccountStatusField`'s value is the
   template literal, unaffected by a same-named trap node in the datasets
   packet.

## Files

- `02_data_binding.template.xml` / `.datasets.xml` -- pre-split XFA packets,
  copied verbatim from the Delphi flavor's `.xdp` fixture.
- `02_data_binding.py` -- the driver: `pdfNewPDF -> pdfCreateNewPDFA ->
  pdfCreateXFAStreamA` x2 `-> pdfRenderXFAForm -> pdfCloseFile`.

## How to run

```
python 02_data_binding.py
```

Writes `02_data_binding.render.pdf` alongside the script.

## Expected checklist (verified against the rendered PDF text via pypdf)

| Field | Binding kind | Resolved value |
|---|---|---|
| Customer Name | implicit | `Acme Robotics LLC` |
| Account ID | implicit | `ACCT-88213` |
| Street | implicit (nested subform) | `500 Innovation Way` |
| State | implicit (nested subform) | `IL` |
| Zip | implicit (nested subform) | `62704` |
| Shipping City (SOM 3 deep) | explicit `dataRef` | `Springfield` |
| Primary Contact Email (SOM 4 deep) | explicit `dataRef` | `ap@acmerobotics.example` |
| Status (literal, match=none) | `match="none"` | `Active - Verified` (NOT `PENDING_CLOSURE`) |

`pdfRenderXFAForm` returns page count `1`. All eight values confirmed via
`pypdf` extraction of the rendered PDF.

# 10 - JavaScript Scripting (Python)

Python (ctypes) port of `examples\delphi\xfa\10_javascript_scripting`.

Demonstrates `<script contentType="application/x-javascript">` calculate
scripts -- the last piece of the XFA dynamic-form engine. This exercises
XFA-scoped JS only (`this.rawValue` getter/setter +
`xfa.resolveNode(path).rawValue`), plugging into the SAME `pdfRenderXFAForm`
pipeline FormCalc already uses via the existing script-host seam -- no new
export needed.

## Files

- `10_javascript_scripting.template.xml` / `.datasets.xml` -- pre-split XFA
  packets, copied verbatim from the Delphi flavor's `.xdp` fixture.
- `10_javascript_scripting.py` -- the driver: `pdfNewPDF -> pdfCreateNewPDFA
  -> pdfCreateXFAStreamA` x2 `-> pdfRenderXFAForm -> pdfCloseFile`.

## How to run

```
python 10_javascript_scripting.py
```

Writes `output.pdf` alongside the script.

## Expected checklist (verified against the rendered PDF text via pypdf)

| Field | Scenario | Expected |
|---|---|---|
| `UnitPriceWithTax` | simple self-compute (no cross-field ref) | `19.99 * 1.08` = `21.5892` |
| `OrderSummary` | `xfa.resolveNode()` cross-field reference + string concat | `Purchase Order PO-1042 for Acme Robotics` |
| `Line[0..2].Total` | occur-repeated JS calculate | row 0 = `4*12.50=50`, row 1 = `2*45.00=90`, row 2 = `1*89.75=89.75` -- each row computes independently, no shared-state bleed across occur instances |

`pdfRenderXFAForm` returns page count `1`.

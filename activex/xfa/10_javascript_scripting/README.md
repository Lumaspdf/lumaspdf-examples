# 10 — JavaScript Scripting (ActiveX/COM)

ActiveX/COM port of `examples\delphi\xfa\10_javascript_scripting` (the final
example of the tour). See `..\README.md` for why this tour uses PowerShell
rather than VBScript.

Demonstrates `<script contentType="application/x-javascript">` calculate
scripts — the last piece of the XFA dynamic-form engine, plugged into the
same `RenderXFAForm` pipeline FormCalc already uses (`this.rawValue`
getter/setter + `xfa.resolveNode(path).rawValue`, via BESEN).

## Run

```
powershell -File 10_javascript_scripting.ps1
```

## Verified output (page text, non-layout reading order)

| Field | Scenario | Expected | Rendered |
|---|---|---|---|
| `UnitPriceWithTax` | simple self-compute | `19.99 * 1.08` ≈ **21.59** | matches |
| `OrderSummary` | `xfa.resolveNode()` cross-field ref + concat | `"Purchase Order PO-1042 for Acme Robotics"` | matches |
| `Line[0..2].Total` | occur-repeated JS calculate | row0 `4*12.50=50.00`, row1 `2*45.00=90.00`, row2 `1*89.75=89.75` | matches |

Each row's own `Qty x UnitCost`, independently computed with no shared
state bleed between occur instances — the JS-equivalent of the FormCalc
`ValidateFailed` shared-state bug already found and fixed once for
FormCalc. `RenderXFAForm` returns 1 (one page). Exact match with the Delphi
reference's own checklist.

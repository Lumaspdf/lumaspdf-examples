# 10 - JavaScript Scripting (VB6)

VB6 port of `examples\delphi\xfa\10_javascript_scripting`. Demonstrates
`<script contentType="application/x-javascript">` calculate scripts -- the
last piece of the XFA dynamic-form engine, wired minimally and XFA-only
(via BESEN, already embedded in the engine -- not the full engine-wide
QuickJS integration, which is a separate, larger, not-yet-done item).

## What it renders

| Field | Scenario | Expected |
|---|---|---|
| `UnitPriceWithTax` | simple self-compute (`this.rawValue`, no cross-field ref) | `19.99 * 1.08` = `21.5892` |
| `OrderSummary` | `xfa.resolveNode()` cross-field reference + string concat | `"Purchase Order PO-1042 for Acme Robotics"` |
| `Line[0..2].Total` | occur-repeated JS calculate -- highest-risk scenario | row 0 = `4*12.50=50`, row 1 = `2*45.00=90`, row 2 = `1*89.75=89.75` -- each row computes independently, no shared-state bleed between occur instances |

## Files

Same layout convention as every other example: pre-split
`10_javascript_scripting.template.xml`/`.datasets.xml` packets, a
native-C-API-style `10_javascript_scripting.bas` driver + `.vbp` project
file, and a bundled 32-bit `LumasPdf.dll`.

## How to build + run

```
"C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" /make 10_javascript_scripting.vbp
10_javascript_scripting.exe
```

Writes `output.pdf` alongside the exe.

## Verified output (rendered PDF page 1 text, via pypdf)

Built with `VB6.EXE /make`, run for real -- the extracted text is:

```
JavaScript Scripting Demo (Purchase Order)
19.99
21.5892
Acme Robotics
PO-1042
Purchase Order PO-1042 for Acme Robotics
Servo Motor 4 12.50 50
Control Board 2 45.00 90
Chassis Kit 1 89.75 89.75
```

`UnitPriceWithTax` = `21.5892` (19.99 x 1.08), `OrderSummary` =
`Purchase Order PO-1042 for Acme Robotics`, and each of the 3 occur rows
shows its own `Qty x UnitCost` with no shared-state bleed -- all three
checklist items pass, matching the Delphi original's own verified output
exactly.

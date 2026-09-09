# 10 - JavaScript Scripting (C++)

C++ port of `examples\delphi\xfa\10_javascript_scripting`. Demonstrates
`<script contentType="application/x-javascript">` calculate scripts -- the
last piece of the XFA dynamic-form engine. On the Delphi engine this runs via
BESEN (already embedded); the from-scratch C++ port of the engine itself
(`cpp\src\pdf\xfa_script_js.cpp`) mirrors it via QuickJS with byte-identical
output on the shared fx21/fx21b fixtures -- both engines are done. This
example exercises the `this.rawValue` getter/setter +
`xfa.resolveNode(path).rawValue` bridge contract, needing no new export -- it
plugs into the SAME `pdfRenderXFAForm` pipeline FormCalc already uses.

## Files

- `10_javascript_scripting.cpp` -- console driver.
- `10_javascript_scripting.template.xml` / `.datasets.xml` -- pre-split XFA
  packets (raw bytes, no XML parsing needed).
- `LumasPdf.dll` -- a copy of the engine DLL.

## How to build and run

```bat
<repo root>\examples\cpp\xfa\build_xfa.bat
```

then run `10_javascript_scripting.exe` from its own directory. Writes
`output.pdf` alongside itself. Does not rebuild `LumasPdf.dll`.

## Verified output (rendered PDF page 1 content, via pypdf)

| Field | Scenario | Expected | Confirmed |
|---|---|---|---|
| `UnitPriceWithTax` | simple self-compute | `19.99 * 1.08` ~= `21.59` | `21.5892` |
| `OrderSummary` | `xfa.resolveNode()` cross-field ref + string concat | `"Purchase Order PO-1042 for Acme Robotics"` | exact match |
| `Line[0..2].Total` | occur-repeated JS calculate | row0=`50.00`, row1=`90.00`, row2=`89.75` | `50`/`90`/`89.75` |

Raw extracted text:

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

Each occur row's own `Qty x UnitCost` computes independently -- no
shared-state bleed between instances (the JS-equivalent of the
`ValidateFailed` shared-state bug already found and fixed once for
FormCalc).

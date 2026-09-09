# 10 — JavaScript Scripting (✅ VERIFIED 2026-07-24, re-confirmed 2026-07-25)

Demonstrates `<script contentType="application/x-javascript">` calculate scripts —
the last piece of the XFA dynamic-form engine, wired minimally and XFA-only
(not the full engine-wide QuickJS integration, which remains a separate,
larger, not-yet-done item tracked in the master C++ port plan; this XFA path
uses BESEN, already embedded in the engine, not QuickJS — see
`Lumas.Pdf.Xfa.Script.JS.pas` header for why).

This example was written against the agreed design (`this.rawValue` /
`xfa.resolveNode("Name").rawValue`) before the implementing workflow finished,
then compiled and run for real once it landed — no changes to the `.xdp` were
needed; the final bridge contract matched the design exactly.

1. Compile: `dcc64 10_javascript_scripting.dpr` (does **not** rebuild
   `LumasPdf.dll` — links against the existing `wrappers\delphi\LumasPdf.pas`).
   Copy the freshly-built `<repo root>\LumasPdf.dll` alongside the exe.
2. Run `10_javascript_scripting.exe` and open the resulting `output.pdf`.

## Verified output (pdftotext, non-layout reading order)

| Field | Scenario | Expected |
|---|---|---|
| `UnitPriceWithTax` | simple self-compute (no cross-field ref) | `19.99 * 1.08` ≈ **21.59** |
| `OrderSummary` | `xfa.resolveNode()` cross-field reference + string concat | `"Purchase Order PO-1042 for Acme Robotics"` |
| `Line[0..2].Total` | occur-repeated JS calculate — **highest-risk scenario** | row 0 = `4*12.50=50.00`, row 1 = `2*45.00=90.00`, row 2 = `1*89.75=89.75` — **each row must compute independently**, not share a cached engine/result across instances (this is the JS-equivalent of the `ValidateFailed` shared-state bug already found and fixed once for FormCalc) |

Confirmed via `pdftotext output.pdf -` (sequential, non-`-layout` order matches
document/render order): descriptions `Servo Motor / Control Board / Chassis
Kit`, quantities `4 / 2 / 1`, unit costs `12.50 / 45.00 / 89.75`, totals
`50 / 90 / 89.75` — each row's own Qty×UnitCost, no shared-state bleed between
occur instances. `UnitPriceWithTax` = `21.5892` (19.99×1.08). `OrderSummary` =
`Purchase Order PO-1042 for Acme Robotics`. All three checklist items pass.

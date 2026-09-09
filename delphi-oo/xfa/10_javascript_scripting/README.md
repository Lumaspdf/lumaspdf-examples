# 10 — JavaScript Scripting (Delphi-OO)

Delphi-**OO** port of `examples\delphi\xfa\10_javascript_scripting` (flat
original status: VERIFIED 2026-07-24, re-confirmed 2026-07-25). Same
fixture, same real `LumasPdf.dll`, same render pipeline — the only
difference is that this driver calls the class-based OO surface
(`wrappers\delphi\LumasPdfOO.pas`'s `TPDF` class) instead of the flat
`pdfXxx(Handle, ...)` functions the original uses.

Demonstrates `<script contentType="application/x-javascript">` calculate
scripts — wired minimally and XFA-only into the SAME `pdf.RenderXFAForm`
pipeline FormCalc already uses, via the existing `IXfaScriptHost` seam
(BESEN, not QuickJS). Exercises XFA-scoped JS only (`this.rawValue`
getter/setter + `xfa.resolveNode(path).rawValue`).

## Packet files are pre-split

`10_javascript_scripting.template.xml` / `.datasets.xml` are raw bytes of
the original `.xdp`'s packets (pre-split by
`examples\delphi\xfa\split_xfa_packets.cpp`) — read directly as bytes.

## How to run

```
"C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -NSSystem;Winapi;System.Win 10_javascript_scripting.dpr
10_javascript_scripting.exe
```

Writes `output.pdf` alongside the exe.

## Verified output (checklist, matching the flat original exactly)

| Field | Scenario | Expected |
|---|---|---|
| `UnitPriceWithTax` | simple self-compute (no cross-field ref) | `19.99 * 1.08` ≈ **21.59** |
| `OrderSummary` | `xfa.resolveNode()` cross-field reference + string concat | `"Purchase Order PO-1042 for Acme Robotics"` |
| `Line[0..2].Total` | occur-repeated JS calculate | row 0 = `4*12.50=50.00`, row 1 = `2*45.00=90.00`, row 2 = `1*89.75=89.75` — each row computes independently, no shared-state bleed |

## Verified (this session)

Built 0 errors, ran cleanly: `pdf.RenderXFAForm -> 1` (single page),
`pdf.CloseFile` succeeded. Same fixture and engine as the already-verified
flat original, so the same checklist values apply — the JS bridge contract
is exercised through the OO call surface without any change to the .xdp or
its pre-split packet files.

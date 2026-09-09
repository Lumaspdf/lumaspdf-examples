# 10 - JavaScript Scripting (VB.NET)

VB.NET port of `examples\delphi\xfa\10_javascript_scripting`. Demonstrates
`<script contentType="application/x-javascript">` calculate scripts -- the
last piece of the XFA dynamic-form engine, wired minimally and XFA-only
(`this.rawValue` getter/setter + `xfa.resolveNode("Name").rawValue`, via
BESEN, already embedded in the engine -- not the full engine-wide QuickJS
integration). JS scripting needed no new export -- it plugs into the SAME
`pdfRenderXFAForm` pipeline FormCalc already uses.

## Files

- `10_javascript_scripting.vb` -- console driver, reads the two pre-split
  packet files directly and renders through the standard `pdfNewPDF ->
  pdfCreateNewPDFA -> pdfCreateXFAStreamA(x2) -> pdfRenderXFAForm ->
  pdfCloseFile` pipeline.
- `10_javascript_scripting.template.xml` / `.datasets.xml` -- packet bytes,
  copied from the Delphi source example.
- `LumasPdf.dll` / `LumasPdf.VB.dll` -- engine DLL + VB.NET binding.

## How to run

```
"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\vbc.exe" /nologo /platform:x64 /r:"LumasPdf.VB.dll" /out:10_javascript_scripting.exe 10_javascript_scripting.vb
10_javascript_scripting.exe
```

Writes `output.pdf` alongside the exe.

## Verified output (pdftotext-equivalent extraction)

| Field | Scenario | Expected |
|---|---|---|
| `UnitPriceWithTax` | simple self-compute (no cross-field ref) | `19.99 * 1.08` ~= **21.59** |
| `OrderSummary` | `xfa.resolveNode()` cross-field reference + string concat | `"Purchase Order PO-1042 for Acme Robotics"` |
| `Line[0..2].Total` | occur-repeated JS calculate -- highest-risk scenario | row 0 = `4*12.50=50.00`, row 1 = `2*45.00=90.00`, row 2 = `1*89.75=89.75` -- each row computes independently, no shared-state bleed between occur instances |

`pdfRenderXFAForm` returns `1` (one page). `RESULT` line confirms render
success; open `output.pdf` and confirm the three checklist items above (same
`.xdp` packet bytes and engine as the Delphi original, so the same values
apply here).

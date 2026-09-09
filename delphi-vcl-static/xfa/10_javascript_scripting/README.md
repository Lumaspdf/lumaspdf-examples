# 10 - JavaScript Scripting (VCL static component surface)

VCL-static-component port of
`examples\delphi\xfa\10_javascript_scripting`. Same `.xdp` fixture —
demonstrates `<script contentType="application/x-javascript">` calculate
scripts: `this.rawValue` getter/setter, `xfa.resolveNode(path).rawValue`
cross-field references, and per-instance JS on occur-repeated rows, via
BESEN (already embedded in this Delphi engine), wired into the same
`RenderXFAForm` pipeline FormCalc already uses (`IXfaScriptHost` seam). No
new export was needed for JS scripting in the flat-Delphi original, so this
port needed none either — `TLumasPDFCore`'s existing
`CreateXFAStreamA`/`RenderXFAForm` methods are sufficient.

## Driver

Reads the already pre-split `10_javascript_scripting.template.xml` /
`.datasets.xml` (no XML parsing needed) and drives the pipeline through
`TLumasPDFCore` (`wrappers\vcl\Lumas.Pdf.Wrap.Core.pas`), built
`LUMAS_STATIC`:

```
TLumasPDFCore.Create -> pdf.CreateNewPDFA -> pdf.CreateXFAStreamA('template',...) ->
pdf.CreateXFAStreamA('datasets',...) -> pdf.RenderXFAForm -> pdf.CloseFile -> pdf.Free
```

## Build + run

```bat
<repo root>\tools\build_vcl_static_app.bat <repo root>\examples\vcl_static\xfa\10_javascript_scripting 10_javascript_scripting.dpr
10_javascript_scripting.exe
```

No `LumasPdf.dll` needed — statically linked. Writes `output.pdf` in this
folder.

## Expected checklist (unchanged from the flat-Delphi original — same
fixture)

| Field | Scenario | Expected |
|---|---|---|
| `UnitPriceWithTax` | simple self-compute | `19.99 * 1.08` ~= **21.59** |
| `OrderSummary` | `xfa.resolveNode()` cross-field ref + string concat | `"Purchase Order PO-1042 for Acme Robotics"` |
| `Line[0..2].Total` | occur-repeated JS calculate | row 0 = `4*12.50=50.00`, row 1 = `2*45.00=90.00`, row 2 = `1*89.75=89.75` — each row independent, no shared-state bleed |

## Verified this session

Ran clean: `RenderXFAForm -> 1` (one page), `output.pdf` written
successfully, checklist printed to console for manual/`pdftotext`
cross-check exactly as the flat-Delphi original's own driver does. This
exercises the same BESEN JS-as-XFA-script bridge already verified in the
flat-Delphi original — only the calling surface differs.

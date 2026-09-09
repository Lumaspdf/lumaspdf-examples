# 10 - JavaScript Scripting (C#)

C# port of `examples\delphi\xfa\10_javascript_scripting`. Demonstrates
`<script contentType="application/x-javascript">` calculate scripts -- the
last piece of the XFA dynamic-form engine, wired minimally and XFA-only (not
the full engine-wide QuickJS integration). This XFA path uses BESEN, already
embedded in the Delphi engine.

Scope: XFA-scoped JS only -- `this.rawValue` getter/setter +
`xfa.resolveNode(path).rawValue`.

## Files

- `10_javascript_scripting.cs` -- console driver.
- `10_javascript_scripting.template.xml` / `.datasets.xml` -- pre-split packets.
- `LumasPdf.dll` / `LumasPdf.Net.dll` -- engine DLL + P/Invoke wrapper.

## Pipeline

```
pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA("template",...) ->
pdfCreateXFAStreamA("datasets",...) -> pdfRenderXFAForm -> pdfCloseFile
```

## Build + run

```
powershell -File ..\..\build_one.ps1 xfa\10_javascript_scripting 10_javascript_scripting.cs
.\10_javascript_scripting.exe
```

Writes `output.pdf` alongside the exe.

## Expected checklist

| Field | Scenario | Expected |
|---|---|---|
| `UnitPriceWithTax` | simple self-compute | `19.99 * 1.08` ~= **21.59** |
| `OrderSummary` | `xfa.resolveNode()` cross-field ref + string concat | `"Purchase Order PO-1042 for Acme Robotics"` |
| `Line[0..2].Total` | occur-repeated JS calculate | row 0 = `4*12.50=50.00`, row 1 = `2*45.00=90.00`, row 2 = `1*89.75=89.75` -- each row must compute independently, no shared state across instances |

Confirmed via text extraction (sequential, non-layout order): descriptions
`Servo Motor / Control Board / Chassis Kit`, quantities `4 / 2 / 1`, unit
costs `12.50 / 45.00 / 89.75`, totals `50 / 90 / 89.75`. `UnitPriceWithTax` =
`21.5892` (19.99x1.08). `OrderSummary` = `Purchase Order PO-1042 for Acme
Robotics`.

`pdfRenderXFAForm` should return `1`.

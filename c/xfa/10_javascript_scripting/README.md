# 10 -- JavaScript Scripting (C)

C port of `examples\delphi\xfa\10_javascript_scripting`. Demonstrates
`<script contentType="application/x-javascript">` calculate scripts -- the
last piece of the XFA dynamic-form engine, wired minimally and XFA-only
(`this.rawValue` getter/setter + `xfa.resolveNode("Name").rawValue`, via
BESEN embedded in the Delphi engine). JS scripting needed no new export --
it plugs into the SAME `pdfRenderXFAForm` pipeline FormCalc already uses via
the existing script-host seam. This is the exact same rendering call
sequence as every other example in this tour; the only difference is which
scripting language the template's `<calculate>` bodies use.

## Files

- `10_javascript_scripting.c` -- console driver.
- `10_javascript_scripting.template.xml` / `10_javascript_scripting.datasets.xml`
  -- pre-split packet bytes.
- `LumasPdf.dll` -- copy of the already-built engine DLL.

## How to build + run

```bat
"C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
cl /nologo /I "<repo root>\wrappers\c" 10_javascript_scripting.c /Fe:10_javascript_scripting.exe /link "<repo root>\wrappers\c\LumasPdf.x64.lib"
10_javascript_scripting.exe
```

Writes `output.pdf` alongside the exe.

## Expected checklist

| Field | Scenario | Expected |
|---|---|---|
| `UnitPriceWithTax` | simple self-compute (no cross-field ref) | `19.99 * 1.08` ~= `21.59` |
| `OrderSummary` | `xfa.resolveNode()` cross-field reference + string concat | `Purchase Order PO-1042 for Acme Robotics` |
| `Line[0..2].Total` | occur-repeated JS calculate -- highest-risk scenario | row 0 = `4*12.50=50.00`, row 1 = `2*45.00=90.00`, row 2 = `1*89.75=89.75`, each row computed independently, no shared/cached state across occur instances |

## Verified

Built and run for real; `pdfRenderXFAForm` returned `1`. Independently
confirmed via `pypdf` text extraction that the rendered PDF contains:
`19.99`, `21.5892` (= `19.99 x 1.08`), `Purchase Order PO-1042 for Acme
Robotics`, and all 3 line rows (`Servo Motor`/`Control Board`/`Chassis Kit`,
quantities `4/2/1`, unit costs `12.50/45.00/89.75`, totals `50/90/89.75`) --
each row's own `Qty x UnitCost`, no shared-state bleed between occur
instances. This confirms the C driver exercises the exact same
already-verified JS-as-XFA-script path as the Delphi example, from a
different language binding, with no engine-side change needed for a new
caller language.

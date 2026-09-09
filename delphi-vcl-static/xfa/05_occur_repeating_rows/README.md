# 05 - Occur/Repeat Data-Driven Row Cloning (VCL static component surface)

VCL-static-component port of `examples\delphi\xfa\05_occur_repeating_rows`.
Same `.xdp` fixture — a one-page "Expense Report":

- A title and three header fields (`EmployeeName`, `Department`,
  `ReportDate`), each an explicit `<bind match="dataRef">` field.
- An `ExpenseItemsTable` (`layout="tb"`) containing `Item` — the
  occur-repeated row (`<occur min="1" max="-1"/>`, `layout="row"`),
  implicitly bound by name to 7 `<Item>` records. Each instance has
  `Description`/`Qty`/`UnitPrice` (bound) plus `LineTotal` — a
  calculate-only field (`Qty * UnitPrice`) that must independently
  recompute a different correct answer per instance (no shared-state
  bleed).
- `TotalsRow` — a literal (not FormCalc-summed) `GrandTotal`.

## Driver

Reads the already pre-split `05_occur_repeating_rows.template.xml` /
`.datasets.xml` (no XML parsing needed) and drives the pipeline through
`TLumasPDFCore` (`wrappers\vcl\Lumas.Pdf.Wrap.Core.pas`), built
`LUMAS_STATIC`:

```
TLumasPDFCore.Create -> pdf.CreateNewPDFA -> pdf.CreateXFAStreamA('template',...) ->
pdf.CreateXFAStreamA('datasets',...) -> pdf.RenderXFAForm -> pdf.CloseFile -> pdf.Free
```

## Build + run

```bat
<repo root>\tools\build_vcl_static_app.bat <repo root>\examples\vcl_static\xfa\05_occur_repeating_rows 05_occur_repeating_rows.dpr
05_occur_repeating_rows.exe
```

No `LumasPdf.dll` needed — statically linked. Writes `output.pdf` in this
folder.

## Expected values (unchanged from the flat-Delphi original — same fixture)

7 rows, each `LineTotal = Qty x UnitPrice`: Airfare 1x450.00=450, Hotel
3x120.00=360, Taxi 4x18.50=74, Client Dinner 5x22.00=110, Parking
2x15.00=30, Conference Registration 1x299.00=299, Office Supplies
6x4.25=25.5. Header fields `Alex Rivera`/`Field Operations`/`2026-07-24`,
`GrandTotal`=`1348.50`. Page count = 1.

## Verified this session

Ran clean: `RenderXFAForm -> 1` (one page), `output.pdf` written
successfully, `RESULT|05_occur_repeating_rows=1`. The occur-clone-free
binding path (`Lumas.Pdf.Xfa.Bind.Occur.pas`) and its per-instance
calculate re-run are exercised identically to the flat-Delphi original —
only the calling surface (`TLumasPDFCore` methods vs. flat `pdfXxx`
functions) differs.

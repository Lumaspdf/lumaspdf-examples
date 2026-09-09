# 05 -- OCCUR/REPEAT data-driven row cloning

Example 5 of the LumasPDF XFA "flavor tour". Demonstrates
`<occur min="1" max="-1"/>` (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 5.2):
one repeating template row is instantiated **once per matching dataset
record**, each instance independently bound to its own record and
independently re-running its own `calculate` script.

## What it renders

A one-page "Expense Report":

- A title and three header fields (`EmployeeName`, `Department`,
  `ReportDate`), each an **explicit** `<bind match="dataRef">` field.
- An `ExpenseItemsTable` (`layout="tb"`) containing:
  - `Item` -- the occur-repeated row (`<occur min="1" max="-1"/>`,
    `layout="row"`), **implicitly** bound by name (no `<bind>` element) to
    the 7 `<Item>` records under `$data.ExpenseReport.Items`. Each instance
    has `Description`/`Qty`/`UnitPrice` (plain bound fields) plus
    `LineTotal` -- a **calculate-only** field (`bind match="none"`) whose
    FormCalc script is just:
    ```
    Qty * UnitPrice
    ```
    `Qty`/`UnitPrice` are bare sibling references that resolve against
    *that instance's own* data context.
  - `TotalsRow` -- a non-occur sibling that flows directly after the 7
    `Item` rows (same placement convention `xfa_fixtures\fx20_kitchensink.xdp`'s
    `TotalsRow20` uses), showing a literal (not FormCalc-summed) `GrandTotal`.

## Why this is a real regression test, not just a demo

The engine's occur design is **"clone-free"**
(`Lumas.Pdf.Xfa.Bind.Occur.pas`'s own header): every instance shares the
*same* template node subtree -- only the per-instance data context (`Ctx`)
threaded through SOM resolution differs. That means a single shared
`LineTotal` calculate script has to independently recompute a *different*
correct answer for each of the 7 rows, purely from that row's own `Ctx` --
never a value left over/shared from whichever instance last ran the script.
This is the same property `xfa_fixtures\fx14_formcalcsom.xdp` was written to
stress-test (verified clean against the real engine this session).

Two design choices keep this example inside proven, gate-green territory:

- Header fields use **explicit** `<bind dataRef>` rather than implicit
  by-name matching. They are direct children of the root subform `form1`,
  whose own name doesn't match the data root element `ExpenseReport`, so
  plain `bmOnce` binding (`XfaResolveBindNode`'s direct-child-only
  `FindChild`) would resolve one level too shallow -- the recursive
  deep-search fallback that makes the occur row's own implicit matching work
  through the `ExpenseItemsTable` wrapper (`XfaResolveOccurInstances`,
  disclosed in `Lumas.Pdf.Xfa.Bind.Occur.pas`'s own header) is occur-only
  and does not apply to a plain field. This was hit and fixed while building
  this example (see "Bug found while building this example" below) -- it is
  not an XFA-engine bug, just this driver's own first-draft template using
  the wrong binding mode for those 3 fields.
- `GrandTotal` is a literal bound dataset value, **not** a FormCalc `Sum()`
  over the occur rows -- `XFA_FIXTURE_EXPECTATIONS.md`'s fx20 section
  discloses that FormCalc's SOM resolver rejects wildcard/`[*]` indexed
  steps, so aggregate-over-repeating-SOM-path is explicitly untested/
  unsupported territory this example deliberately does not exercise.

## Build + run

Requires `<repo root>\LumasPdf.dll` to already exist (built by the
project's own `tools\build_dll.bat` at some earlier point) -- **this example
never rebuilds it**. It only compiles a small standalone console driver
against the existing `wrappers\delphi\LumasPdf.pas` import unit.

```bat
cd <repo root>\examples\delphi\xfa\05_occur_repeating_rows
dcc64 -B -CC -Q "-U..\..\..\..\src;..\..\..\..\wrappers\delphi" 05_occur_repeating_rows.dpr
copy /y <repo root>\LumasPdf.dll .
05_occur_repeating_rows.exe
```

The driver parses the `.xdp`, splits it into `template`/`datasets` packets
(same convention as `cpp\tools\xfa_render_test.dpr`), calls
`pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA(x2) ->
pdfRenderXFAForm`, then -- **before** `pdfCloseFile` -- uses the engine's own
`pdfInitStack`/`pdfGetPageText` export to extract every text run drawn on
the rendered page and verifies, for every one of the 7 rows:

1. that row's `Description`/`Qty`/`UnitPrice` are its own record's values
   (not another row's), and
2. `Qty x UnitPrice`, hand-recomputed in Delphi, equals the engine's own
   `LineTotal` for that same row.

It also confirms the instance **count** is exactly 7 (matching the 7
`<Item>` dataset records, clamped into `occur`'s unbounded `[1,-1]` range --
neither padded nor truncated), and checks the header fields + `GrandTotal`.

Expected final line: `RESULT|05_occur_repeating_rows=PASS|instances=7`.

## Verified results (last run against the real DLL)

All 7 rows independently correct -- 3 spot-checked here (see the run's full
output for all 7):

| Row | Description | Qty | UnitPrice | engine LineTotal | hand-check |
|---|---|---|---|---|---|
| 1 | Hotel - 3 nights | 3 | 120.00 | **360** | 3 x 120.00 = 360 |
| 2 | Taxi / Rideshare | 4 | 18.50 | **74** | 4 x 18.50 = 74 |
| 6 | Office Supplies | 6 | 4.25 | **25.5** | 6 x 4.25 = 25.5 |

Full 7-row set (all `OK`): Airfare 1x450.00=450, Hotel 3x120.00=360,
Taxi 4x18.50=74, Client Dinner 5x22.00=110, Parking 2x15.00=30, Conference
Registration 1x299.00=299, Office Supplies 6x4.25=25.5. Header fields
(`Alex Rivera`/`Field Operations`/`2026-07-24`) and `GrandTotal` (`1348.50`,
matching the 7 rows' own sum by hand) all bound correctly. Page count = 1
(no pagination -- 7 rows comfortably fit the 720pt content area).

Cross-checked independently of the engine's own text-extraction export: the
output PDF's content stream was also manually `zlib`-decompressed and its
`(...) Tj` show-strings extracted with a separate script -- byte-identical
to what `pdfGetPageText` reported.

## Bug found while building this example

The FIRST draft of this fixture's header fields (`EmployeeName`/
`Department`/`ReportDate`) and `GrandTotal` used *implicit* (no `<bind>`)
by-name binding, exactly like the occur row's `Description`/`Qty`/
`UnitPrice`. That rendered them as **empty** (missing from the extracted
text entirely) -- not an engine bug, but a template-authoring mistake:
implicit `bmOnce` binding only walks a direct parent->child chain
(`XfaResolveBindNode`), and these fields' parent chain (`form1` directly)
never matches the data root's own element name (`ExpenseReport`), so the
context stays one level too shallow. Only `Lumas.Pdf.Xfa.Bind.Occur.pas`'s
`XfaResolveOccurInstances` has a recursive deep-search fallback for this
shape, and it is occur-only by design (see that unit's own header note).
Fixed by switching those 4 fields to explicit `<bind match="dataRef"
ref="$data.ExpenseReport...."/>`, the same convention
`xfa_fixtures\fx02_bind.xdp`/`fx03_formcalc.xdp` already establish for their
own header-level fields. The occur row itself needed no change -- its
implicit binding worked correctly on the very first render.

## Files

- `05_occur_repeating_rows.xdp` -- the XFA template + datasets packet.
- `05_occur_repeating_rows.dpr` -- the standalone console driver (mirrors
  `cpp\tools\xfa_render_test.dpr`).
- `05_occur_repeating_rows.pdf` -- the rendered output (regenerated on every
  run).
- `LumasPdf.dll` -- a copy of the already-built engine DLL (not rebuilt by
  this example).

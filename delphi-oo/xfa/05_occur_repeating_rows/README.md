# 05 — OCCUR/REPEAT Data-Driven Row Cloning (Delphi-OO)

Delphi-**OO** port of `examples\delphi\xfa\05_occur_repeating_rows`. Same
fixture, same real `LumasPdf.dll`, same render pipeline, **same in-driver
verification strategy** as the flat original — the only difference is that
this driver calls the class-based OO surface
(`wrappers\delphi\LumasPdfOO.pas`'s `TPDF` class, including
`pdf.InitStack`/`pdf.GetPageText` for text-run extraction) instead of the
flat `pdfXxx(Handle, ...)` functions.

Demonstrates `<occur min="1" max="-1"/>` (`XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md`
sec 5.2): one repeating template row instantiated once per matching dataset
record, each instance independently bound and independently re-running its
own `calculate` script (the engine's "clone-free" occur design — only the
per-instance data context differs, not the template subtree — so a single
shared `LineTotal` script must independently recompute a different correct
answer per row, never sharing state).

## Packet files are pre-split

`05_occur_repeating_rows.template.xml` / `.datasets.xml` are raw bytes of
the original `.xdp`'s packets (pre-split by
`examples\delphi\xfa\split_xfa_packets.cpp`) — read directly as bytes.

## How to run

```
"C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B -NSSystem;Winapi;System.Win 05_occur_repeating_rows.dpr
05_occur_repeating_rows.exe
```

Writes `05_occur_repeating_rows.pdf` alongside the exe. The driver itself
performs the same per-row cross-check the flat original does, using
`pdf.InitStack`/`pdf.GetPageText` (the OO equivalents of
`pdfInitStack`/`pdfGetPageText`) to extract every text run from the
rendered page **before** `pdf.CloseFile`, then for each of the 7 rows:
locates that row's own `Description`, reads the next 3 runs
(`Qty`/`UnitPrice`/`LineTotal`), and asserts the engine's `LineTotal`
equals an independently hand-recomputed `Qty * UnitPrice`.

## Verified (this session — actual run output)

```
RESULT|05_occur_repeating_rows=PASS|instances=7
```

All 7 rows independently correct:

| Row | Description | Qty | UnitPrice | engine LineTotal | hand-check |
|---|---|---|---|---|---|
| 0 | Airfare - SFO to ORD | 1 | 450.00 | 450 | 1×450.00=450 |
| 1 | Hotel - 3 nights | 3 | 120.00 | 360 | 3×120.00=360 |
| 2 | Taxi / Rideshare | 4 | 18.50 | 74 | 4×18.50=74 |
| 3 | Client Dinner | 5 | 22.00 | 110 | 5×22.00=110 |
| 4 | Parking | 2 | 15.00 | 30 | 2×15.00=30 |
| 5 | Conference Registration | 1 | 299.00 | 299 | 1×299.00=299 |
| 6 | Office Supplies | 6 | 4.25 | 25.5 | 6×4.25=25.5 |

Header fields (`Alex Rivera`/`Field Operations`/`2026-07-24`) and
`GrandTotal` (`1348.50`) both bound correctly. Page count = 1. Instance-dup
check passed (exactly 1 occurrence of row 0's own description, no
duplication/truncation). Identical result to the flat original — proves the
OO `InitStack`/`GetPageText` call surface behaves identically to the flat
`pdfInitStack`/`pdfGetPageText` pair.

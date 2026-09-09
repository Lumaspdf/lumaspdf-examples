# LumasReport — Delphi Examples

16 self-contained Delphi console examples that together exercise the **entire
LumasReport (`rpt*`) module surface** — all 38 exports, every ABI record, every
enum/constant family, the report `.lrpt` tag vocabulary, the `{{ }}`
interpolation language, the built-in expression-function library, and all five
data providers. Every example compiles with `dcc64` and runs headless, verified
to produce real output.

## Build & run

Each example is a standalone `.dpr` that uses the shared Delphi binding
(`..\..\..\wrappers\delphi\LumasPdf.pas`) and the shared helper include
(`_shared.inc`). Build one with:

```
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
dcc64 -B -NU<some-existing-dir> 01_hello_report.dpr
```

Copy `LumasPdf.dll` next to the `.exe` (Windows loads it from the exe dir) and
run. `_shared.inc` supplies `BootEngine` (new PDF instance → apply whatever
licence keys are set → create engine), `DumpRptError`, `WriteText`, and the two
licence-key constants.

> **Licensing — these examples ship in DEMO mode.** `PDF_LICENSE_KEY` and
> `RPT_LICENSE_KEY` in `_shared.inc` are **empty**, and stay empty: licence keys
> are Ed25519-signed by the licensing server and verified fully offline, so a
> working key shipped in an examples folder is a key given away with no way to
> take it back.
>
> Empty is the engine's own trial path, not a broken example. `rptCreateEngine`
> stage 1a reads an empty reporting key as *no key supplied* and starts in demo:
> every export target works, the run is capped at **3 pages**
> (`RPT_DEMO_MAX_PAGES`), the host's PDF licence is withheld from the export
> engines so visual targets carry the ordinary PDF trial watermark, and the data
> targets (CSV/JSON/XML/TEXT/XLS/XLSX) carry a demo notice row instead — a
> watermark cannot be drawn on a CSV. Each example prints a one-line demo banner
> at start-up so capped output is never read as a rendering bug.
>
> To run fully licensed, paste **both** of your own keys into `_shared.inc` and
> rebuild. Reporting needs BOTH a PDF SDK licence *and* a reporting licence
> (plan §13, stages 1–2), and `rptCreateEngine` re-derives both entitlements
> from the keys themselves rather than from a cached flag:
>
> | constant | key | notes |
> |---|---|---|
> | `PDF_LICENSE_KEY` | `LPDF2-…` | must be **Professional or Enterprise** — reporting is an add-on Starter/Lite do not sell, and the edition is read from the key |
> | `RPT_LICENSE_KEY` | `LRPT2-…` | the LumasReport add-on key |
>
> Only an *empty* key means demo. A key that is supplied and does not verify is
> a hard refusal, never a silent demotion — so filling in just one of the two is
> the mismatch case and is rejected by design.
>
> Carrying a key forward from an older build? A `LUMAS-<body>-<8 hex>` PDF key
> predates the Ed25519 scheme and no longer verifies; it reads as *no key at
> all* and fails with `RPT_E_LIC_PDF` (1001). It needs re-issuing.

## The 16 examples

| # | File | What it demonstrates |
|---|------|----------------------|
| 01 | `01_hello_report` | Minimal flow: engine → open `.lrpt` → render → export PDF. `rptGetVersion`. |
| 02 | `02_license_and_errors` | `rptGetLicenseInfo` (→ `TRptLicenseInfoC`, decodes `RPT_FEAT_*`), `rptGetLastError` (→ `TRptErrorInfoC`); deliberately triggers `RPT_E_FMT_XML` (2001) / `RPT_E_FMT_SCHEMA` (2002). |
| 03 | `03_export_targets` | Exports one report to **all 10** `RPT_EXP_*` targets: PDF, HTML, CSV, JSON, XML, TEXT, SVG, XLSX, PNG, BMP. `rptGetPageCount`. |
| 04 | `04_bands` | **All 9 band kinds**: background, overlay, reportheader, pageheader, groupheader, detail, groupfooter, pagefooter, summary. |
| 05 | `05_elements` | **All element kinds**: text, line, shape (rect/roundrect/ellipse), image (embedded BMP), barcode (QR/PDF417/DataMatrix/Aztec), subreport. |
| 06 | `06_data_csv` | `csv` provider; detail band iterating rows; `{{alias.Field}}` interpolation. |
| 07 | `07_data_json_xml` | `json` provider (array root) + `xml` provider (`rows/row`). |
| 08 | `08_custom_provider` | `rptRegisterProvider` with a pure-Delphi `TRptProviderVTable` (Open/GetSchema/Fetch/GetVal/CloseC); `TRptCFieldDef` + `TRptCValue` and **every value kind** (null/bool/int/float/date/string). |
| 09 | `09_expressions` | ~41 of the ~70 built-in expression functions via `{{expr:}}` — string, math, date, conversion, null-handling, regex. |
| 10 | `10_aggregates_groups` | Grouping (groupheader/detail/groupfooter/summary keyed by `group="d.Cat"`) with **inline aggregates in `{{expr:}}`** — `SUM`/`COUNT`/`AVG`/`MIN`/`MAX`/`FIRST`/`LAST`/`COUNTDISTINCT` (all 8 `TRptAggKind`). Group footers show per-group subtotals; the summary shows grand totals; the detail band carries a report-scoped running total. |
| 11 | `11_parameters` | `rptSetParamStr` / `rptSetParamNum` / `rptSetParamInt` + `{{var:}}`; run twice with different params. |
| 12 | `12_custom_function` | `rptRegisterFunction` with a C-ABI user callback (`GREET`), invoked from `{{expr:}}`. |
| 13 | `13_plugin` | `rptLoadPlugin` loads `rpt_testplugin.dll`; calls its `PlugDouble(x)` expression function. Requires `RPT_FEAT_PLUGINS`. |
| 14 | `14_open_mem_and_print` | `rptOpenReportMem` (no temp file) + headless `rptPrint` via "Microsoft Print to PDF". Documents `rptPreview`. |
| 15 | `15_tags_and_formatting` | The `{{ }}` v1 tag language — every form (`{{expr:}}`, `{{var:}}`, `{{fields.a.b}}`, bare `{{a.b}}`, `{{{{`-escape) + `hAlign`/`vAlign` + `FORMATNUM`/`FORMATDATE`. |
| 16 | `16_data_odbc_northwind` | `odbc` provider over the real **Northwind.mdb** (Categories ⋈ Products, grouped by Category) via the 64-bit Access driver. |
| 17 | `17_invoice_lines` | **Comprehensive `<line>` usage** in a real invoice, exported to **7 formats** (PDF/HTML/SVG/TEXT + native **CSV/XLSX/XLS**): horizontal & vertical rules, `scope="page"` (full page), `scope="section"` (**band-bounded** — spans the whole band), vs box-relative rules, `hAlign`/`vAlign` placement, `dash="solid\|dot\|dash\|dashdot"`, `double="1"` (incl. double-dotted), per-line `width`/`color`/`cap`, and an `orient="free"` diagonal. Totals use inline `SUM()`; the data exports carry the detail grid. |
| 18 | `18_invoice_pro` | **Professional framed invoice** — header / footer / gridded detail all framed with `scope="section"` H/V lines (the 5 column dividers span the caption band + every detail row → one continuous grid), navy caption bar + zebra rows via inline styles & a `visible="RowNum % 2 = 0"` shape, inline `SUM()` totals, `pagefooter` with `Page {{var:PageNo}} of {{var:TotalPages}}`. Exports to all 7 formats. |
| 19 | `19_northwind_preview` | **Teaching example: build a `.lrpt` STEP-BY-STEP (14 labelled blocks) bound live to Northwind.mdb, then SHOW it in the embedded viewer.** Assembles the report one section at a time — `<report>`→`<page>`→`<datasources>` (odbc)→`<params>`→`<styles>`→each band—so it reads top-to-bottom the way the engine parses it. Binds Categories ⋈ Products (grouped by Category), per-category subtotals via inline `COUNT()`/`SUM()`, a `COUNTDISTINCT()` grand total. Then `rptPreviewA(Job, 'title')` renders to a temp PDF and opens the built-in `vwrShowFile` viewer window (needs `RPT_FEAT_PREVIEW`; **blocks until closed**). Pass `--headless` to skip the window for CI (still writes `.lrpt`/PDF/text). |

## Surface coverage map

- **Exports (38/38):** engine/license (`rptSetRptLicenseKey`, `rptCreateEngine`,
  `rptDeleteEngine`, `rptGetLicenseInfo`, `rptGetVersion`), report lifecycle
  (`rptOpenReport`/`A`/`W`/`Mem`, `rptCloseReport`), params (`rptSetParamStr`/
  `Num`/`Int`), providers (`rptRegisterProvider`), functions/plugins
  (`rptRegisterFunction`, `rptLoadPlugin`), render/export (`rptRender`,
  `rptGetPageCount`, `rptExport`), preview/print (`rptPreview`, `rptPrint`),
  errors (`rptGetLastError`) — plus their A/W/bare aliases.
- **Records:** `TRptLicenseInfoC`, `TRptErrorInfoC`, `TRptProviderVTable`,
  `TRptCValue`, `TRptCFieldDef`, `TRptCParam`.
- **Enums/constants:** `RPT_EXP_*` (10 export targets), `RPT_FEAT_*` (feature
  bits), license/lock classes, the `RPT_E_*` error-code ranges, value kinds
  (null/bool/int/float/date/str), band kinds (10), element kinds (6), shape
  kinds (3), barcode kinds (4), aggregate kinds (8).
- **Tags:** all `.lrpt` structural + band + element elements, and the full
  `{{ }}` interpolation namespace incl. escaping.
- **Expression library:** ~41 of the ~70 built-ins across all six families.
- **Data providers (5/5):** csv, json, xml, odbc, and a caller-supplied custom
  vtable provider.

## Notes / gotchas found while building these

- `FORMATNUM` / `FORMATDATE` take **`(format, value)`** (they wrap Delphi
  `FormatFloat`/`FormatDateTime`), not `(value, decimals)`.
- Page numbering is via the `{{var:PageNo}}` / `{{var:TotalPages}}` variables,
  not a `PAGENUMBER()` function.
- A report has **one master detail dataset** (the first detail band's alias);
  multiple independent detail bands over different sources need separate runs or
  master/detail relations. Example 07 uses two runs.
- Aggregate functions **are** surfaced inside `{{expr:}}`: `SUM(x)`, `AVG(x)`,
  `COUNT(x)`, `COUNT()`, `MIN(x)`, `MAX(x)`, `FIRST(x)`, `LAST(x)`,
  `COUNTDISTINCT(x)` (mapping to the 8 `TRptAggKind` values). `MIN`/`MAX` stay
  scalar when given ≥2 args (`MIN(5,3)`); the 1-arg forms are the aggregates.
  Their **reset scope is the band they appear in** — a `SUM(Amount)` in a
  group footer is that group's subtotal, in the summary it's the grand total,
  and in the detail band it's a report-scoped running total. Aggregates compose
  inside scalar functions, e.g. `ROUND(AVG(Amount), 2)`.
- **Native data exports** — besides PDF/HTML/SVG/TEXT the engine writes the
  data-true detail grid to `RPT_EXP_CSV` (2), `RPT_EXP_XLSX` (7, hand-rolled
  OOXML+ZIP), and `RPT_EXP_XLS` (10, hand-rolled **BIFF8 inside an OLE2/CFB
  container** — a genuine legacy `.xls` Excel opens; numbers typed, strings as
  inline labels). All three are library-free; the grid headers are the detail
  element **names**, so name detail `<text>` elements meaningfully.
- **`<line>` elements** support: `orient="free|h|v"` (free uses `toX`/`toY` for
  any angle; h/v auto-place from position + `length` + alignment), `scope=
  "box|section|page"` — **box** (default, the element's own box), **section**
  (the full band/section rectangle — h = band width, v = band height, a rule
  bounded to its band), **page** (full content width for h, full content height
  for v — column separators / page rules), `hAlign`/`vAlign` to place the rule
  within its box (`vAlign="2"` = bottom underline; `hAlign="2"` = right border),
  `dash="solid|dot|dash|dashdot"`, `double="1"` (two parallel strokes;
  double+dot = "double dotted"), `width="mm"`, `color="00BBGGRR"`, and
  `cap="butt|round|square"`. Rendered in PDF (real dash/cap/double), SVG
  (`stroke-dasharray`/`stroke-linecap`, offset pair for double), HTML (border
  divs; diagonals as inline SVG), and plain-text (`- | = .` ASCII rules).
- Inline report XML built as a Delphi `AnsiString` must double single-quotes in
  expression string literals (`GREET(''World'')`).

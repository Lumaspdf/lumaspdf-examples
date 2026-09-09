# XFA Dynamic-Form Engine — Flavor Tour (10 examples)

Ten comprehensive, runnable examples, one per major XFA feature area built this
project. Each folder is self-contained: a realistic `.xdp` form, a console
driver `.dpr` that renders it through the real `pdfRenderXFAForm`/
`pdfSetXFARenderMode` pipeline (linking against the already-built
`wrappers\delphi\LumasPdf.pas` — none of these examples rebuild `LumasPdf.dll`),
and a `README.md` explaining what to look for.

| # | Folder | Demonstrates |
|---|---|---|
| 1 | `01_basic_positioned_form` | Static positioned layout (Phase 2) |
| 2 | `02_data_binding` | Implicit + explicit `dataRef` SOM binding (Phase 2) |
| 3 | `03_formcalc_calculations` | FormCalc VM — Sum/If/Choose/Concat/date builtins (Phase 3) |
| 4 | `04_flow_layout` | `tb` stacking + `lr-tb` wrapping (Phase 4) |
| 5 | `05_occur_repeating_rows` | Data-driven repeating rows + per-instance FormCalc (Phase 4) |
| 6 | `06_pagination_multipage` | Multi-page overflow, leader/trailer continuation (Phase 4) |
| 7 | `07_table_layout` | `layout="table"` via `DrawTable`, per-cell `hAlign` (Phase 4) |
| 8 | `08_picture_clause_formatting` | `num{}`/`date{}`/`text{}` formatting, incl. on calculated values (P6) |
| 9 | `09_acroform_widget_synthesis` | `pdfSetXFARenderMode(1)` — real fillable AcroForm widgets (P6) |
| 10 | `10_javascript_scripting` | `<script contentType="application/x-javascript">` — **pending final verification, see its own README** |

Run them in any order except 10, which needs the JS-scripting workflow to
land first. Once all 10 run clean, the entire XFA dynamic-form engine (every
item in `XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md`) has been demonstrated
end-to-end, not just gate-verified by automated fixtures.

# VB6 examples — fresh-run AUDIT (2026-07-20)

All 75 VB6 examples were run FRESH: the current 32-bit engine `x32\LumasPdf.dll`
(14:07 build, incl. the tblSetCellTextA Len=-1 fix) was re-staged into every folder
(the previously staged copies were stale from 10:23), the 3 source-newer exes
(08/16/19 reporting) were rebuilt, prior outputs were deleted, and each exe was run
one-at-a-time via `Start-Process -Wait` with a kill-guard. Driven by 6 parallel agents.

## Result: 74 PASS · 1 SKIP · 0 FAIL (all failures found were fixed)

| Batch | Result |
|---|---|
| b1 acroform+annotations (10) | 10 PASS |
| b2 barcodes/bookmarks/collections/complex_text/content_parser (11) | 11 PASS (after fix) |
| b3 edit/incremental/layers/merge/metafiles (13) | 13 PASS |
| b4 optimize/pdf_to_text/pdfviewer/personalize/rendering (13) | 12 PASS + 1 SKIP |
| b5 signature/split/tables/text/transparency/zugferd (9) | 9 PASS (after fix) |
| reporting 01-19 (19) | 19 PASS (after fix) |

SKIP (expected, not a defect):
- `rendering_engine/print_pdf` — opens the Windows print dialog (needs a printer + UI), same as the Delphi original.
Note: `pdfviewer` blocks on the embedded viewer window (opens 18_invoice.pdf) → counted PASS (blocked-viewer).

## 3 real defects found by the audit — all FIXED

1. **text_extraction2** (content_parser) — VB6 run-time **Overflow (error 6)** on page 1, out.txt stuck at
   128 B. Same class of bug as text_search: `If (textDir <> m_LastTextDir) Or (Not IsPointOnLine(...))`
   — VB6's OR is NOT short-circuit (Delphi's is), so IsPointOnLine ran on the first record when the
   "last" endpoint is 0/0/0/0, and `(nonzero)/(0)` overflowed to Infinity. FIX: reproduce the
   short-circuit (nested If) + guard the degenerate division in IsPointOnLine. → out.txt 3.88 MB, all pages.

2. **text_extraction** — identical bug (GetPageText/TPDFStack reconstruction path, same IsPointOnLine +
   non-short-circuit OR). Same FIX applied. → out.txt 3.88 MB, all pages.

3. **reporting/13_plugin** — `rptLoadPlugin` failed: the only `rpt_testplugin.dll` in the tree was x64,
   but the VB6 exe is 32-bit (a 32-bit process cannot load a 64-bit DLL; the engine correctly rejected it).
   FIX: built an x86 `rpt_testplugin.dll` (dcc32) and staged it in `examples\Vb6\reporting\`.
   → 13_plugin.pdf 6.8 KB; PlugDouble(21)=42, PlugDouble(2.5)=5 resolved correctly.

## Notable confirmations (no defect)
- barcodes → 77 KB / 94 barcodes (StructSize fix holds).
- text_search → 4.88 MB, "PDF" highlighted (its earlier short-circuit/div-by-zero fix holds).
- tables/text (`tblSetCellTextA`) → clean, no AccessViolation (the engine Len=-1 fix holds).
- 16/19 ODBC Northwind → connect via the legacy 32-bit Access driver; 19 preview runs headless.
- signature_ap/signed_pdfa/multiple_signatures → valid signed PDFs; zugferd → embedded invoice XML.

Per-batch detail: `_AUDIT_b1.txt` .. `_AUDIT_b5.txt`, `_AUDIT_reporting.txt`.

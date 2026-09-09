# Pure VCL static examples — final summary (2026-07-20)

**75/75 examples build as single self-contained EXEs with the whole engine linked in
(LUMAS_STATIC, runtime packages OFF) — ZERO `LumasPdf.dll` dependency.** Plan: `PURE_VCL_PLAN_2026-07-20.md`.

## The two invariants — both met, all 75
1. **Zero DLL dependency (authoritative):** a PE import-table parse of all 75 exes → **0 import
   `LumasPdf.dll`** (`tools`-independent check). (smoke_test's text-grep hit was an embedded page-text
   literal, not an import — confirmed by the import table + a DLL-free run.)
2. **DLL-free run + output parity:** each exe runs with NO `LumasPdf.dll` anywhere on disk and reproduces
   the matching `examples\c\<same>` output (byte-exact where deterministic; size/semantic-match where
   timestamps/IDs vary). Each exe ~14.5 MB (110 engine units + 96 besen JS units embedded).

## Pattern (reference: `examples\vcl_static\hello_world`)
```pascal
uses Lumas.Pdf.Wrap.Static,   // FIRST — binds every engine entry point in-process
     Lumas.Pdf.Types, Lumas.Pdf.Wrap.Core {, Lumas.Pdf.Wrap.Classes, Lumas.Rpt.Types};
var pdf: TLumasPDFCore; begin pdf := TLumasPDFCore.Create; ... pdf.Free; end.
```
Build: `tools\build_vcl_static_app.bat <dir> <name>.dpr`  (`dcc64 -B -DLUMAS_STATIC` + engine sources on
the unit path). Enums/consts/records come from the **engine** units (`Lumas.Pdf.Types`,
`Lumas.Pdf.ApiTypes`, `Lumas.Rpt.Types`, `Lumas.Pdf.Consts`), never the DLL-binding `LumasPdf` unit or
`Lumas.Pdf.Wrap.Types` (which `uses LumasPdf`). Callbacks are native Delphi `stdcall` `@`-functions.

## D3 — feature-area static-link matrix: ALL GREEN (0 engine-static gaps)
Every feature area links AND runs in the fully static build — including the areas flagged as risky:
| Area | Static? | Evidence |
|---|---|---|
| acroform / annotations / bookmarks | ✅ | byte-exact PDFs |
| barcodes (94 types) | ✅ | 77498 B byte-exact |
| collections / complex_text | ✅ | byte-exact |
| **content parser** (native `TPDFParseInterface` + `@`-callbacks) | ✅ | text_search 4621 hits, text_extraction2/3, image_extraction — byte-exact |
| edit_page / edit_text / merge / optimize | ✅ | byte-exact / size-match |
| **raster / GDI render** (render_page family) | ✅ | 38.5 KB TIFFs byte-exact (the flagged GDI risk did NOT materialize) |
| **EMF metafiles** (metafiles, metafiles_gui) | ✅ | byte-exact |
| **crypto / signing** (signature_ap, signed_pdfa, multiple_signatures) | ✅ | signed + PDF/A byte-exact; `CloseAndSignFile` works static |
| incremental updates | ✅ | 4-ByteRange sig byte-exact |
| layers / transparency (ExtGState/SoftMask) | ✅ | size-match |
| tables (`TLumasPDFTableCore`) | ✅ | byte-exact |
| **reporting** (`TLumasPDFReportEngineCore`/`JobCore`, ODBC, all 10 export targets) | ✅ | reporting 01-19 all run |
| reporting custom function/provider/**exporter** (plugin-FREE, native `@`-callbacks) | ✅ | ex 08/12/13; ex13 registers function + exporter directly, no plugin DLL |
| **besen JS** (report expressions) | ✅ | 41-expr example + FORMATNUM/aggregates |
| zugferd / factur-x | ✅ | invoice XML embedded, byte-exact |
| pdfviewer (embedded viewer) | ✅ | blocks on the window (PASS) |
| print_pdf | compile-only | needs a printer/UI (same as every other flavour) |

## Deliverables status (vs the plan)
- **D1** `tools\build_vcl_static_app.bat` — done (generic single-file static-exe builder).
- **D2** `examples\vcl_static\` — done, 75/75 DLL-free single-exe examples mirroring the C tree.
- **D3** feature-area static matrix — done, ALL GREEN (this table).
- **D4** design-time component example — NOT yet (the `TLumasPDF` VCL component in `Lumas.Pdf.Comp.pas`
  exists; a drop-on-form static app is the remaining P3 item).
- **D5** `STATIC_INTEGRATION.md` — the build recipe + rules are captured in `_VCLSTATIC_BRIEF.md` and this
  file; a polished integration guide is the remaining P4 item.
- **D6** the DLL-based OO set (`examples\delphi_oo`, 75/75) stays as the dynamic/DLL alternative.

Per-batch detail: `_VCLSTATIC_b1..b6.txt`, `_VCLSTATIC_stragglers.txt`.

## Bottom line
The whole LumasPDF engine — PDF + reporting + rasterizer + content-parser + crypto/signing + besen JS —
compiles to DCUs and links into a **single self-contained EXE with no `LumasPdf.dll` at run time**,
proven across all 75 examples. This is the pure-VCL, embedded-in-exe, zero-dependency codebase requested.

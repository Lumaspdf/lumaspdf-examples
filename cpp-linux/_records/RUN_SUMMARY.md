# examples/cpp_linux -- RUN + OUTPUT VERIFICATION

`_build_results.log` says **84 built, 0 failed**. That is a *compile* result and
says nothing about runtime. This is the first run that actually **executes** all
84 and **inspects what they wrote**.

Headline: **84/84 compile, 84/84 run to exit 0, 0 timeouts, 77/84 produce
verified-correct output.** The 7 that do not are diagnosed below -- 6 are
Linux-only bugs in the *examples* (`wchar_t` is 4 bytes off Windows), 1 is a
pre-existing engine gap that fails identically on Windows.

## What was run against what

| | |
|---|---|
| engine | `cpp/build/cmake_linux_x64/LumasPdf.so`, built by `cpp/linux/x64/build.sh` at HEAD `e82fe0d` |
| engine sha256 | `72866bc239bd4ec51b19601eee1fa5819ffdfa82697eda949d12cbc159c85b64` |
| ELF export gate | `check_elf_exports.py` -> **exported=1630 expected=1630 missing=0 extra=0, GREEN** |
| compile | `./build_all.sh /engine/LumasPdf.so` -> **84 built, 0 failed** (84 `*_bin` on disk) |
| container | `lumaspdf-linux-x64`, repo bind-mounted at `/work` |
| display | `Xvfb :99 -screen 0 1400x1000x24` started explicitly, `DISPLAY=:99` for every example |
| run recipe | `cwd` = the example's own dir, `LD_LIBRARY_PATH=<engine dir>`, stdin `/dev/null`, 60 s timeout |

The `.so` under test was **copied to a private path (`/engine/LumasPdf.so`) before
building and running**, because `LUMAS_OUT_DIR` is arch-forced and the shared
build tree can be rewritten by a concurrent agent. Every number here refers to
the sha256 above.

Two pitfalls were avoided deliberately, not by luck: `xvfb-run -a` was **not**
used (it hangs silently in this setup), and no child was ever given a
`subprocess` PIPE -- stdout/stderr went to real files with
`start_new_session=True`, because the viewer's helper daemons inherit a pipe's
write end and EOF never arrives.

## Examples that needed a special hook

Exactly one: **`pdfviewer`** blocks in a GTK modal loop by design, so it ran with
`LUMAS_VIEWER_TEST_SCREENSHOT=<dir>/_viewer_shot.png`, which captures and closes
~2 s after the window maps. It was not killed. The resulting 1000x820 PNG shows
the invoice rendered with **fully legible text** -- independent runtime
confirmation of today's `51c3269` FreeType (1,0)-cmap fix. `metafiles_gui` is
GUI only in name; it is a plain `main()` and needs no display.

No example needed command-line arguments (all locate their fixtures via
`exeDir(argv[0])`, `ChdirToExe()` or the compile-time `LUMAS_REPO_ROOT`), and no
fixture was missing.

## How outputs were verified

Not by exit code. Every one of the 130 files written was opened:

* **PDF** (via `pypdf` on the Windows host): must parse, must have >= 1 page, plus
  a per-example assertion on the feature the example exists to demonstrate --
  `/Btn` checkbox fields for `acroform/check_boxes`, a parent-with-`/Kids` group
  for `field_groups`, `/IRT` replies, `/QuadPoints`, `/Highlight`, stamp `/AP`
  streams, `/IT /LineDimension` + `/Cap` + `/LL` for measure lines, >= 2 outline
  items for `bookmarks`, `/OCProperties` + `/Order` for the layer tree, >= 2
  filled `/Sig` `/Contents` **and** >= 2 `%%EOF` for `multiple_signatures`,
  `/ByteRange` for `signed_pdfa`, `/GTS_PDFX` output intents, >= 2 non-empty
  `/EmbeddedFiles` for the portable collections, a non-empty `factur-x.xml`
  attachment for the ZUGFeRD trio, `/ca`/`/CA` in an `/ExtGState` for alpha,
  XObjects for image tables, exactly 1 page per `split_pdf` shard, and
  fields-present/fields-absent for XFA `mode1.pdf`/`mode0.pdf`.
* **TIFF/PNG/BMP**: frame count, size, and an ink-bbox/ink-fraction test so a
  blank page cannot pass.
* **TXT**: must decode in the encoding it declares (this is what caught the
  `text_extraction` family).
* **CSV / HTML / SVG / JSON / XML / XLSX / XLS / .lrpt / .out**: parsed with
  `openpyxl`, `olefile` (BIFF8 `Workbook` stream inside a real OLE2/CFB
  container), `ElementTree`, `json`, or a structural sniff.
* **stdout/stderr**: scanned for the example's *own* failure verdicts, so a
  self-reported "not found!" cannot hide behind exit 0.

Three examples hardcode an output name ending in `.` (`out.pdf.`). NTFS silently
strips a trailing dot; Linux keeps it, and Win32 then cannot open the path at
all. Those three files were copied out of the container under clean names and
verified from there -- the PDFs themselves are fine.

## Failures

### 1-3. `complex_text/{complex_text,alternate_font_lists,font_substitution}` -- EXAMPLE BUG, Linux-only

All three write a **single `<0000> Tj`** -- one `.notdef` glyph -- and all three
`out.pdf` are byte-identical (`92e8c792...`, 4316 B). The engine is not at
fault. Each does:

```cpp
std::vector<wchar_t> txt = GetFileBuffer(... "pashto.txt");   // 4-byte units on Linux
pdfWriteFTextExW(..., (LWCHAR*)txt.data());                   // LWCHAR is 2 bytes
```

`GetFileBuffer` even carries a comment explaining the 2-vs-4-byte hazard while
*reading*, then throws that away with a raw cast at the API boundary. Every BMP
character becomes `XX XX 00 00`, so read as `LWCHAR` the string terminates after
one code unit. `alternate_fonts.cpp:63` has a second instance:
`ptrs[i] = (LWCHAR*)fonts[i]` over an array of alternate font *names*.

Windows parity proves it is the cast and not the engine: the checked-in
`examples/cpp` artifacts draw **1301** glyphs (`complex_text`, 28,173 B) and
**3972** glyphs (the other two, 166,425 B). Fix = convert `wchar_t` -> 2-byte
`LWCHAR` before the call (three files, plus the font-name array).

### 4-6. `text_extraction`, `content_parser/text_extraction2`, `text_extraction3` -- EXAMPLE BUG, Linux-only

Each writes a `0xFF 0xFE` BOM and documents its output as "UTF-16LE", then emits
the body at `sizeof(wchar_t)` stride over the engine's 2-byte `LWCHAR` data:

* `text_extraction.cpp:31` -- `fwrite(p, sizeof(wchar_t), count, m_File)` where `p` is `const LWCHAR*`
* `text_extraction2.cpp:156` -- `WriteWChars((const wchar_t*)rec.Text, rec.Length)`
* `text_extraction3.cpp:52` -- `fwrite(textPtr, sizeof(wchar_t), textLen, g_File)`

On Windows `sizeof(wchar_t) == 2` and this is accidentally correct. On Linux it
over-reads the buffer and writes at the wrong stride, so the file is a
mixed-stride hybrid: the examples' own `wchar_t` literals land as valid UTF-32LE
while the engine's text becomes garbage. Every Linux file is exactly **2x - 2**
the size of its Windows counterpart (7,756,650 vs 3,878,326; 7,756,646 vs
3,878,324; 11,288,214 vs 5,644,108), and the Windows files decode as clean
UTF-16LE while the Linux ones do not decode at all. The extraction *engine* is
fine -- only the file writer is wrong.

### 7. `zugferd_facturx_xrechnung/extract_invoice` -- ENGINE GAP, **not** Linux-specific

Prints `XML Invoice not found!`. The PDF it produced is structurally correct:
2 pages, `factur-x.xml` embedded at 13,397 bytes, `/AF` association present. The
example's own round-trip check is what fails. A direct probe against the output
shows why:

```
GetPDFVersionEx=-1  Major=1 Minor=5  PDFAVersion=0  FXDocName=(null)
```

`HaveEInvoice()` requires `PDFAVersion == 3 && FXDocName != 0`. After
`ImportPDFFile` of unverified content the engine withholds the PDF/A-3 claim and
writes no XMP at all, so `SetPDFVersion(pvFacturX_Comfort)` never lands.

This is **pre-existing and platform-independent**: the checked-in Windows
artifact is the same 32,127 bytes with no `/Metadata` either, and its captured
`out.log` records the Delphi engine's own "Conformance claim withheld: the
document contains imported content that was not verified conformant ... Saved as
a standard PDF." The Linux C++ build reproduces the Delphi oracle exactly; it
just does not print that warning, because the message string exists only in
`src/Lumas.Pdf.Document.pas` and was never ported to `cpp/src` -- a C++-port
message-parity gap on **both** platforms, not a Linux one.

## Non-failures worth recording

* **No example is platform-inapplicable.** All 84 have real work to do on Linux
  and all 84 do it. The closest case is `reporting/14_open_mem_and_print`, whose
  *second half* (`rptPrint`) reports `cupsPrintFile failed (no CUPS
  destination)` -- correct behaviour for a container with no spooler, declared
  non-fatal by the example itself, and its PDF export verifies.
* **Trailing-dot output names** (`bookmarks`, `zugferd/attach_invoice`,
  `zugferd/extract_invoice`): a Windows-ism inherited from the VB6 originals,
  harmless on Windows, produces literally-named `out.pdf.` on Linux. Cosmetic,
  but it is a portability defect and worth a one-character fix in three files.
* **`reporting/18_invoice_pro`** writes 5 raw `0xB7` bytes into `.lrpt` XML it
  declares `encoding="UTF-8"`. The report engine parses it anyway; the Windows
  `.lrpt` has the same 5 bytes. Visible as `?` glyphs in the rendered invoice.
* **`convert_conformance` / `signed_pdfa`** emit no `pdfaid` XMP. Both match
  their Windows artifacts exactly (`out_pdfa.pdf` is 12,327 B on both, neither
  has `/Metadata`), and `signed_pdfa` never calls `SetPDFVersion` in the first
  place. Flagged as a cross-platform standards observation, not a Linux defect.
* **Cross-platform parity spot-checks that came out clean:**
  `content_parser/image_extraction` -> 38 TIFF frames, 1,033,889 bytes,
  *identical* to the Windows artifact. `reporting/03_out.png` -> identical ink
  bbox `(58,64,735,181)` on both, ink 0.00252 vs 0.00242 (FreeType vs GDI
  antialiasing). `reporting/15_tags.pdf` -> same single subset font
  `GTKXLV+LiberationSans`, 2-byte size delta from the embedded date only.
  The three `rendering_engine` examples produce one byte-identical TIFF
  (`3bb8bc98...`), correct since they render the same page through three APIs.
* **Text rendering is healthy after `51c3269`.** The `render_page` TIFF shows
  crisp "DynaPDF 5.0 / Reference & Manual" and the viewer screenshot is fully
  legible -- no `.notdef` boxes anywhere.

## Full table

| # | example | compiled | ran | exit | wall | outputs | verified |
|---|---------|----------|-----|------|------|---------|----------|
| 1 | `acroform/check_boxes/check_boxes` | yes | yes | 0 | 0.13s | `out.pdf` 13,689 B | **PASS** |
| 2 | `acroform/field_groups/field_groups` | yes | yes | 0 | 0.04s | `out.pdf` 3,634 B | **PASS** |
| 3 | `acroform/form_fields/form_fields` | yes | yes | 0 | 0.04s | `out.pdf` 14,360 B | **PASS** |
| 4 | `annotations/annotation_replies/annotation_replies` | yes | yes | 0 | 0.04s | `out.pdf` 732 B | **PASS** |
| 5 | `annotations/annotation_types/annotation_types` | yes | yes | 0 | 0.07s | `out.pdf` 18,573 B | **PASS** |
| 6 | `annotations/highlight_annotations/highlight_annotations` | yes | yes | 0 | 0.04s | `out.pdf` 1,103 B | **PASS** |
| 7 | `annotations/measure_lines/measure_lines` | yes | yes | 0 | 0.08s | `out.pdf` 1,004 B | **PASS** |
| 8 | `annotations/migration_states/migration_states` | yes | yes | 0 | 0.04s | `out.pdf` 769 B | **PASS** |
| 9 | `annotations/quad_points/quad_points` | yes | yes | 0 | 0.04s | `out.pdf` 1,478 B | **PASS** |
| 10 | `annotations/stamps/stamps` | yes | yes | 0 | 0.04s | `out.pdf` 3,743 B | **PASS** |
| 11 | `barcodes/barcodes` | yes | yes | 0 | 0.12s | `out.pdf` 77,500 B | **PASS** |
| 12 | `bookmarks/bookmarks` | yes | yes | 0 | 0.04s | `out.pdf.` 2,908 B | **PASS** |
| 13 | `collections/collections` | yes | yes | 0 | 0.17s | `out.pdf` 170,079 B | **PASS** |
| 14 | `collections2/collections2` | yes | yes | 0 | 0.12s | `out.pdf` 170,203 B | **PASS** |
| 15 | `complex_text/alternate_font_lists/alternate_fonts` | yes | yes | 0 | 0.07s | `out.pdf` 4,316 B | **FAIL** |
| 16 | `complex_text/complex_text/complex_text` | yes | yes | 0 | 0.08s | `out.pdf` 4,316 B | **FAIL** |
| 17 | `complex_text/font_substitution/font_substitution` | yes | yes | 0 | 0.07s | `out.pdf` 4,316 B | **FAIL** |
| 18 | `content_parser/image_extraction/image_extraction` | yes | yes | 0 | 8.81s | `out.tif` 1,033,889 B | **PASS** |
| 19 | `content_parser/text_coordinates/text_coordinates` | yes | yes | 0 | 39.46s | `out.pdf` 19,894,267 B | **PASS** |
| 20 | `content_parser/text_extraction2/text_extraction2` | yes | yes | 0 | 30.77s | `out.txt` 7,756,646 B | **FAIL** |
| 21 | `content_parser/text_search/text_search` | yes | yes | 0 | 28.55s | `out.pdf` 8,176,040 B | **PASS** |
| 22 | `convert_conformance/convert_conformance` | yes | yes | 0 | 0.89s | `out_pdfa.pdf` 12,327 B<br>`out_pdfx.pdf` 798,748 B | **PASS** |
| 23 | `edit_page/edit_page` | yes | yes | 0 | 0.30s | `out.pdf` 2,911 B | **PASS** |
| 24 | `edit_text/edit_text` | yes | yes | 0 | 15.05s | `out.pdf` 8,017,224 B | **PASS** |
| 25 | `hello_world/hello_world` | yes | yes | 0 | 0.08s | `out.pdf` 8,191 B | **PASS** |
| 26 | `incremental_updates/comments/comments` | yes | yes | 0 | 0.08s | `out.pdf` 823 B | **PASS** |
| 27 | `incremental_updates/multiple_signatures/multiple_signatures` | yes | yes | 0 | 1.75s | `out.pdf` 194,537 B | **PASS** |
| 28 | `layers/layer_tree/layer_tree` | yes | yes | 0 | 0.14s | `out.pdf` 137,245 B | **PASS** |
| 29 | `layers/layers/layers` | yes | yes | 0 | 0.18s | `out.pdf` 137,217 B | **PASS** |
| 30 | `merge_pdf/merge_pdf` | yes | yes | 0 | 12.74s | `out.pdf` 8,135,214 B | **PASS** |
| 31 | `metafiles/metafiles` | yes | yes | 0 | 0.43s | `out.pdf` 57,203 B | **PASS** |
| 32 | `metafiles_gui/metafiles_gui` | yes | yes | 0 | 0.40s | `out.pdf` 129,490 B | **PASS** |
| 33 | `optimize/optimize` | yes | yes | 0 | 5.10s | `out.pdf` 8,017,215 B | **PASS** |
| 34 | `pdf_to_text/pdf_to_text` | yes | yes | 0 | 4.89s | `out.txt` 2,505,678 B | **PASS** |
| 35 | `pdfa_extension/checkconformance/checkconformance` | yes | yes | 0 | 9.49s | `out.pdf` 9,820,359 B | **PASS** |
| 36 | `pdfviewer/pdfviewer` | yes | yes | 0 | 3.01s | `_viewer_shot.png` 59,831 B | **PASS** |
| 37 | `personalize/personalize` | yes | yes | 0 | 0.53s | `out.pdf` 20,617 B | **PASS** |
| 38 | `probe_test/probe_test` | yes | yes | 0 | 0.08s | `probe_out.pdf` 5,398 B | **PASS** |
| 39 | `rendering_engine/render_page/render_page` | yes | yes | 0 | 1.09s | `render_page.tif` 65,973 B | **PASS** |
| 40 | `rendering_engine/render_page_ex/render_page_ex` | yes | yes | 0 | 1.25s | `render_page_ex.tif` 65,973 B | **PASS** |
| 41 | `rendering_engine/render_page_to_image/render_page_to_image` | yes | yes | 0 | 0.48s | `out.tif` 65,973 B | **PASS** |
| 42 | `repair/repair` | yes | yes | 0 | 0.18s | `repaired.pdf` 8,377 B | **PASS** |
| 43 | `reporting/01_hello_report` | yes | yes | 0 | 0.13s | `01_hello.lrpt` 510 B<br>`01_hello.pdf` 9,178 B | **PASS** |
| 44 | `reporting/02_license_and_errors` | yes | yes | 0 | 0.18s | `02_bad.lrpt` 31 B<br>`02_good.lrpt` 379 B<br>`02_out.pdf` 6,498 B | **PASS** |
| 45 | `reporting/03_export_targets` | yes | yes | 0 | 0.93s | `03_data.csv` 63 B<br>`03_out.bmp` 2,677,286 B<br>`03_out.csv` 54 B<br>`03_out.html` 1,909 B<br>`03_out.json` 128 B<br>`03_out.pdf` 9,007 B<br>`03_out.png` 10,670 B<br>`03_out.svg` 665 B<br>`03_out.txt` 495 B<br>`03_out.xlsx` 2,749 B<br>`03_out.xml` 185 B<br>`03_report.lrpt` 823 B | **PASS** |
| 46 | `reporting/04_bands` | yes | yes | 0 | 0.25s | `04_data.csv` 1,993 B<br>`04_out.pdf` 27,273 B<br>`04_report.lrpt` 2,221 B | **PASS** |
| 47 | `reporting/05_elements` | yes | yes | 0 | 0.18s | `05_elements.lrpt` 1,851 B<br>`05_elements.pdf` 16,047 B<br>`05_img.bmp` 246 B<br>`05_sub.lrpt` 350 B | **PASS** |
| 48 | `reporting/06_data_csv` | yes | yes | 0 | 0.14s | `06_data.csv` 150 B<br>`06_data.lrpt` 1,370 B<br>`06_data.pdf` 11,662 B<br>`06_data.txt` 879 B<br>`06_data_out.csv` 142 B | **PASS** |
| 49 | `reporting/07_data_json_xml` | yes | yes | 0 | 0.25s | `07_data.json` 126 B<br>`07_data.xml` 193 B<br>`07_json.lrpt` 823 B<br>`07_json.pdf` 8,791 B<br>`07_json.txt` 424 B<br>`07_xml.lrpt` 827 B<br>`07_xml.pdf` 9,607 B<br>`07_xml.txt` 424 B | **PASS** |
| 50 | `reporting/08_custom_provider` | yes | yes | 0 | 0.18s | `08_custom.lrpt` 1,616 B<br>`08_custom.pdf` 17,288 B<br>`08_custom.txt` 585 B | **PASS** |
| 51 | `reporting/09_expressions` | yes | yes | 0 | 0.13s | `09_expr.lrpt` 5,445 B<br>`09_expr.pdf` 14,524 B<br>`09_expr.txt` 938 B | **PASS** |
| 52 | `reporting/10_aggregates_groups` | yes | yes | 0 | 0.18s | `10_data.csv` 140 B<br>`10_groups.lrpt` 1,553 B<br>`10_groups.pdf` 21,156 B<br>`10_groups.txt` 1,346 B | **PASS** |
| 53 | `reporting/11_parameters` | yes | yes | 0 | 0.14s | `11_parameters.lrpt` 761 B<br>`11_run1.pdf` 9,576 B<br>`11_run1.txt` 267 B<br>`11_run2.pdf` 8,739 B<br>`11_run2.txt` 267 B | **PASS** |
| 54 | `reporting/12_custom_function` | yes | yes | 0 | 0.22s | `12_custom_function.lrpt` 465 B<br>`12_custom_function.pdf` 7,737 B<br>`12_custom_function.txt` 194 B | **PASS** |
| 55 | `reporting/13_plugin` | yes | yes | 0 | 0.13s | `13_custom.out` 77 B<br>`13_plugin.lrpt` 493 B<br>`13_plugin.pdf` 6,782 B<br>`13_plugin.txt` 200 B | **PASS** |
| 56 | `reporting/14_open_mem_and_print` | yes | yes | 0 | 0.51s | `14_open_mem.pdf` 10,187 B | **PASS** |
| 57 | `reporting/15_tags_and_formatting` | yes | yes | 0 | 0.18s | `15_data.csv` 33 B<br>`15_tags.pdf` 13,632 B<br>`15_tags.txt` 803 B | **PASS** |
| 58 | `reporting/17_invoice_lines` | yes | yes | 0 | 0.24s | `17_invoice.csv` 195 B<br>`17_invoice.html` 9,944 B<br>`17_invoice.lrpt` 4,258 B<br>`17_invoice.pdf` 24,307 B<br>`17_invoice.svg` 5,096 B<br>`17_invoice.txt` 1,746 B<br>`17_invoice.xls` 3,072 B<br>`17_invoice.xlsx` 3,256 B<br>`17_items.csv` 140 B | **PASS** |
| 59 | `reporting/18_invoice_pro` | yes | yes | 0 | 0.17s | `18_invoice.csv` 250 B<br>`18_invoice.html` 15,478 B<br>`18_invoice.lrpt` 7,479 B<br>`18_invoice.pdf` 26,613 B<br>`18_invoice.svg` 7,711 B<br>`18_invoice.txt` 2,302 B<br>`18_invoice.xls` 3,072 B<br>`18_invoice.xlsx` 3,446 B<br>`18_items.csv` 208 B | **PASS** |
| 60 | `signature_ap/signature_ap` | yes | yes | 0 | 0.13s | `out.pdf` 43,610 B | **PASS** |
| 61 | `signed_pdfa/signed_pdfa` | yes | yes | 0 | 0.12s | `out.pdf` 45,718 B | **PASS** |
| 62 | `smoke_test/smoke_test` | yes | yes | 0 | 0.07s | `smoke_out.pdf` 8,273 B | **PASS** |
| 63 | `split_pdf/split_pdf` | yes | yes | 0 | 0.18s | `out/page0001.pdf` 92,460 B<br>`out/page0002.pdf` 105,673 B<br>`out/page0003.pdf` 106,582 B<br>`out/page0004.pdf` 101,627 B | **PASS** |
| 64 | `tables/images/table_images` | yes | yes | 0 | 3.24s | `out.pdf` 1,513,574 B | **PASS** |
| 65 | `tables/templates/table_templates` | yes | yes | 0 | 4.55s | `out.pdf` 4,761,331 B | **PASS** |
| 66 | `tables/text/table_text` | yes | yes | 0 | 0.08s | `out.pdf` 9,107 B | **PASS** |
| 67 | `text_extraction/text_extraction` | yes | yes | 0 | 10.97s | `out.txt` 7,756,650 B | **FAIL** |
| 68 | `text_extraction3/text_extraction3` | yes | yes | 0 | 5.95s | `out.txt` 11,288,214 B | **FAIL** |
| 69 | `text_formatting/text_formatting` | yes | yes | 0 | 0.27s | `out.pdf` 380,757 B | **PASS** |
| 70 | `transparency/alpha_transparency/alpha_transparency` | yes | yes | 0 | 0.12s | `out.pdf` 22,235 B | **PASS** |
| 71 | `transparency/softmask/softmask` | yes | yes | 0 | 0.13s | `out.pdf` 161,445 B | **PASS** |
| 72 | `xfa/01_basic_positioned_form/01_basic_positioned_form` | yes | yes | 0 | 0.04s | `output.pdf` 5,504 B | **PASS** |
| 73 | `xfa/02_data_binding/02_data_binding` | yes | yes | 0 | 0.04s | `02_data_binding.render.pdf` 6,342 B | **PASS** |
| 74 | `xfa/03_formcalc_calculations/03_formcalc_calculations` | yes | yes | 0 | 0.08s | `03_formcalc_calculations.render.pdf` 11,111 B | **PASS** |
| 75 | `xfa/04_flow_layout/04_flow_layout` | yes | yes | 0 | 0.08s | `04_flow_layout.pdf` 4,482 B | **PASS** |
| 76 | `xfa/05_occur_repeating_rows/05_occur_repeating_rows` | yes | yes | 0 | 0.07s | `05_occur_repeating_rows.pdf` 4,404 B | **PASS** |
| 77 | `xfa/06_pagination_multipage/06_pagination_multipage` | yes | yes | 0 | 0.13s | `06_pagination_multipage.pdf` 13,796 B | **PASS** |
| 78 | `xfa/07_table_layout/07_table_layout` | yes | yes | 0 | 0.08s | `07_table_layout.pdf` 6,167 B | **PASS** |
| 79 | `xfa/08_picture_clause_formatting/08_picture_clause_formatting` | yes | yes | 0 | 0.08s | `08_picture_clause_formatting.pdf` 4,589 B | **PASS** |
| 80 | `xfa/09_acroform_widget_synthesis/09_acroform_widget_synthesis` | yes | yes | 0 | 0.13s | `mode0.pdf` 5,844 B<br>`mode1.pdf` 13,370 B | **PASS** |
| 81 | `xfa/10_javascript_scripting/10_javascript_scripting` | yes | yes | 0 | 0.13s | `output.pdf` 4,888 B | **PASS** |
| 82 | `zugferd_facturx_xrechnung/attach_invoice/attach_invoice` | yes | yes | 0 | 0.23s | `out.pdf.` 32,002 B | **PASS** |
| 83 | `zugferd_facturx_xrechnung/attach_invoice_and_conv_to_zugferd/conv_to_zugferd` | yes | yes | 0 | 0.18s | `out.pdf` 32,004 B | **PASS** |
| 84 | `zugferd_facturx_xrechnung/extract_invoice/extract_invoice` | yes | yes | 0 | 0.18s | `out.pdf.` 32,127 B | **FAIL** |

## Tally

```
compiled            84 / 84
ran                 84 / 84
exit 0              84 / 84
timed out            0 / 84
output verified     77 / 84
```

Failures by class: **6 example bugs** (all Linux-only `wchar_t`/`LWCHAR` width
confusion, in 6 files), **1 pre-existing engine gap** that fails identically on
Windows. **0 missing fixtures. 0 platform-inapplicable examples. 0 Linux-only
engine bugs.**

Per-example detail, including the exact assertion that fired, is in
`_run_results.log`.

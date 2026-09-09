# examples/cpp_linux on **real macOS** -- build, run and output verification

**This tree had never been built or run on macOS before this session.** It is
named `cpp_linux`, but the sources are POSIX + a hand-rolled `apputil.h` shim,
so whether they are actually portable was an open question. They are -- with
two small edits, both listed below, both no-ops on Linux.

## What was run

| | |
|---|---|
| host | macOS 13.7.8 (22H730), x86_64, VMware Workstation guest, 4 cores |
| toolchain | Apple clang 14.0.3 (Command Line Tools 15.2 only -- **no full Xcode needed**) |
| cmake / ninja | 4.4.1 / 1.13.2 (not on PATH; `~/tools/...`) |
| engine commit | `e82fe0d28e7195e4c397d872e9a7cb31ab2c1982` ("gate: a lock ...") |
| engine build | `cmake --preset macos-x64` -> configure rc=0, build rc=0, 366/366 targets |
| engine artefact | `cpp/build/cmake_macos_x64/LumasPdf.dylib`, 12,034,952 B, Mach-O 64-bit x86_64, install name `@rpath/LumasPdf.dylib` |
| ABI | **1630 exported / 0 missing / 0 extra -- GREEN**, diffed BOTH directions against `cpp/exports/LumasPdf.exported_symbols` |
| examples | 84/84 compiled, 84/84 ran, 84/84 exited 0 |
| verification | pypdf 6.7.0 on the Windows host, over the outputs pulled back from the Mac |
| Linux side | available -- the concurrent Linux x64 run's own outputs, byte-compared file by file |

### ABI verification (why not `cpp/tools/abi_gate.py`)

`abi_gate.py` is pefile-only and hardcodes an `E:\` root, so it can neither open
a Mach-O nor find the tree on a Mac. Instead `nm -gU --defined-only` on the
dylib was diffed against the frozen `cpp/exports/LumasPdf.exported_symbols`
**in both directions**:

```
frozen exported_symbols entries : 1630
dylib exported symbols (nm -gU) : 1630
MISSING (in frozen list, not exported by dylib): 0
EXTRA   (exported by dylib, not in frozen list): 0
_pdfNewPDF present   _vwrShowFileW present   _pdfGetErrorMessage present
_fntGetFont present  _gpcNewGPC present      (39 rpt* + 112 ras* exports present)
RESULT: GREEN -- 1630 exported, 0 missing, 0 extra
```

## The two portability edits (both work on Linux *and* macOS)

### 1. `apputil.h` -- `ChdirToExe()` did nothing at all on macOS

The non-Windows branch resolved `readlink("/proc/self/exe")`. **Darwin has no
`/proc`**, so `readlink` returned -1 and the function silently returned without
chdir'ing. 35 of the 84 examples call `ChdirToExe()`; every one of them would
have written its output into whatever directory the shell happened to be in and
failed to find its sibling fixtures. Fixed with the documented libSystem
equivalent, under `#ifdef __APPLE__`, leaving the Linux path byte-for-byte
unchanged:

```c
#ifdef __APPLE__
#include <mach-o/dyld.h>
#include <cstdint>
#endif
...
    char b[PATH_MAX];
#ifdef __APPLE__
    uint32_t sz = (uint32_t)sizeof(b);
    if (_NSGetExecutablePath(b, &sz) != 0) return;
#else
    ssize_t n = readlink("/proc/self/exe", b, sizeof(b) - 1);
    if (n <= 0) return;
    b[n] = 0;
#endif
```

### 2. `build_all.sh` -- `-Wl,-rpath` (required on macOS, tidier on Linux)

`cpp/CMakeLists.txt` gives the dylib the install name `@rpath/LumasPdf.dylib`
(`MACOSX_RPATH` + `INSTALL_NAME_DIR "@rpath"`, confirmed by `otool -D`). A
client with no `LC_RPATH` **cannot** resolve `@rpath`, so it fails at load with
`Library not loaded: @rpath/LumasPdf.dylib` no matter what `DYLD_LIBRARY_PATH`
says. One flag fixes it on both platforms, and on Linux it removes the need to
export `LD_LIBRARY_PATH` at all:

```diff
-  if g++ -std=c++17 -O2 \
+  if "$CXX" -std=c++17 -O2 \
          -DLUMAS_REPO_ROOT="\"$FIXTURES\"" \
          -I "$HERE" -I "$HERE/include" \
          "$src" -o "$bin" "$SO" \
+        -Wl,-rpath,"$SODIR" \
```
plus `SODIR=$(cd "$(dirname "$SO")" && pwd)`, `CXX="${CXX:-g++}"` (macOS `g++`
is a CLT clang driver shim and accepts every flag used), and the `.so`-vs-`.dylib`
/ `LD_`-vs-`DYLD_` wording in the header and closing hint. **The tree was not
renamed and no per-platform fork was introduced.**

Result: `84 built, 0 failed` on the first attempt after these two edits. No
source file of any example needed changing.

### One environment shim, not a code change

Eight examples reach *outside* the self-contained package with bare relative
paths that escape it (`../../test_files/plain.pdf`,
`../../../../dynapdf_help.pdf`, ...). On Windows/Linux those happen to resolve
because the package sits inside the full SDK tree. On the Mac the package was
therefore unpacked at `~/ex84/LUMASPDFSDK/examples/cpp_linux` with
`examples/test_files` symlinked to `fixtures/examples/test_files` and
`dynapdf_help.pdf` / `license.pdf` copied to the SDK root -- all byte-identical
to the SDK originals (md5 verified), so the run is directly comparable with the
Linux one. This is a **packaging defect in the examples**, not a macOS problem:
that package claims to be self-contained and is not.

## Results: 74 / 84 verified

| tally | |
|---|---|
| compiled | **84 / 84** |
| ran | **84 / 84** |
| exit code 0 | **84 / 84** (0 timeouts) |
| outputs verified | **74 / 84** |
| failed verification | **10** |
| vs Linux: byte-identical | 67 output files |
| vs Linux: differ only in `/ID` (+`/CreationDate`) | 75 output files |
| vs Linux: differ in real content | 7 output files: **6 explained legitimate** (2 timestamp, 1 directory order, 3 read-past-buffer) + **1 genuine engine defect** |

**Verification is on outputs, not exit codes.** Every one of the 84 examples
exits 0. Three of them exit 0 having written nothing at all.

## Per-example results

`verified` = the output parses, has >= 1 page, and contains the feature the
example exists for (`/AcroForm` fields for acroform, `/Outlines` for bookmarks,
`/Annots` for annotations, an `/FT /Sig` field for signing, `/EmbeddedFiles` for
ZUGFeRD/collections, `/OCProperties` for layers, `/ExtGState` alpha for
transparency, vector module rects for barcodes, magic bytes for TIFF/BMP/PNG,
OLE2 magic for `.xls`, a real zip for `.xlsx`).

| # | example | compiled | ran | exit | s | outputs | verified | vs Linux |
|--:|---|:--:|:--:|--:|--:|---|:--:|---|
| 1 | `acroform/check_boxes/check_boxes` | yes | yes | 0 | 1.70 | `out.pdf` 13,689 | yes | /ID only |
| 2 | `acroform/field_groups/field_groups` | yes | yes | 0 | 1.82 | `out.pdf` 3,634 | yes | /ID only |
| 3 | `acroform/form_fields/form_fields` | yes | yes | 0 | 1.93 | `out.pdf` 14,360 | yes | /ID only |
| 4 | `annotations/annotation_replies/annotation_replies` | yes | yes | 0 | 1.73 | `out.pdf` 732 | yes | /ID only |
| 5 | `annotations/annotation_types/annotation_types` | yes | yes | 0 | 2.06 | `out.pdf` 18,573 | yes | /ID only |
| 6 | `annotations/highlight_annotations/highlight_annotations` | yes | yes | 0 | 2.54 | `out.pdf` 1,103 | yes | /ID only |
| 7 | `annotations/measure_lines/measure_lines` | yes | yes | 0 | 2.83 | `out.pdf` 1,004 | yes | /ID only |
| 8 | `annotations/migration_states/migration_states` | yes | yes | 0 | 2.66 | `out.pdf` 769 | yes | /ID only |
| 9 | `annotations/quad_points/quad_points` | yes | yes | 0 | 2.75 | `out.pdf` 1,478 | yes | /ID only |
| 10 | `annotations/stamps/stamps` | yes | yes | 0 | 2.52 | `out.pdf` 3,743 | yes | /ID only |
| 11 | `barcodes/barcodes` | yes | yes | 0 | 2.76 | `out.pdf` 77,500 | yes | /ID only |
| 12 | `bookmarks/bookmarks` | yes | yes | 0 | 1.76 | `out.pdf.` 2,908 | yes | /ID only |
| 13 | `collections/collections` | yes | yes | 0 | 2.66 | `out.pdf` 170,079 | yes | /ID only |
| 14 | `collections2/collections2` | yes | yes | 0 | 2.02 | `out.pdf` 170,203 | yes | /ID only |
| 15 | `complex_text/alternate_font_lists/alternate_fonts` | yes | yes | 0 | 1.69 | `out.pdf` 4,316 | **NO** | /ID only |
| 16 | `complex_text/complex_text/complex_text` | yes | yes | 0 | 1.49 | `out.pdf` 4,316 | **NO** | /ID only |
| 17 | `complex_text/font_substitution/font_substitution` | yes | yes | 0 | 1.47 | `out.pdf` 4,316 | **NO** | /ID only |
| 18 | `content_parser/image_extraction/image_extraction` | yes | yes | 0 | 14.19 | `out.tif` 1,033,889 | yes | identical |
| 19 | `content_parser/text_coordinates/text_coordinates` | yes | yes | 0 | 35.58 | `out.pdf` 19,894,267 | yes | /ID only |
| 20 | `content_parser/text_extraction2/text_extraction2` | yes | yes | 0 | 15.41 | `out.txt` 7,756,646 | **NO** | differs - uninit heap |
| 21 | `content_parser/text_search/text_search` | yes | yes | 0 | 21.08 | `out.pdf` 8,176,040 | yes | /ID only |
| 22 | `convert_conformance/convert_conformance` | yes | yes | 0 | 1.90 | `out_pdfa.pdf` 12,327<br>`out_pdfx.pdf` 798,748 | yes | /ID only |
| 23 | `edit_page/edit_page` | yes | yes | 0 | 2.19 | `out.pdf` 2,911 | yes | /ID only |
| 24 | `edit_text/edit_text` | yes | yes | 0 | 14.55 | `out.pdf` 8,017,224 | yes | /ID only |
| 25 | `hello_world/hello_world` | yes | yes | 0 | 0.09 | `out.pdf` 8,265 | yes | differs - timestamp |
| 26 | `incremental_updates/comments/comments` | yes | yes | 0 | 1.31 | `out.pdf` 823 | yes | /ID only |
| 27 | `incremental_updates/multiple_signatures/multiple_signatures` | yes | yes | 0 | 2.67 | **none** | **NO** | n/a |
| 28 | `layers/layer_tree/layer_tree` | yes | yes | 0 | 2.11 | `out.pdf` 137,245 | yes | /ID only |
| 29 | `layers/layers/layers` | yes | yes | 0 | 2.91 | `out.pdf` 137,217 | yes | /ID only |
| 30 | `merge_pdf/merge_pdf` | yes | yes | 0 | 12.42 | `out.pdf` 8,135,214 | yes | /ID only |
| 31 | `metafiles/metafiles` | yes | yes | 0 | 2.19 | `out.pdf` 57,203 | yes | /ID only |
| 32 | `metafiles_gui/metafiles_gui` | yes | yes | 0 | 2.83 | `out.pdf` 129,490 | yes | /ID only |
| 33 | `optimize/optimize` | yes | yes | 0 | 12.33 | `out.pdf` 8,017,215 | yes | /ID only |
| 34 | `pdf_to_text/pdf_to_text` | yes | yes | 0 | 8.21 | `out.txt` 2,505,678 | yes | identical |
| 35 | `pdfa_extension/checkconformance/checkconformance` | yes | yes | 0 | 11.32 | `out.pdf` 9,820,359 | yes | /ID only |
| 36 | `pdfviewer/pdfviewer` | yes | yes | 0 | 4.64 | `_viewer_shot.png` 74,073 B (1000x820) | yes | n/a |
| 37 | `personalize/personalize` | yes | yes | 0 | 2.19 | `out.pdf` 20,616 | yes | differs - timestamp |
| 38 | `probe_test/probe_test` | yes | yes | 0 | 2.59 | `probe_out.pdf` 5,398 | yes | /ID only |
| 39 | `rendering_engine/render_page/render_page` | yes | yes | 0 | 3.68 | `render_page.tif` 65,973 | yes | identical |
| 40 | `rendering_engine/render_page_ex/render_page_ex` | yes | yes | 0 | 3.50 | `render_page_ex.tif` 65,973 | yes | identical |
| 41 | `rendering_engine/render_page_to_image/render_page_to_image` | yes | yes | 0 | 3.24 | `out.tif` 65,973 | yes | identical |
| 42 | `repair/repair` | yes | yes | 0 | 1.52 | `repaired.pdf` 8,377 | yes | /ID only |
| 43 | `reporting/01_hello_report` | yes | yes | 0 | 2.54 | `01_hello.lrpt` 510<br>`01_hello.pdf` 9,178 | yes | /ID only |
| 44 | `reporting/02_license_and_errors` | yes | yes | 0 | 2.37 | `02_bad.lrpt` 31<br>`02_good.lrpt` 379<br>`02_out.pdf` 6,498 | yes | /ID only |
| 45 | `reporting/03_export_targets` | yes | yes | 0 | 2.92 | `03_data.csv` 63<br>`03_out.bmp` 2,677,286<br>`03_out.csv` 54<br>+9 more | yes | /ID only |
| 46 | `reporting/04_bands` | yes | yes | 0 | 2.42 | `04_data.csv` 1,993<br>`04_out.pdf` 27,273<br>`04_report.lrpt` 2,221 | yes | /ID only |
| 47 | `reporting/05_elements` | yes | yes | 0 | 2.74 | `05_elements.lrpt` 1,851<br>`05_elements.pdf` 16,047<br>`05_img.bmp` 246<br>+1 more | yes | /ID only |
| 48 | `reporting/06_data_csv` | yes | yes | 0 | 2.75 | `06_data.csv` 150<br>`06_data.lrpt` 1,370<br>`06_data.pdf` 11,662<br>+2 more | yes | /ID only |
| 49 | `reporting/07_data_json_xml` | yes | yes | 0 | 2.42 | `07_data.json` 126<br>`07_data.xml` 193<br>`07_json.lrpt` 823<br>+5 more | yes | /ID only |
| 50 | `reporting/08_custom_provider` | yes | yes | 0 | 2.17 | `08_custom.lrpt` 1,616<br>`08_custom.pdf` 17,288<br>`08_custom.txt` 585 | yes | /ID only |
| 51 | `reporting/09_expressions` | yes | yes | 0 | 2.32 | `09_expr.lrpt` 5,445<br>`09_expr.pdf` 14,524<br>`09_expr.txt` 938 | yes | /ID only |
| 52 | `reporting/10_aggregates_groups` | yes | yes | 0 | 2.27 | `10_data.csv` 140<br>`10_groups.lrpt` 1,553<br>`10_groups.pdf` 21,156<br>+1 more | yes | /ID only |
| 53 | `reporting/11_parameters` | yes | yes | 0 | 2.12 | `11_parameters.lrpt` 761<br>`11_run1.pdf` 9,576<br>`11_run1.txt` 267<br>+2 more | yes | /ID only |
| 54 | `reporting/12_custom_function` | yes | yes | 0 | 1.77 | `12_custom_function.lrpt` 465<br>`12_custom_function.pdf` 7,737<br>`12_custom_function.txt` 194 | yes | /ID only |
| 55 | `reporting/13_plugin` | yes | yes | 0 | 2.01 | `13_custom.out` 77<br>`13_plugin.lrpt` 493<br>`13_plugin.pdf` 6,782<br>+1 more | yes | /ID only |
| 56 | `reporting/14_open_mem_and_print` | yes | yes | 0 | 2.54 | `14_open_mem.pdf` 10,187 | yes | /ID only |
| 57 | `reporting/15_tags_and_formatting` | yes | yes | 0 | 1.50 | `15_data.csv` 33<br>`15_tags.pdf` 13,632<br>`15_tags.txt` 803 | yes | /ID only |
| 58 | `reporting/17_invoice_lines` | yes | yes | 0 | 2.18 | `17_invoice.csv` 195<br>`17_invoice.html` 9,944<br>`17_invoice.lrpt` 4,258<br>+6 more | yes | /ID only |
| 59 | `reporting/18_invoice_pro` | yes | yes | 0 | 2.35 | `18_invoice.csv` 250<br>`18_invoice.html` 15,478<br>`18_invoice.lrpt` 7,479<br>+6 more | yes | **differs - iconv** |
| 60 | `signature_ap/signature_ap` | yes | yes | 0 | 2.74 | **none** | **NO** | n/a |
| 61 | `signed_pdfa/signed_pdfa` | yes | yes | 0 | 2.34 | **none** | **NO** | n/a |
| 62 | `smoke_test/smoke_test` | yes | yes | 0 | 2.62 | `smoke_out.pdf` 8,273 | yes | /ID only |
| 63 | `split_pdf/split_pdf` | yes | yes | 0 | 2.42 | `page0001.pdf` 92,460<br>`page0002.pdf` 105,673<br>`page0003.pdf` 106,582<br>+1 more | yes | /ID only |
| 64 | `tables/images/table_images` | yes | yes | 0 | 6.65 | `out.pdf` 1,513,587 | yes | differs - dir order |
| 65 | `tables/templates/table_templates` | yes | yes | 0 | 2.75 | `out.pdf` 4,761,331 | yes | /ID only |
| 66 | `tables/text/table_text` | yes | yes | 0 | 0.88 | `out.pdf` 9,107 | yes | /ID only |
| 67 | `text_extraction/text_extraction` | yes | yes | 0 | 12.80 | `out.txt` 7,756,650 | **NO** | differs - uninit heap |
| 68 | `text_extraction3/text_extraction3` | yes | yes | 0 | 7.31 | `out.txt` 11,288,214 | **NO** | differs - uninit heap |
| 69 | `text_formatting/text_formatting` | yes | yes | 0 | 2.77 | `out.pdf` 380,757 | yes | /ID only |
| 70 | `transparency/alpha_transparency/alpha_transparency` | yes | yes | 0 | 1.85 | `out.pdf` 22,235 | yes | /ID only |
| 71 | `transparency/softmask/softmask` | yes | yes | 0 | 1.94 | `out.pdf` 161,445 | yes | /ID only |
| 72 | `xfa/01_basic_positioned_form/01_basic_positioned_form` | yes | yes | 0 | 2.01 | `output.pdf` 5,504 | yes | /ID only |
| 73 | `xfa/02_data_binding/02_data_binding` | yes | yes | 0 | 2.39 | `02_data_binding.render.pdf` 6,342 | yes | /ID only |
| 74 | `xfa/03_formcalc_calculations/03_formcalc_calculations` | yes | yes | 0 | 2.29 | `03_formcalc_calculations.render.pdf` 11,111 | yes | /ID only |
| 75 | `xfa/04_flow_layout/04_flow_layout` | yes | yes | 0 | 1.86 | `04_flow_layout.pdf` 4,482 | yes | /ID only |
| 76 | `xfa/05_occur_repeating_rows/05_occur_repeating_rows` | yes | yes | 0 | 1.56 | `05_occur_repeating_rows.pdf` 4,404 | yes | /ID only |
| 77 | `xfa/06_pagination_multipage/06_pagination_multipage` | yes | yes | 0 | 1.70 | `06_pagination_multipage.pdf` 13,796 | yes | /ID only |
| 78 | `xfa/07_table_layout/07_table_layout` | yes | yes | 0 | 2.04 | `07_table_layout.pdf` 6,167 | yes | /ID only |
| 79 | `xfa/08_picture_clause_formatting/08_picture_clause_formatting` | yes | yes | 0 | 1.57 | `08_picture_clause_formatting.pdf` 4,589 | yes | /ID only |
| 80 | `xfa/09_acroform_widget_synthesis/09_acroform_widget_synthesis` | yes | yes | 0 | 1.56 | `mode0.pdf` 5,844<br>`mode1.pdf` 13,370 | yes | /ID only |
| 81 | `xfa/10_javascript_scripting/10_javascript_scripting` | yes | yes | 0 | 1.95 | `output.pdf` 4,888 | yes | /ID only |
| 82 | `zugferd_facturx_xrechnung/attach_invoice/attach_invoice` | yes | yes | 0 | 1.71 | `out.pdf.` 32,002 | yes | /ID only |
| 83 | `zugferd_facturx_xrechnung/attach_invoice_and_conv_to_zugferd/conv_to_zugferd` | yes | yes | 0 | 1.65 | `out.pdf` 32,004 | yes | /ID only |
| 84 | `zugferd_facturx_xrechnung/extract_invoice/extract_invoice` | yes | yes | 0 | 2.12 | `out.pdf.` 32,127 | **NO** | /ID only |

## The 10 verification failures

Every one exits 0. None is a compile or a crash.

### (b) EXAMPLE BUG -- 4 x `wchar_t*` cast onto a 2-byte `LWCHAR*` parameter

Identical on Linux (the concurrent run failed the same four), and by
construction impossible on Windows, where `wchar_t` *is* 2 bytes. Nothing to do
with macOS.

| example | what the output shows |
|---|---|
| `complex_text/complex_text` | `out.pdf` draws **1** glyph code total (`.notdef`): `pdfWriteFTextExW` is handed a 4-byte `wchar_t` buffer, so the string terminates after one UTF-16 code unit |
| `complex_text/alternate_font_lists` | same cast, twice (the text *and* the alternate font-name array) |
| `complex_text/font_substitution` | same cast |
| `text_extraction`, `text_extraction3`, `content_parser/text_extraction2` | `out.txt` carries a UTF-16LE BOM but will not decode as UTF-16LE (`illegal UTF-16 surrogate`); 36% of `text_extraction/out.txt` decodes to NUL. `fwrite(ptr, sizeof(wchar_t), n)` writes the engine's 2-byte buffer at 4-byte stride, so half of every record is read from **past the end of the buffer** |

(That is 6 rows, 4 distinct bugs.)

### (b) EXAMPLE BUG -- `extract_invoice` self-reports failure

`zugferd_facturx_xrechnung/extract_invoice` prints `XML Invoice not found!` and
returns 0. Its `out.pdf.` is fine (2 pages, `/EmbeddedFiles ['factur-x.xml']`,
`/AF` present) -- what fails is the example's own round-trip check:
`GetPDFVersionEx` after `ImportPDFFile` reports `PDFAVersion != 3` /
`FXDocName == 0`, so the engine withholds the PDF/A-3 + Factur-X claim it just
wrote. **Not macOS-specific**: the Linux run reached the identical verdict and
recorded the output as byte-size-identical to the checked-in Windows/Delphi
artefact (32,127 B). Engine gap, platform-independent.

### (d) PLATFORM-INAPPLICABLE AS CONFIGURED -- 3 x signing produces no file

`signature_ap`, `signed_pdfa` and `incremental_updates/multiple_signatures` all
exit 0, print **nothing**, and write **no file**. All three end in
`pdfCloseAndSignFile(...)`, and two of them contain the literal
`if (pdfOpenOutputFileA(...) == 0) { pdfDeletePDF(pdf); return 0; }` -- a
failure path that returns success. Root cause is not a macOS defect and is
documented in the engine source, `cpp/src/pdf/signbarcode_exports.cpp:107-131`:

* the `apple-base` preset sets `LUMAS_VENDOR_THIRDPARTY=ON`, so the macOS build
  compiles vendored **mbedTLS** and defines `LUMAS_CRYPTO_MBEDTLS` (confirmed
  present in the Mac's `compile_commands.json`);
* mbedTLS 3.6 has no PKCS#7 *signing* entry point, no PKCS#12 parser and no
  RC2, which `test_cert.pfx` needs, so that branch deliberately takes the
  honest-failure path: `SignPfxDetachedCms` returns `""`;
* `linux-base` sets `LUMAS_VENDOR_THIRDPARTY=OFF` and links **system OpenSSL**,
  which is why the concurrent Linux run signed all three successfully
  (`signature_ap/out.pdf` 43,610 B, `signed_pdfa/out.pdf` 45,718 B,
  `multiple_signatures/out.pdf` 194,537 B).

So this is a *configuration* gap, and a real one: **the shipped `macos-x64`
preset cannot sign a PDF.** It is fixable without touching any of these
examples -- `brew install openssl@3 freetype pkg-config` and configure with
`-DLUMAS_VENDOR_THIRDPARTY=OFF` selects the OpenSSL backend that Linux uses.
That was **not** possible to demonstrate on this machine: it has no Homebrew and
macOS ships no OpenSSL headers (`/usr/local/opt/openssl*`, `/opt/homebrew/opt/openssl*`
and `/usr/local/include/openssl` all absent), so there is nothing to link
against. Marked (d) rather than (a) because the source states the trade-off
explicitly and the Linux configuration proves the code path is correct.

## macOS vs Linux, file by file

Both runs used the same commit, the same fixtures and the same
`LUMAS_LINUX_FAKE_SCREEN_WIDTH_PX 1920` constant, so deterministic generation
*should* match byte for byte. Of the 149 output files:

* **67 byte-identical.** Including every raster output (`render_page.tif`,
  `render_page_ex.tif`, `render_page_to_image/out.tif` -- 65,973 B each --
  and `image_extraction/out.tif`, 1,033,889 B), `pdf_to_text/out.txt`
  (2,505,678 B), and all of `18_invoice`'s non-PDF exports
  (`.txt/.html/.svg/.csv/.xls/.xlsx/.lrpt`). That the TIFFs match matters:
  it is the same FreeType raster path that commit 51c3269 changed today.
* **75 differ ONLY inside `/ID`** (and, in the 3 ZUGFeRD + 2 collections files,
  also inside `/CreationDate`/`/ModDate`). Every differing byte run in those 75
  files falls inside a `/ID [<..><..>]` or `/(CreationDate|ModDate) (...)`
  span -- 0 runs classified as anything else, sizes identical to the byte.
  Legitimate.
* **7 differ in real content.** Named individually below.

### 1-2. `hello_world/out.pdf`, `personalize/out.pdf` -- the example stamps the clock (legitimate)

Both call `strftime` on `localtime(time(NULL))` and draw the result on the page.
`personalize` obj 8 content stream, decompressed, differs in exactly one place:

```
- (30.07.2026 09:28:06) Tj      <- Linux run, 09:28
+ (30.07.2026 15:22:58) Tj      <- macOS run, 15:22
```

`hello_world` is the same cause with a knock-on: different digits mean a
different **glyph subset**, so obj 8 (`FontFile2`) is 8,524 B on macOS vs
8,428 B on Linux, `/Length1` differs, obj 9's ToUnicode CMap has 24
`beginbfchar` vs 23 (macOS additionally maps `<0014> <0031>` = '1' and
`<0018> <0035>` = '5'; Linux maps `<001C> <0039>` = '9'), and the file is
8,265 vs 8,191 B. Entirely downstream of the timestamp.

### 3. `tables/images/out.pdf` -- unsorted `directory_iterator` (legitimate; example bug)

`table_images.cpp:41` iterates `fs::directory_iterator("../../../test_files/images/")`
and **never sorts**. Directory order is filesystem-defined, so APFS hands the 37
JPEGs over in a different order than the Linux container's filesystem. macOS's
`/Im1` is byte-for-byte Linux's `/Im4`. Because each image is scaled to its
table cell, a different order changes the cell heights, which changes the
`re`/`cm` operators and then the downsampled JPEG bytes:

```
- 50 692 125 100 re            /  117 0 0 77.146875 54 703.426563 cm    <- Linux
+ 50 637.75 125 154.25 re      /  117 0 0 77.878125 54 690.560938 cm    <- macOS
```

74 image XObjects and 4 pages on both sides; the XObject *bytes* do not
match one-for-one precisely because the cell each image is scaled into changed. Sorting the vector would
make this deterministic across platforms.

### 4. `reporting/18_invoice.pdf` -- **a real engine defect** (macOS drops a character Windows and Linux replace)

This is the one difference that is nobody's timestamp and nobody's example bug.

`18_invoice.lrpt` is **byte-identical** on both platforms (7,479 B) and contains
5 raw `0xB7` bytes inside XML that declares `encoding="UTF-8"` (VB6 heritage: the
original wrote `ChrW(183)` through the ANSI codepage). `0xB7` is not valid UTF-8,
so `DecodeUtf8Cp` (`cpp/src/pdf/rpt_util.cpp:671`) maps it to U+FFFD on both
platforms -- that function is pure, table-free C++ with no platform branch.

What then happens to U+FFFD is **not** platform-independent. Decoding the page
content stream through the font's own ToUnicode CMap:

```
Linux : '123 Industrial Way  ?  Springfield, IL 62704'
macOS : '123 Industrial Way    Springfield, IL 62704'     <- the character is GONE
```

...and the same in the four other places (`+1 (555) 018-2245  ?  billing@...`,
`ACME Corp ? IBAN GB00 ACME 0000 1042 ? Ref INV-1042.`, `USD ? Total items 6`).
The Linux PDF contains glyph `<0022>` (ToUnicode `U+003F`, '?') 6 times; the
macOS PDF contains it once -- only in the literal `Questions?` that was always
a real question mark. Text advances shift accordingly
(`482.595103 452.629921 Td` vs `487.044322 452.629921 Td`).

Root cause, `cpp/rtl/lumas_ansi_convert.cpp:352`:

```c
std::string toName = CodePageToIconvName(codePage);
if (toName != "UTF-8" && toName != "UTF-16LE") toName += "//TRANSLIT//IGNORE";
```

The comment above it states the intent -- *"`//TRANSLIT//IGNORE` below
approximates Win32's automatic default-char substitution for characters
unrepresentable in the target codepage"*. That approximation holds on glibc,
whose iconv transliterates U+FFFD to `?`. **macOS's libiconv has no
transliteration for U+FFFD, so `//IGNORE` then deletes it.** Same source, same
font (identical subset tags `BHLTQU+LiberationSans-Bold` / `YPDNMF+LiberationSans`
on both sides), different host iconv.

Severity is low -- it only bites characters unrepresentable in the target
codepage, i.e. already-degraded text -- but it is a genuine cross-platform
correctness defect in the Win32 shim, not a legitimate difference, and macOS is
the platform that gets it wrong. Nothing was changed to fix it: this run's brief
was to establish portability, and an engine change here needs the gate (which is
locked by another session).

### 5-7. `text_extraction/out.txt`, `text_extraction3/out.txt`, `content_parser/text_extraction2/out.txt` -- reads past the buffer (legitimate difference, invalid on both)

These are the `sizeof(wchar_t)`-stride examples above. Roughly half of every
record's bytes come from **beyond the end of the engine's buffer**, so the file
content is whatever the allocator left there: 44,050 / 366,903 / 792,759 bytes
differ, and of `text_extraction`'s differing bytes 75.7% are `0x00` on macOS
against live heap debris on Linux (`PareP`, `0> <20AC`, `\xc8+`). Both files are
corrupt and both fail verification identically. **Byte comparison is not
meaningful for these three** -- the differing bytes are undefined behaviour, not
engine output. The leading real text agrees (`%----------------------- Page 1
----------...`); the first divergence is at byte offset 520 / 560 / 290 respectively.

## GUI: the Cocoa viewer

`pdfviewer` calls `vwrShowFileW`, which blocks in an AppKit modal loop. Run over
SSH with `caffeinate -u -t 3` first and `LUMAS_VIEWER_TEST_SCREENSHOT` set (the
same content-view capture hook the VIEWERSMOKE gate rests on -- `screencapture`
cannot capture this VM's window server). It opened, rendered and self-closed in
4.64 s, exit 0, producing a **1000x820 PNG with 1,297 distinct colours** -- real
rendered page content, not a blank window. The Linux GTK viewer's shot from the
concurrent run is also 1000x820 with 1,313 colours. The two PNGs are not
byte-comparable and are not expected to be: different window server, different
toolkit, different font rasteriser at the widget level.

## Notes that are NOT failures

* **`out.pdf.` with a trailing dot.** `bookmarks`, `zugferd/attach_invoice` and
  `zugferd/extract_invoice` contain the literal string `"out.pdf."`. NTFS
  silently strips the trailing dot; POSIX does not, so on macOS *and* Linux the
  file is really named `out.pdf.`. Cosmetic example bug, identical on both.
  (It also hides the file from Windows `open()`/`os.path.exists()` unless the
  path is passed in extended-length form -- the verifier does that.)
* **`reporting/14_open_mem_and_print`** reports
  `rpt error 6002 ... cupsPrintFile failed (no CUPS destination)`. The example
  declares this non-fatal and its PDF export is correct (`14_open_mem.pdf`,
  10,187 B, 1 page). Same on Linux.
* **`convert_conformance/out_pdfa.pdf`** carries the `/OutputIntents` entry but
  no `pdfaid` XMP -- same as the checked-in Windows artefact (both 12,327 B), so
  verification checks the OutputIntent, which is present.
* **`signed_pdfa`** never calls `SetPDFVersion(PDF/A)`, so no `pdfaid` XMP is
  expected on any platform.

## One host-level surprise worth recording

Pulling 74 MB of outputs off the Mac initially ran at **~11 KB/s** while pushing
*to* it ran at 6 MB/s -- a 500x asymmetry, across SFTP, an SSH exec channel and
plain HTTP alike, so protocol-independent. Cause: `net.inet.tcp.tso=1` on the
guest's `en0` (TSO4 is in its `options=424<VLAN_MTU,TSO4,CHANNEL_IO>`); VMware's
NAT mishandles the offloaded segments. `sudo sysctl -w net.inet.tcp.tso=0` took
the same transfer to **19 MB/s**. Runtime-only, not persisted; restored to `1`
afterwards. Recorded because it will bite the next person who tries to get build
artefacts off this VM, and it looks exactly like a hung transfer.

## Reproducing

```sh
# on the Mac
export PATH="$HOME/tools/cmake-4.4.1-macos-universal/CMake.app/Contents/bin:$HOME/tools:$PATH"
cd <repo>/cpp && cmake --preset macos-x64 && cmake --build build/presets/macos-x64 -j4
nm -gU --defined-only build/cmake_macos_x64/LumasPdf.dylib | wc -l     # 1630

cd <repo>/examples/cpp_linux
./build_all.sh <repo>/cpp/build/cmake_macos_x64/LumasPdf.dylib          # 84 built, 0 failed
( cd hello_world && ./hello_world_bin )                                # no DYLD_* needed
```

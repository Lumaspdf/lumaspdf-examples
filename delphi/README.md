# LumasPDF — Mirrored DynaPDF Delphi Examples

This folder mirrors the complete DynaPDF `examples/Delphi` set, running
against **LumasPdf.dll** instead of dynapdf.dll.

## Layout

- `include\LumasPdfApi.pas` — the flat-API Delphi import unit (unit
  `LumasPdfApi`; TPDF class and all flat `pdf*`/`tbl*`/`ras*`/… functions),
  derived from the DynaPDF Delphi import unit with its library binding
  changed to `LumasPdf.dll` (both the static `DYNAPDFLIB` constant and the
  `TPDF.Create` default LibName). Example sources are otherwise untouched;
  every `.dpr` simply points its `LumasPdfApi in '...'` clause here.
- `..\test_files\` — the DynaPDF sample assets referenced by some examples
  (taxform.pdf, ICC profiles, sample.txt, …) at their expected relative
  location.
- `build_examples.bat` — builds every example with dcc32 (x86) and stages a
  hardlinked `x32\LumasPdf.dll` next to each exe (no disk cost).
- `smoke_test.dpr` / `probe_test.dpr` — small console checks proving the
  include unit + DLL binding end-to-end (create → draw → table → save).

## Building

    build_examples.bat

Notes baked into the script:
- dcc32 resolves `in '..'` paths against the CURRENT directory, so each
  project is compiled from inside its own folder.
- `pdf_to_text` and `metafiles_gui` use the ShellCtrls sample control; it is
  precompiled once into `include\dcu\` (from RAD Studio's `source\vcl`).
- After changing the engine, re-run the script: it re-stages the DLL
  hardlinks (a rebuilt `x32\LumasPdf.dll` detaches existing hardlinks).

## Source changes vs the DynaPDF originals

1. `include\LumasPdfApi.pas` (was `dynapdf.pas`): unit renamed to
   `LumasPdfApi`, DLL binding changed to `LumasPdf.dll`.
2. Every `.dpr`/`.pas`: `uses dynapdf` / `dynapdf in '...'` clauses
   rewritten to `LumasPdfApi` pointing at the local
   `include\LumasPdfApi.pas`.
3. `metafiles_gui\UMetafile.pas`: `PAnsiChar(FBuffer)` →
   `PByte(FBuffer)` for SetEnhMetaFileBits/SetWinMetaFileBits (the example
   itself documents this Delphi-version API change; required on current
   RAD Studio).

Everything else — forms, logic, resources — is byte-identical to the
DynaPDF originals.

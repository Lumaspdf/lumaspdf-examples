# Delphi OO examples — port brief (read fully)

Create 75 Delphi CONSOLE examples that use the **OO wrapper** `wrappers\delphi\LumasPdfOO.pas`
(the `TPDF` class + helper classes), NOT the flat pdf* API directly. Output to
`examples\delphi_oo\<same-subpath>\<name>.dpr` (mirror the C tree). The reference for each is the
matching **C example** `examples\c\<same-subpath>\<name>.c` — it has the full flat logic; you convert
`pdfFoo(handle, args)` -> `pdf.Foo(args)` (drop the `pdf` prefix AND the handle first-arg; keep the
`A`/`W` suffix exactly). Reference example already done + verified: `examples\delphi_oo\hello_world`.

## Program shape
```pascal
program <name>;
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf   in '..\..\..\wrappers\delphi\LumasPdf.pas',     // flat externals + ALL enums/consts/records
  LumasPdfOO in '..\..\..\wrappers\delphi\LumasPdfOO.pas';   // TPDF + helper classes
var pdf: TPDF;
begin
  pdf := TPDF.Create;                 // = pdfNewPDF
  try
    pdf.CreateNewPDFA('');
    pdf.Append;
    pdf.SetFontA('Arial', fsItalic, 24, True, cp1252);       // enums from LumasPdf unit
    pdf.WriteFTextA(taCenter, 'Hello');
    pdf.EndPage;
    pdf.OpenOutputFileA(PAnsiChar(AnsiString(ExtractFilePath(ParamStr(0)) + 'out.pdf')));
    pdf.CloseFile;
  finally
    pdf.Free;                         // = pdfDeletePDF
  end;
end.
```
Adjust the `..\..\..\` unit-path depth to reach `wrappers\delphi\` from the example folder
(depth-1 folder e.g. `bookmarks\` -> `..\..\..\`; depth-2 e.g. `acroform\check_boxes\` -> `..\..\..\..\`).

## Translation rules
- Method params are mostly `PAnsiChar`/typed enums/Double/Cardinal. For a **computed** Ansi string pass
  `PAnsiChar(AnsiString(s))`; a plain literal `'text'` binds to `const PAnsiChar` directly.
- Enums/consts (fsItalic, cp1252, taCenter, diCreator, dtFit, fmFill, RPT_EXP_PDF, RPT_FEAT_*, NO_COLOR,
  the barcode `bct*`, colors, etc.) all live in the **LumasPdf** unit — use by name. Records (TPDFRect,
  TCTM, TTextRecordW, TPDFBarcode2, TLineAnnotParms, TOptimizeParams, TRptCValue, TPDFParseInterface, ...)
  also come from LumasPdf.
- Bool args: `True`/`False`. Return checks: methods return the flat value (LongBool/Integer) — e.g.
  `if not pdf.Append then ...`, `if pdf.OpenImportFileA(...) < 0 then ...`.
- **Callbacks are NATIVE in Delphi** (unlike VBScript): keep the C example's callback functions as
  plain Delphi `stdcall` functions and pass their address with `@`:
  - error: `pdf.SetOnErrorProc(nil, @ErrProc)` (ErrProc: `function(Data: Pointer; ErrCode: Integer; const Msg: PAnsiChar; ErrType: Integer): Integer; stdcall`).
  - content parse: build a `TPDFParseInterface`, set the needed fn-ptr fields to `@YourProc`, and call
    `pdf.ParseContent(...)` (or the flat `pdfParseContent`). The OO wrapper also has `TPDFContentParser`.
  - reporting: use the flat rpt* externals (in LumasPdf) OR the `TPDFReport`/`TPDFReportJob` helper
    classes if cleaner. Example 13 is PLUGIN-FREE: register a custom function via `rptRegisterFunction`
    (+ `@PlugDouble`) and a custom exporter via `rptRegisterExporter` (+ `@PlugExport`), NO rptLoadPlugin,
    NO rpt_testplugin.dll — mirror `examples\delphi\reporting\13_plugin.dpr` (already plugin-free) or the
    C 13.
  - tables: use the `TPDFTable` helper class (`tblCreateTable` -> a TPDFTable) or flat `tbl*`.
- Barcodes: set `bcd.StructSize := SizeOf(TPDFBarcode2)` before `InitBarcode2`, like the C example.

## Build + verify
Use the helper `examples\delphi_oo\_build.bat`:  `cmd /c _build.bat "<abs example dir>" "<name>.dpr"`
(it runs `rsvars.bat` then `dcc64 -B -NSSystem;Winapi;System.Win <name>.dpr`; must print `EXIT=0`).
Copy `<repo root>\LumasPdf.dll` next to the built exe, then run it and confirm the SAME output as the
C example (valid `%PDF`, similar size; text/tif/csv as applicable). Stage the same fixtures the C example
used (sample_multipage.pdf, examples\test_files\*, Northwind.mdb, test_cert.pfx pw 123456). print_pdf =
compile-only (printer). pdfviewer = the embedded viewer blocks (8s-timeout = PASS).

Write results to a per-batch report. Return a concise table: example -> BUILD ok/RUN ok / issue.

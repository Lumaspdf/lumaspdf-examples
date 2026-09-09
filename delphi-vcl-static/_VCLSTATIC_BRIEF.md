# Pure VCL static examples — port brief (read fully)

Create 75 Delphi CONSOLE examples that link the WHOLE engine statically (LUMAS_STATIC, runtime
packages OFF) into a **single self-contained exe with ZERO `LumasPdf.dll` dependency**. Output to
`examples\vcl_static\<same-subpath>\<name>.dpr` (mirror the C tree). Reference example already done +
verified: `examples\vcl_static\hello_world` — mirror its shape EXACTLY. The matching **C example**
`examples\c\<same-subpath>\<name>.c` is your PRIMARY logic reference (flat `pdfFoo(handle,args)` ->
`pdf.Foo(args)`, drop `pdf` prefix + handle first-arg, keep A/W suffix).

## Program shape (from hello_world)
```pascal
program <name>;
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST BE FIRST -- binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Types,              // engine PDF enums/consts/records (fsItalic, cp1252, taCenter, dtFit, fmFill, TPDFRect, TCTM, ...)
  Lumas.Pdf.Wrap.Core           // TLumasPDFCore (flat API as methods)
  {,Lumas.Pdf.Wrap.Classes}     // helper CORE classes (report/table/content-parser/...) if needed
  {,Lumas.Rpt.Types};           // reporting enums/records (RPT_EXP_*, TRptCValue, ...) if needed
var pdf: TLumasPDFCore;
begin
  pdf := TLumasPDFCore.Create;  // static: DllPath ignored, engine in-process
  try
    pdf.CreateNewPDFA('');  ...
  finally pdf.Free;
  end;
end.
```

## Rules
- **Enums / consts / records come from the ENGINE units** (`Lumas.Pdf.Types`, `Lumas.Pdf.ApiTypes`,
  `Lumas.Rpt.Types`, `Lumas.Rpt.Errors`), NOT from the DLL-binding `LumasPdf` unit and NOT from
  `Lumas.Pdf.Wrap.Types` (that one `uses LumasPdf` and will NOT compile in the static build). Add the
  engine unit that declares each symbol you need.
- Method names on `TLumasPDFCore` == the flat pdf* API minus prefix/handle (`CreateNewPDFA`, `Append`,
  `SetFontA`, `WriteFTextA`, `EndPage`, `OpenOutputFileA`, `CloseFile`, `OpenImportFileA`, `ImportPDFFile`,
  `EditPage`, `ParseContent`, ...). Enum args typed `Integer` need `Ord(...)`; typed-enum params take the
  enum directly.
- **Reporting**: use the helper CORE classes from `Lumas.Pdf.Wrap.Classes`
  (`TLumasPDFReportEngineCore`, `TLumasPDFReportJobCore`) as the working demo `wrappers\vcl\Examples\
  ReportDemoMain.pas` does, OR the flat rpt* proc pointers. Example 13 is PLUGIN-FREE (register a custom
  function + custom exporter directly via the flat `rptRegisterFunction`/`rptRegisterExporter` proc
  pointers with native `@`-callbacks; NO rptLoadPlugin, NO rpt_testplugin.dll).
- **Callbacks are native** (Delphi `stdcall` functions, pass `@Proc`) — error, ParseContent
  (`TPDFParseInterface`), font/ICC, rpt provider/function/exporter. Same as the C example.
- **Tables**: `TLumasPDFTableCore` helper (or flat tbl*). Barcodes: `bcd.StructSize := SizeOf(TPDFBarcode2)`.
- No `LumasPdf.dll` copy is needed at run time (static). Stage the same DATA fixtures the C example used
  (dynapdf_help.pdf, examples\test_files\*, Northwind.mdb, test_cert.pfx pw 123456).

## Build + verify (the two invariants)
Build: `cmd //c "<repo root>\tools\build_vcl_static_app.bat" "<abs example dir>" "<name>.dpr"` (must
print `EXITCODE=0`). Then:
1. **Zero DLL dependency:** `grep -c "LumasPdf.dll" <name>.exe` must be **0**.
2. **Runs DLL-free + output parity:** with NO `LumasPdf.dll` in the folder, run the exe and confirm it
   reproduces the C baseline output (valid `%PDF`, similar size; text/tif/csv as applicable).
print_pdf = compile-only (printer). pdfviewer = the embedded viewer blocks (8s-timeout = PASS).
Delete the `__dcu` temp dir after building. If an example FAILS to link or run statically, that is a real
engine-static gap — capture the exact dcc64 error / runtime failure (this is deliverable D3 of the plan).

Write results to a per-batch report. Return a concise table: example -> BUILD ok(0-DLL) / RUN ok(parity) / issue.

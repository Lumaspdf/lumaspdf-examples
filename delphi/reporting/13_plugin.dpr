program plugin;
// ===========================================================================
//  LumasReport example 13 -- Register a custom function + custom exporter
//  DIRECTLY via native function pointers, instead of loading an external
//  plugin DLL. The engine now exports rptRegisterFunctionA / rptRegisterExporter
//  (single DLL, no rpt_testplugin.dll / rptLoadPlugin needed):
//
//        PlugDouble(x)  ->  x * 2      (accepts an int or a float)  [function]
//        exporter target 100  ->  writes a marker string to a file  [exporter]
//
//  We invoke the function from a report via {{expr: PlugDouble(21)}} (-> 42) and
//  a float form {{expr: PlugDouble(2.5)}} (-> 5), then invoke the custom
//  exporter via rptExport(Job, 100, '<dir>\13_custom.out').
//  Exports covered: rptRegisterFunctionA, rptRegisterExporter, rptExportA.
// ===========================================================================
{$APPTYPE CONSOLE}
{$MINENUMSIZE 4}
{$ALIGN 8}
uses
  Winapi.Windows, System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

const
  REPORT_XML: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Plugin" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="24">'#10 +
    '   <text name="p1" x="0" y="0"  w="180" h="8" fontSize="16">PlugDouble(21) = {{expr: PlugDouble(21) }}</text>'#10 +
    '   <text name="p2" x="0" y="10" w="180" h="8" fontSize="12">PlugDouble(2.5) = {{expr: PlugDouble(2.5) }}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

// ---- Custom expression function: PlugDouble(x) = x * 2 (stdcall ABI) --------
function PlugDouble(User: Pointer; Args: PRptCValue; NArgs: Int32;
  ResultV: PRptCValue): Int32; stdcall;
begin
  if NArgs <> 1 then Exit(-1);
  case Args^.Kind of
    2: begin ResultV^.Kind := 2; ResultV^.I := Args^.I * 2; end;        // vkInt
    3: begin ResultV^.Kind := 3; ResultV^.F := Args^.F * 2; end;        // vkFloat
  else
    Exit(-2);
  end;
  Result := 0;
end;

// ---- Custom exporter for target id 100 (stdcall ABI) -----------------------
function PlugExport(User: Pointer; Job: Pointer; Path: PAnsiChar): Int32; stdcall;
var
  FS: TFileStream;
  S: AnsiString;
begin
  Result := -1;
  if Path = nil then Exit;
  S := 'PLUGIN:OK -- custom exporter via rptRegisterExporter (no external plugin DLL)';
  try
    FS := TFileStream.Create(string(UTF8ToString(Path)), fmCreate);
    try
      FS.WriteBuffer(S[1], Length(S));
    finally
      FS.Free;
    end;
    Result := 0;
  except
    Result := -3;
  end;
end;

var
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, Lrpt, OutPdf, OutTxt, OutCustom: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));

    // Register the custom function + exporter DIRECTLY -- BEFORE opening.
    if not rptRegisterFunctionA(Eng, 'PlugDouble', 1, 1, @PlugDouble, nil) then
      begin Writeln('rptRegisterFunction failed'); DumpRptError(Eng); Halt(2); end;
    if not rptRegisterExporter(Eng, 100, @PlugExport, nil) then
      begin Writeln('rptRegisterExporter failed'); DumpRptError(Eng); Halt(2); end;
    Writeln('registered function PlugDouble(x)=x*2 and exporter target 100 (no plugin DLL)');

    Lrpt      := Dir + '13_plugin.lrpt';
    OutPdf    := Dir + '13_plugin.pdf';
    OutTxt    := Dir + '13_plugin.txt';
    OutCustom := Dir + '13_custom.out';
    WriteText(Lrpt, REPORT_XML);

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(3); end;
    try
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(4); end;
      if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
        begin Writeln('export PDF failed'); DumpRptError(Eng); Halt(5); end;
      if not rptExportA(Job, RPT_EXP_TEXT, PAnsiChar(OutTxt)) then
        begin Writeln('export TEXT failed'); DumpRptError(Eng); Halt(6); end;
      // Invoke the custom exporter (target 100).
      if not rptExportA(Job, 100, PAnsiChar(OutCustom)) then
        begin Writeln('custom export failed'); DumpRptError(Eng); Halt(7); end;
      Writeln('wrote ' + string(OutPdf));
      Writeln('wrote ' + string(OutCustom) + ' (via custom exporter)');
      Writeln('OK');
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.

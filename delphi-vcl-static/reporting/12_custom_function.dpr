program custom_function;
// ===========================================================================
//  LumasReport PURE-VCL STATIC example 12 -- Custom expression function
//  Static port: engine linked in (LUMAS_STATIC), NO LumasPdf.dll. Registers a
//  Delphi function on the engine via the native @-callback path
//  (RegisterFunction(Eng,'GREET',...,@GreetFn,nil)). The callback matches the
//  engine's C user-function ABI:
//    function(User: Pointer; Args: PRptCValue; NArgs: Int32;
//             ResultV: PRptCValue): Int32; stdcall;   // 0 = success
//  Invoked from the report via {{expr: GREET('World')}}.
// ===========================================================================
{$APPTYPE CONSOLE}
{$ALIGN 8}
{$MINENUMSIZE 4}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils, System.Classes,
  Lumas.Rpt.Types,
  Lumas.Rpt.Errors,
  Lumas.Pdf.Wrap.Core,
  Lumas.Pdf.Wrap.Classes;

{$I _vcl_static_shared.inc}

const
  VK_INT = 2;
  VK_STR = 5;

type
  // Engine's C user-function value ABI (declared locally: the DLL-binding
  // TRptCValue is unavailable in the static build).
  TRptCValue = packed record
    Kind: Int32;
    B:    Int32;
    I:    Int64;
    F:    Double;
    S:    PAnsiChar;   // UTF-8
  end;
  PRptCValue = ^TRptCValue;

var
  // Backing store for the string handed back to the engine. Must outlive the
  // callback return (engine copies it immediately on the way out).
  GResult: AnsiString;

// GREET(name)  ->  'Hello, <name>!'
function GreetFn(User: Pointer; Args: PRptCValue; NArgs: Int32;
  ResultV: PRptCValue): Int32; stdcall;
var
  ArgStr: AnsiString;
begin
  if (NArgs <> 1) or (Args = nil) or (ResultV = nil) then Exit(-1);
  if Args^.Kind = VK_STR then
  begin
    if Args^.S <> nil then ArgStr := AnsiString(Args^.S) else ArgStr := '';
  end
  else if Args^.Kind = VK_INT then
    ArgStr := AnsiString(IntToStr(Args^.I))
  else
    Exit(-2);

  GResult := 'Hello, ' + ArgStr + '!';
  ResultV^.Kind := VK_STR;
  ResultV^.S := PAnsiChar(GResult);
  Result := 0;
end;

const
  REPORT_XML: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="CustomFn" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="24">'#10 +
    '   <text name="g1" x="0" y="0"  w="180" h="8" fontSize="16">{{expr: GREET(''World'') }}</text>'#10 +
    '   <text name="g2" x="0" y="10" w="180" h="8" fontSize="12">{{expr: GREET(''LumasReport'') }}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

var
  Pdf: TLumasPDFCore; Eng: TRPT;
  EC: TLumasPDFReportEngineCore; JC: TLumasPDFReportJobCore; Job: TRPTJOB;
  Dir, Lrpt, OutPdf, OutTxt: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    EC := TLumasPDFReportEngineCore.Create(Eng);
    try
      if not EC.RegisterFunction('GREET', 1, 1, @GreetFn, nil) then
        begin Writeln('rptRegisterFunction failed'); DumpRptError(Pdf, Eng); Halt(2); end;
      Writeln('registered custom function GREET/1');

      Dir    := ExeDir;
      Lrpt   := Dir + '12_custom_function.lrpt';
      OutPdf := Dir + '12_custom_function.pdf';
      OutTxt := Dir + '12_custom_function.txt';
      WriteText(Lrpt, REPORT_XML);

      Job := EC.OpenReportA(PAnsiChar(Lrpt));
      if Job = nil then begin Writeln('open failed'); DumpRptError(Pdf, Eng); Halt(3); end;
      JC := TLumasPDFReportJobCore.Create(Job);
      try
        if not JC.Render then begin Writeln('render failed'); DumpRptError(Pdf, Eng); Halt(4); end;
        if not JC.ExportA(RPT_EXP_PDF, PAnsiChar(OutPdf)) then
          begin Writeln('export PDF failed'); DumpRptError(Pdf, Eng); Halt(5); end;
        if not JC.ExportA(RPT_EXP_TEXT, PAnsiChar(OutTxt)) then
          begin Writeln('export TEXT failed'); DumpRptError(Pdf, Eng); Halt(6); end;
        Writeln('wrote ' + string(OutPdf));
        Writeln('OK');
        JC.CloseReport;
      finally
        JC.Free;
      end;
    finally
      EC.DeleteEngine;
      EC.Free;
    end;
  finally
    Pdf.Free;
  end;
end.

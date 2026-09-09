program custom_function;
// ===========================================================================
//  LumasReport example 12 -- Custom expression function
//  Registers a Delphi-implemented expression function on the engine via
//  rptRegisterFunction(Eng, 'GREET', MinArgs, MaxArgs, @Fn, User). The callback
//  matches the engine's C user-function ABI:
//
//    function(User: Pointer; Args: PRptCValue; NArgs: Int32;
//             ResultV: PRptCValue): Int32; stdcall;   // 0 = success
//
//  where TRptCValue is a packed record { Kind: Int32; B: Int32; I: Int64;
//  F: Double; S: PAnsiChar } and Kind ordinals are vkNull=0, vkBool=1, vkInt=2,
//  vkFloat=3, vkDate=4, vkStr=5. A string result must stay valid until the next
//  call (the engine copies it immediately), so we keep it in a global buffer.
//  The function is invoked from the report via {{expr: GREET('World')}}.
//  Exports covered: rptRegisterFunction + the C user-function ABI.
// ===========================================================================
{$APPTYPE CONSOLE}
{$ALIGN 8}
{$MINENUMSIZE 4}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

const
  VK_INT = 2;
  VK_STR = 5;

type
  TRptCValue = packed record
    Kind: Int32;
    B:    Int32;
    I:    Int64;
    F:    Double;
    S:    PAnsiChar;   // UTF-8
  end;
  PRptCValue = ^TRptCValue;

var
  // Backing store for the string we hand back to the engine. Must outlive the
  // callback return (engine copies it immediately on the way out).
  GResult: AnsiString;

// GREET(name)  ->  'Hello, <name>!'
// Matches the C user-function ABI. Returns 0 on success, negative on error.
function GreetFn(User: Pointer; Args: PRptCValue; NArgs: Int32;
  ResultV: PRptCValue): Int32; stdcall;
var
  ArgStr: AnsiString;
begin
  if (NArgs <> 1) or (Args = nil) or (ResultV = nil) then Exit(-1);
  // Accept a string argument (Kind vkStr = 5).
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
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, Lrpt, OutPdf, OutTxt: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    // Register BEFORE opening/rendering so the compiler resolves GREET.
    if not rptRegisterFunction(Eng, 'GREET', 1, 1, @GreetFn, nil) then
      begin Writeln('rptRegisterFunction failed'); DumpRptError(Eng); Halt(2); end;
    Writeln('registered custom function GREET/1');

    Dir    := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Lrpt   := Dir + '12_custom_function.lrpt';
    OutPdf := Dir + '12_custom_function.pdf';
    OutTxt := Dir + '12_custom_function.txt';
    WriteText(Lrpt, REPORT_XML);

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(3); end;
    try
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(4); end;
      if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
        begin Writeln('export PDF failed'); DumpRptError(Eng); Halt(5); end;
      if not rptExportA(Job, RPT_EXP_TEXT, PAnsiChar(OutTxt)) then
        begin Writeln('export TEXT failed'); DumpRptError(Eng); Halt(6); end;
      Writeln('wrote ' + string(OutPdf));
      Writeln('OK');
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.

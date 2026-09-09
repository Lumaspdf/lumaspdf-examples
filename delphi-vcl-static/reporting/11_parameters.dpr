program parameters;
// ===========================================================================
//  LumasReport PURE-VCL STATIC example 11 -- Report parameters
//  Static port: engine linked in (LUMAS_STATIC), NO LumasPdf.dll. Drives params
//  from Delphi at JOB level via SetParamStr / SetParamNum / SetParamInt (called
//  AFTER OpenReport, BEFORE Render). Rendered TWICE with different values.
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils, System.Classes,
  Lumas.Rpt.Types,
  Lumas.Rpt.Errors,
  Lumas.Pdf.Wrap.Core,
  Lumas.Pdf.Wrap.Classes;

{$I _vcl_static_shared.inc}

const
  REPORT_XML: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Params" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <params>'#10 +
    '  <param name="Customer" default="ACME (default)"/>'#10 +
    '  <param name="UnitPrice" default="0"/>'#10 +
    '  <param name="Qty" default="0"/>'#10 +
    ' </params>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="30">'#10 +
    '   <text name="title" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center">Invoice for {{var:Customer}}</text>'#10 +
    '   <text name="line1" x="0" y="14" w="180" h="6" fontSize="11">Unit price: {{var:UnitPrice}}   Quantity: {{var:Qty}}</text>'#10 +
    '   <text name="line2" x="0" y="22" w="180" h="6" fontSize="11">TOTAL = {{expr: UnitPrice * Qty}}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

function RunOnce(Pdf: TLumasPDFCore; EC: TLumasPDFReportEngineCore;
  const Lrpt, OutPdf, OutTxt, Customer: AnsiString;
  UnitPrice: Double; Qty: Int64): Boolean;
var
  Job: TRPTJOB; JC: TLumasPDFReportJobCore; Eng: TRPT;
begin
  Result := False;
  Eng := EC.Handle;
  Job := EC.OpenReportA(PAnsiChar(Lrpt));
  if Job = nil then begin Writeln('  open failed'); DumpRptError(Pdf, Eng); Exit; end;
  JC := TLumasPDFReportJobCore.Create(Job);
  try
    if not JC.SetParamStr('Customer', PAnsiChar(Customer)) then
      begin Writeln('  SetParamStr failed'); DumpRptError(Pdf, Eng); Exit; end;
    if not JC.SetParamNum('UnitPrice', UnitPrice) then
      begin Writeln('  SetParamNum failed'); DumpRptError(Pdf, Eng); Exit; end;
    if not JC.SetParamInt('Qty', Qty) then
      begin Writeln('  SetParamInt failed'); DumpRptError(Pdf, Eng); Exit; end;

    if not JC.Render then begin Writeln('  render failed'); DumpRptError(Pdf, Eng); Exit; end;
    if not JC.ExportA(RPT_EXP_PDF, PAnsiChar(OutPdf)) then
      begin Writeln('  export PDF failed'); DumpRptError(Pdf, Eng); Exit; end;
    if not JC.ExportA(RPT_EXP_TEXT, PAnsiChar(OutTxt)) then
      begin Writeln('  export TEXT failed'); DumpRptError(Pdf, Eng); Exit; end;
    Writeln(Format('  wrote %s  (Customer="%s" UnitPrice=%.2f Qty=%d  TOTAL=%.2f)',
      [string(OutPdf), string(Customer), UnitPrice, Qty, UnitPrice * Qty]));
    JC.CloseReport;
    Result := True;
  finally
    JC.Free;
  end;
end;

var
  Pdf: TLumasPDFCore; Eng: TRPT; EC: TLumasPDFReportEngineCore;
  Dir, Lrpt: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    EC := TLumasPDFReportEngineCore.Create(Eng);
    try
      Dir  := ExeDir;
      Lrpt := Dir + '11_parameters.lrpt';
      WriteText(Lrpt, REPORT_XML);

      Writeln('Run #1:');
      if not RunOnce(Pdf, EC, Lrpt, Dir + '11_run1.pdf', Dir + '11_run1.txt',
                     'Globex Corporation', 12.50, 4) then Halt(2);

      Writeln('Run #2:');
      if not RunOnce(Pdf, EC, Lrpt, Dir + '11_run2.pdf', Dir + '11_run2.txt',
                     'Initech LLC', 9.99, 10) then Halt(3);

      Writeln('OK');
    finally
      EC.DeleteEngine;
      EC.Free;
    end;
  finally
    Pdf.Free;
  end;
end.

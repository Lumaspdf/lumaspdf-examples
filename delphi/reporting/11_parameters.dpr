program parameters;
// ===========================================================================
//  LumasReport example 11 -- Report parameters
//  Declares <params> in the .lrpt (a string, a number/float, an int) and drives
//  them from Delphi at JOB level via rptSetParamStr / rptSetParamNum /
//  rptSetParamInt (called AFTER rptOpenReport, BEFORE rptRender). The params
//  appear in the layout via {{var:Name}} and are used in an {{expr:}} that
//  multiplies the numeric param by the int param. The whole report is rendered
//  TWICE with different parameter values to prove they drive the output.
//  Exports covered: rptSetParamStr, rptSetParamNum, rptSetParamInt.
//  Tags covered: <params>/<param default>, {{var:P}}, {{expr: A*B}}.
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

const
  REPORT_XML: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Params" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <params>'#10 +
    '  <param name="Customer" default="ACME (default)"/>'#10 +   // string
    '  <param name="UnitPrice" default="0"/>'#10 +               // number / float
    '  <param name="Qty" default="0"/>'#10 +                     // int
    ' </params>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="30">'#10 +
    '   <text name="title" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center">Invoice for {{var:Customer}}</text>'#10 +
    '   <text name="line1" x="0" y="14" w="180" h="6" fontSize="11">Unit price: {{var:UnitPrice}}   Quantity: {{var:Qty}}</text>'#10 +
    '   <text name="line2" x="0" y="22" w="180" h="6" fontSize="11">TOTAL = {{expr: UnitPrice * Qty}}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

// Render the report once with a specific set of parameter values.
function RunOnce(Eng: TRPT; const Lrpt, OutPdf, OutTxt, Customer: AnsiString;
  UnitPrice: Double; Qty: Int64): Boolean;
var
  Job: TRPTJOB;
begin
  Result := False;
  Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
  if Job = nil then begin Writeln('  open failed'); DumpRptError(Eng); Exit; end;
  try
    // --- drive the declared params from Delphi (JOB level) ---
    if not rptSetParamStr(Job, 'Customer', PAnsiChar(Customer)) then
      begin Writeln('  SetParamStr failed'); DumpRptError(Eng); Exit; end;
    if not rptSetParamNum(Job, 'UnitPrice', UnitPrice) then
      begin Writeln('  SetParamNum failed'); DumpRptError(Eng); Exit; end;
    if not rptSetParamInt(Job, 'Qty', Qty) then
      begin Writeln('  SetParamInt failed'); DumpRptError(Eng); Exit; end;

    if not rptRender(Job) then begin Writeln('  render failed'); DumpRptError(Eng); Exit; end;
    if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
      begin Writeln('  export PDF failed'); DumpRptError(Eng); Exit; end;
    if not rptExportA(Job, RPT_EXP_TEXT, PAnsiChar(OutTxt)) then
      begin Writeln('  export TEXT failed'); DumpRptError(Eng); Exit; end;
    Writeln(Format('  wrote %s  (Customer="%s" UnitPrice=%.2f Qty=%d  TOTAL=%.2f)',
      [string(OutPdf), string(Customer), UnitPrice, Qty, UnitPrice * Qty]));
    Result := True;
  finally
    rptCloseReport(Job);
  end;
end;

var
  Pdf: PPDF; Eng: TRPT;
  Dir, Lrpt: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir  := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Lrpt := Dir + '11_parameters.lrpt';
    WriteText(Lrpt, REPORT_XML);

    Writeln('Run #1:');
    if not RunOnce(Eng, Lrpt, Dir + '11_run1.pdf', Dir + '11_run1.txt',
                   'Globex Corporation', 12.50, 4) then Halt(2);

    Writeln('Run #2:');
    if not RunOnce(Eng, Lrpt, Dir + '11_run2.pdf', Dir + '11_run2.txt',
                   'Initech LLC', 9.99, 10) then Halt(3);

    Writeln('OK');
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.

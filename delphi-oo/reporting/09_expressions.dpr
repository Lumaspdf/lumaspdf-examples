program expressions;
// Delphi OO example -- LumasPdfOO wrapper (TPDF/TPDFReport/TPDFReportJob).
// Port of examples\c\reporting\09_expressions.c -- expression function tour.
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf,
  LumasPdfOO;

const
  PDF_DEMO_KEY: AnsiString = 'LUMAS-LumasReportExamples-DD5D40E0';
  RPT_DEMO_KEY: AnsiString =
    'LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM' +
    '.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA';

procedure WriteText(const Path, Content: AnsiString);
var FS: TFileStream;
begin
  FS := TFileStream.Create(string(Path), fmCreate);
  try
    if Content <> '' then FS.WriteBuffer(Content[1], Length(Content));
  finally
    FS.Free;
  end;
end;

procedure DumpRptError(Eng: TRPT);
var Info: TRptErrorInfoC;
begin
  FillChar(Info, SizeOf(Info), 0);
  if rptGetLastError(Eng, @Info) and (Info.Code <> 0) then
    Writeln(Format('  ! rpt error %d [%s] at %s: %s',
      [Info.Code, string(AnsiString(Info.Module_)), string(AnsiString(Info.Location)), string(AnsiString(Info.Msg))]));
end;

function BootEngine(out Pdf: TPDF; out Rpt: TPDFReport): Boolean;
var Eng: TRPT;
begin
  Result := False;
  Pdf := TPDF.Create;
  Pdf.SetLicenseKey(PAnsiChar(PDF_DEMO_KEY));
  Pdf.SetRptLicenseKeyA(PAnsiChar(RPT_DEMO_KEY));
  Eng := Pdf.CreateEngineA(nil);
  if Eng = nil then begin Writeln('rptCreateEngine failed:'); DumpRptError(nil); Exit; end;
  Rpt := TPDFReport.Create(Eng);
  Result := True;
end;

var
  gY: Integer;
  Body: AnsiString;

procedure LineEl(const Label_, Expr: AnsiString);
begin
  Body := Body + AnsiString(Format(
    '   <text name="l%d" x="0" y="%d" w="185" h="5" fontSize="9" wordWrap="0">%s -&gt; {{expr: %s}}</text>'#10,
    [gY, gY, string(Label_), string(Expr)]));
  gY := gY + 5;
end;

var
  Pdf: TPDF; Rpt: TPDFReport; Job: TPDFReportJob;
  Lrpt, OutPdf, OutTxt, Xml: AnsiString;
begin
  Lrpt := '09_expr.lrpt'; OutPdf := '09_expr.pdf'; OutTxt := '09_expr.txt';

  if not BootEngine(Pdf, Rpt) then Halt(1);

  gY := 0; Body := '';
  LineEl('UPPER', 'UPPER(''abc'')');
  LineEl('LOWER', 'LOWER(''ABC'')');
  LineEl('LEFT', 'LEFT(''LumasReport'', 5)');
  LineEl('RIGHT', 'RIGHT(''LumasReport'', 6)');
  LineEl('SUBSTR', 'SUBSTR(''LumasReport'', 6, 6)');
  LineEl('LEN', 'LEN(''LumasReport'')');
  LineEl('TRIM', '''['' + TRIM(''  hi  '') + '']''');
  LineEl('REPLACE', 'REPLACE(''a-b-c'', ''-'', ''+'')');
  LineEl('PADL', 'PADL(''7'', 4, ''0'')');
  LineEl('POS', 'POS(''Report'', ''LumasReport'')');
  LineEl('REVERSE', 'REVERSE(''abc'')');
  LineEl('REPLICATE', 'REPLICATE(''ab'', 3)');
  LineEl('CONTAINS', 'CONTAINS(''LumasReport'', ''Rep'')');
  LineEl('STARTSWITH', 'STARTSWITH(''LumasReport'', ''Lumas'')');
  LineEl('ENDSWITH', 'ENDSWITH(''LumasReport'', ''port'')');
  LineEl('ABS', 'ABS(-42)');
  LineEl('ROUND', 'ROUND(3.14159, 2)');
  LineEl('FLOOR', 'FLOOR(3.9)');
  LineEl('CEIL', 'CEIL(3.1)');
  LineEl('SQRT', 'SQRT(144)');
  LineEl('POWER', 'POWER(2, 10)');
  LineEl('MIN', 'MIN(5, 3)');
  LineEl('MAX', 'MAX(5, 3)');
  LineEl('SIGN', 'SIGN(-7)');
  LineEl('TRUNC', 'TRUNC(9.87)');
  LineEl('MOD_op', '17 % 5');
  LineEl('YEAR', 'YEAR(TODAY())');
  LineEl('FORMATDATE', 'FORMATDATE(''yyyy-mm-dd'', TODAY())');
  LineEl('ADDDAYS', 'FORMATDATE(''yyyy-mm-dd'', ADDDAYS(TODAY(), 7))');
  LineEl('DATEDIFF', 'DATEDIFF(''d'', TODAY(), ADDDAYS(TODAY(), 30))');
  LineEl('CSTR', 'CSTR(123)');
  LineEl('CINT', 'CINT(''45'')');
  LineEl('CFLOAT', 'CFLOAT(''3.5'') * 2');
  LineEl('VAL', 'VAL(''19'') + 1');
  LineEl('FORMATNUM', 'FORMATNUM(''#,##0.00'', 1234.5)');
  LineEl('ISNULL', 'ISNULL(NULLIF(3, 3))');
  LineEl('IFNULL', 'IFNULL(NULLIF(3, 3), ''was-null'')');
  LineEl('COALESCE', 'COALESCE(NULLIF(1,1), NULLIF(2,2), ''fallback'')');
  LineEl('REGEXMATCH', 'REGEXMATCH(''abc123'', ''[a-z]+[0-9]+'')');
  LineEl('REGEXREPLACE', 'REGEXREPLACE(''a1b2c3'', ''[0-9]'', ''#'')');
  LineEl('REGEXEXTRACT', 'REGEXEXTRACT(''order 4567 ok'', ''[0-9]+'')');

  Xml := AnsiString(Format(
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Expressions" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="12" marginTop="12" marginRight="12" marginBottom="12"/>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="%d">'#10 +
    '%s' +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10, [gY + 4, string(Body)]));
  WriteText(Lrpt, Xml);

  Job := TPDFReportJob.Create(Rpt.OpenReportA(PAnsiChar(Lrpt)));
  if Job.Handle = nil then begin Writeln('open failed'); DumpRptError(Rpt.Handle); Halt(2); end;
  if not Job.Render then begin Writeln('render failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Halt(3); end;
  Job.ExportA(RPT_EXP_PDF, PAnsiChar(OutPdf));
  Job.ExportA(RPT_EXP_TEXT, PAnsiChar(OutTxt));
  Writeln(Format('rendered %d page(s); 41 expression lines -> %s', [Job.GetPageCount, string(OutTxt)]));
  Job.CloseReport;

  Rpt.DeleteEngine;
  Pdf.Free;
end.

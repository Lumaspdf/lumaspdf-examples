program expressions;
// ===========================================================================
//  LumasReport example 09 -- the built-in expression-function library
//  Covers ~40 of the ~70 built-ins via {{expr: ...}}: string, math, date,
//  conversion, null-handling and regex families. Each line shows NAME -> result
//  so the TEXT export can be grepped to prove evaluation.
//  (FORMATNUM / FORMATDATE take (format, value); string literals are doubled
//   single-quotes because the whole report is a Delphi AnsiString.)
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

// Build one "<text> label -> {{expr}}" line at a running y offset.
function Line(var Y: Integer; const Label_, Expr: AnsiString): AnsiString;
begin
  Result :=
    '   <text name="l' + AnsiString(IntToStr(Y)) + '" x="0" y="' + AnsiString(IntToStr(Y)) +
    '" w="185" h="5" fontSize="9" wordWrap="0">' + Label_ + ' -&gt; {{expr: ' + Expr + '}}</text>'#10;
  Inc(Y, 5);
end;

function BuildReport: AnsiString;
var s: AnsiString; y: Integer;
begin
  y := 0;
  s := '';
  // ---- string ----
  s := s + Line(y, 'UPPER',      'UPPER(''abc'')');
  s := s + Line(y, 'LOWER',      'LOWER(''ABC'')');
  s := s + Line(y, 'LEFT',       'LEFT(''LumasReport'', 5)');
  s := s + Line(y, 'RIGHT',      'RIGHT(''LumasReport'', 6)');
  s := s + Line(y, 'SUBSTR',     'SUBSTR(''LumasReport'', 6, 6)');
  s := s + Line(y, 'LEN',        'LEN(''LumasReport'')');
  s := s + Line(y, 'TRIM',       '''['' + TRIM(''  hi  '') + '']''');
  s := s + Line(y, 'REPLACE',    'REPLACE(''a-b-c'', ''-'', ''+'')');
  s := s + Line(y, 'PADL',       'PADL(''7'', 4, ''0'')');
  s := s + Line(y, 'POS',        'POS(''Report'', ''LumasReport'')');
  s := s + Line(y, 'REVERSE',    'REVERSE(''abc'')');
  s := s + Line(y, 'REPLICATE',  'REPLICATE(''ab'', 3)');
  s := s + Line(y, 'CONTAINS',   'CONTAINS(''LumasReport'', ''Rep'')');
  s := s + Line(y, 'STARTSWITH', 'STARTSWITH(''LumasReport'', ''Lumas'')');
  s := s + Line(y, 'ENDSWITH',   'ENDSWITH(''LumasReport'', ''port'')');
  // ---- math ----
  s := s + Line(y, 'ABS',    'ABS(-42)');
  s := s + Line(y, 'ROUND',  'ROUND(3.14159, 2)');
  s := s + Line(y, 'FLOOR',  'FLOOR(3.9)');
  s := s + Line(y, 'CEIL',   'CEIL(3.1)');
  s := s + Line(y, 'SQRT',   'SQRT(144)');
  s := s + Line(y, 'POWER',  'POWER(2, 10)');
  s := s + Line(y, 'MIN',    'MIN(5, 3)');
  s := s + Line(y, 'MAX',    'MAX(5, 3)');
  s := s + Line(y, 'SIGN',   'SIGN(-7)');
  s := s + Line(y, 'TRUNC',  'TRUNC(9.87)');
  s := s + Line(y, 'MOD_op', '17 % 5');
  // ---- date ----
  s := s + Line(y, 'YEAR',       'YEAR(TODAY())');
  s := s + Line(y, 'FORMATDATE', 'FORMATDATE(''yyyy-mm-dd'', TODAY())');
  s := s + Line(y, 'ADDDAYS',    'FORMATDATE(''yyyy-mm-dd'', ADDDAYS(TODAY(), 7))');
  s := s + Line(y, 'DATEDIFF',   'DATEDIFF(''d'', TODAY(), ADDDAYS(TODAY(), 30))');
  // ---- conversion ----
  s := s + Line(y, 'CSTR',      'CSTR(123)');
  s := s + Line(y, 'CINT',      'CINT(''45'')');
  s := s + Line(y, 'CFLOAT',    'CFLOAT(''3.5'') * 2');
  s := s + Line(y, 'VAL',       'VAL(''19'') + 1');
  s := s + Line(y, 'FORMATNUM', 'FORMATNUM(''#,##0.00'', 1234.5)');
  // ---- null-handling ----
  s := s + Line(y, 'ISNULL',    'ISNULL(NULLIF(3, 3))');
  s := s + Line(y, 'IFNULL',    'IFNULL(NULLIF(3, 3), ''was-null'')');
  s := s + Line(y, 'COALESCE',  'COALESCE(NULLIF(1,1), NULLIF(2,2), ''fallback'')');
  // ---- regex ----
  s := s + Line(y, 'REGEXMATCH',   'REGEXMATCH(''abc123'', ''[a-z]+[0-9]+'')');
  s := s + Line(y, 'REGEXREPLACE', 'REGEXREPLACE(''a1b2c3'', ''[0-9]'', ''#'')');
  s := s + Line(y, 'REGEXEXTRACT', 'REGEXEXTRACT(''order 4567 ok'', ''[0-9]+'')');

  Result :=
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Expressions" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="12" marginTop="12" marginRight="12" marginBottom="12"/>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="' + AnsiString(IntToStr(y + 4)) + '">'#10 +
    s +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;
end;

var
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB; Dir, Lrpt, OutPdf, OutTxt, Xml: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Xml := BuildReport;
    Dir := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Lrpt := Dir + '09_expr.lrpt'; OutPdf := Dir + '09_expr.pdf'; OutTxt := Dir + '09_expr.txt';
    WriteText(Lrpt, Xml);

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(2); end;
    try
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(3); end;
      rptExportA(Job, RPT_EXP_PDF,  PAnsiChar(OutPdf));
      rptExportA(Job, RPT_EXP_TEXT, PAnsiChar(OutTxt));
      Writeln(Format('rendered %d page(s); %d expression lines -> %s',
        [rptGetPageCount(Job), 41, string(OutTxt)]));
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.

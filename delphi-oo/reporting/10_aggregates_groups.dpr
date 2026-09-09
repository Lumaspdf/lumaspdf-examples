program aggregates_groups;
// ===========================================================================
//  LumasReport OO example 10 -- Grouping + running aggregates
//  OO port of examples\delphi\reporting\10_aggregates_groups.dpr: boots through
//  the OO TPDF class (see _oo_shared.inc) and drives the report with the flat
//  rpt* externals (they live in the LumasPdf unit).
//  Covers groupheader/detail/groupfooter/summary bands over a grouped CSV plus
//  the inline aggregate functions surfaced in {{expr:}}:
//    SUM(x) AVG(x) COUNT(x) COUNT() MIN(x) MAX(x) FIRST(x) LAST(x) COUNTDISTINCT(x)
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf,
  LumasPdfOO;

{$I _oo_shared.inc}

const
  DATA_CSV: AnsiString =
    'Cat,Item,Amount'#10 +
    'Fruit,Apple,10'#10 +
    'Fruit,Pear,7'#10 +
    'Fruit,Plum,5'#10 +
    'Dairy,Milk,4'#10 +
    'Dairy,Cheese,9'#10 +
    'Dairy,Butter,6'#10 +
    'Grain,Bread,3'#10 +
    'Grain,Rice,8'#10 +
    'Grain,Oats,2'#10;

function BuildReport(const CsvPath: AnsiString): AnsiString;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Groups" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="d" provider="csv" conn="' + CsvPath + '"/></datasources>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="10"><text name="t" x="0" y="0" w="180" h="8" fontSize="16" hAlign="center" wordWrap="0">Grouped Catalog</text></band>'#10 +
    '  <band kind="groupheader" name="gh" group="d.Cat" height="7"><text name="g" x="0" y="1" w="180" h="5" fontSize="12" bold="1" wordWrap="0">Category: {{expr: d.Cat}}</text></band>'#10 +
    '  <band kind="detail" name="det" height="5" data="d">' +
    '<text name="i" x="6" y="0" w="110" h="4" fontSize="9" wordWrap="0">{{Item}}</text>' +
    '<text name="a" x="118" y="0" w="26" h="4" fontSize="9" hAlign="right" wordWrap="0">{{Amount}}</text>' +
    '<text name="r" x="148" y="0" w="30" h="4" fontSize="9" hAlign="right" wordWrap="0">[{{expr: SUM(Amount)}}]</text></band>'#10 +
    '  <band kind="groupfooter" name="gf" group="d.Cat" height="6"><text name="gt" x="4" y="0" w="176" h="5" fontSize="9" bold="1" wordWrap="0">' +
    '{{expr: d.Cat}} total = {{expr: SUM(Amount)}}  (n={{expr: COUNT(Amount)}}, avg={{expr: ROUND(AVG(Amount),2)}}, min={{expr: MIN(Amount)}}, max={{expr: MAX(Amount)}})</text></band>'#10 +
    '  <band kind="summary" name="sm" height="8"><text name="s" x="4" y="1" w="176" h="6" fontSize="11" bold="1" wordWrap="0">' +
    'GRAND TOTAL = {{expr: SUM(Amount)}}   (items={{expr: COUNT()}}, categories={{expr: COUNTDISTINCT(Cat)}})</text></band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;
end;

var
  Pdf: TPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, Csv, Lrpt, OutPdf, OutTxt: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Csv := Dir + '10_data.csv'; WriteText(Csv, DATA_CSV);
    OutPdf := Dir + '10_groups.pdf'; OutTxt := Dir + '10_groups.txt';
    Lrpt := Dir + '10_groups.lrpt'; WriteText(Lrpt, BuildReport(Csv));

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(2); end;
    try
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(3); end;
      Writeln(Format('rendered %d page(s), grouped by Cat with per-group + grand totals',
        [rptGetPageCount(Job)]));
      rptExportA(Job, RPT_EXP_PDF,  PAnsiChar(OutPdf));
      rptExportA(Job, RPT_EXP_TEXT, PAnsiChar(OutTxt));
      Writeln('wrote ' + string(OutPdf) + '  +  ' + string(OutTxt));
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    Pdf.Free;
  end;
end.

program tags_and_formatting;
// ===========================================================================
//  LumasReport OO example 15 -- {{ }} tag language + text formatting tour
//  OO port: boots via TPDF (see _oo_shared.inc). Exercises every v1
//  interpolation form + the text-formatting knobs, then proves (by exporting to
//  TEXT and grepping) that the interpolations resolved.
//    {{expr: 2+3*4 }} {{var:Name}} {{fields.d.Col}} {{d.Col}} {{{{ }}
//    {{expr: FORMATNUM('#,##0.00',1234.5) }} {{expr: FORMATDATE('yyyy-mm-dd',TODAY()) }}
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf,
  LumasPdfOO;

{$I _oo_shared.inc}

const
  CSV_DATA: AnsiString =
    'Col,Note'#10 +
    'Alpha,first'#10 +
    'Beta,second'#10;

  REPORT_TMPL: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="TagTour" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="12" marginTop="12" marginRight="12" marginBottom="12"/>'#10 +
    ' <datasources>'#10 +
    '  <datasource alias="d" provider="csv" conn="%CSV%"/>'#10 +
    ' </datasources>'#10 +
    ' <params>'#10 +
    '  <param name="Name" default="(unset)"/>'#10 +
    ' </params>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="120">'#10 +
    '   <text name="h"   x="0" y="0"  w="186" h="8" fontSize="16" hAlign="center">Tag &amp; formatting tour</text>'#10 +
    '   <text name="ex"  x="0" y="12" w="186" h="6" fontSize="11">expr 2+3*4 = {{expr: 2+3*4 }}</text>'#10 +
    '   <text name="vr"  x="0" y="20" w="186" h="6" fontSize="11">var:Name = {{var:Name}}</text>'#10 +
    '   <text name="fn"  x="0" y="28" w="186" h="6" fontSize="11">FORMATNUM = {{expr: FORMATNUM(''#,##0.00'', 1234.5) }}</text>'#10 +
    '   <text name="fd"  x="0" y="36" w="186" h="6" fontSize="11">FORMATDATE = {{expr: FORMATDATE(''yyyy-mm-dd'', TODAY()) }}</text>'#10 +
    '   <text name="esc" x="0" y="44" w="186" h="6" fontSize="11">escape literal = {{{{ }}</text>'#10 +
    '   <text name="a0" x="0" y="56" w="186" h="6" fontSize="10" hAlign="0">hAlign 0 = left</text>'#10 +
    '   <text name="a1" x="0" y="63" w="186" h="6" fontSize="10" hAlign="1">hAlign 1 = center</text>'#10 +
    '   <text name="a2" x="0" y="70" w="186" h="6" fontSize="10" hAlign="2">hAlign 2 = right</text>'#10 +
    '   <text name="a3" x="0" y="77" w="186" h="6" fontSize="10" hAlign="3">hAlign 3 = justify this line so it spreads across the whole width of the box evenly</text>'#10 +
    '   <text name="v0" x="0"   y="92" w="60" h="20" fontSize="9" vAlign="0">vAlign 0 top</text>'#10 +
    '   <text name="v1" x="63"  y="92" w="60" h="20" fontSize="9" vAlign="1">vAlign 1 middle</text>'#10 +
    '   <text name="v2" x="126" y="92" w="60" h="20" fontSize="9" vAlign="2">vAlign 2 bottom</text>'#10 +
    '  </band>'#10 +
    '  <band kind="detail" name="rows" height="7" data="d">'#10 +
    '   <text name="r" x="0" y="0" w="186" h="6" fontSize="11">row: fields.d.Col={{fields.d.Col}}  bare d.Col={{d.Col}}  note={{d.Note}}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

function ReadAllText(const Path: string): AnsiString;
var FS: TFileStream;
begin
  Result := '';
  FS := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Result, FS.Size);
    if FS.Size > 0 then FS.ReadBuffer(Result[1], FS.Size);
  finally
    FS.Free;
  end;
end;

procedure Prove(const What, Needle: string; const Hay: AnsiString);
begin
  if Pos(AnsiString(Needle), Hay) > 0 then
    Writeln(Format('  OK   %-14s found "%s"', [What, Needle]))
  else
    Writeln(Format('  MISS %-14s expected "%s"', [What, Needle]));
end;

var
  Pdf: TPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, Csv, OutPdf, OutTxt, Xml: AnsiString;
  Txt: AnsiString;
  IsoToday: string;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir    := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Csv    := Dir + '15_data.csv';
    OutPdf := Dir + '15_tags.pdf';
    OutTxt := Dir + '15_tags.txt';

    WriteText(Csv, CSV_DATA);

    Xml := AnsiString(StringReplace(string(REPORT_TMPL), '%CSV%',
             string(Csv), [rfReplaceAll]));

    Job := rptOpenReportMem(Eng, @Xml[1], Length(Xml));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(2); end;
    try
      rptSetParamStr(Job, PAnsiChar(AnsiString('Name')),
                          PAnsiChar(AnsiString('Ada_Lovelace')));

      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(3); end;
      Writeln(Format('rendered %d page(s)', [rptGetPageCount(Job)]));

      if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
        begin Writeln('PDF export failed'); DumpRptError(Eng); Halt(4); end;
      Writeln('wrote ' + string(OutPdf));

      if not rptExportA(Job, RPT_EXP_TEXT, PAnsiChar(OutTxt)) then
        begin Writeln('TEXT export failed'); DumpRptError(Eng); Halt(5); end;
      Writeln('wrote ' + string(OutTxt));
    finally
      rptCloseReport(Job);
    end;

    Writeln('== Proof (grep the TEXT export) ==');
    Txt      := ReadAllText(string(OutTxt));
    IsoToday := FormatDateTime('yyyy-mm-dd', Date);

    Prove('expr 2+3*4',  '= 14',          Txt);
    Prove('var:Name',    'Ada_Lovelace',  Txt);
    Prove('FORMATNUM',   '1,234.50',      Txt);
    Prove('FORMATDATE',  IsoToday,        Txt);
    Prove('escape {{}}', '{{ }}',         Txt);
    Prove('fields.d.Col','Alpha',         Txt);
    Prove('bare d.Col',  'Beta',          Txt);
  finally
    rptDeleteEngine(Eng);
    Pdf.Free;
  end;
end.

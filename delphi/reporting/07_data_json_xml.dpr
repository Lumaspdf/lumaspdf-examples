program data_json_xml_report;
// ===========================================================================
//  LumasReport example 07 -- JSON and XML data sources
//  Writes a JSON file (array of objects) and an XML file (<rows><row/></rows>)
//  next to the exe. Because a single report has ONE master detail dataset
//  (the layout drives every detail band from the first detail band's alias),
//  each provider gets its own report RUN. Both export PDF + TEXT so the field
//  values can be grepped back out to prove each parser fed the layout.
//  Surface covered: json provider (query="" -> document-root array) +
//                   xml provider (query="rows/row").
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

const
  JSON_DATA: AnsiString =
    '[' +
    '{"City":"Paris","Country":"FR","Pop":2100},' +
    '{"City":"Lyon","Country":"FR","Pop":515},' +
    '{"City":"Nice","Country":"FR","Pop":340}' +
    ']';

  XML_DATA: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<rows>'#10 +
    ' <row City="Berlin" Country="DE" Pop="3600"/>'#10 +
    ' <row City="Munich" Country="DE" Pop="1500"/>'#10 +
    ' <row City="Hamburg" Country="DE" Pop="1900"/>'#10 +
    '</rows>'#10;

  // JSON report: {{CONN}} <- absolute .json path. query="" => root is the array.
  JSON_A: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="JsonCities" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="j" provider="json" conn="';
  JSON_B: AnsiString =
    '" query=""/></datasources>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="10">'#10 +
    '   <text name="ttl" x="0" y="0" w="180" h="8" fontSize="16" hAlign="center">Cities (JSON source)</text>'#10 +
    '  </band>'#10 +
    '  <band kind="detail" name="jd" height="6" data="j">'#10 +
    '   <text name="c1" x="0"  y="0" w="60" h="5" fontSize="9" wordWrap="0">{{j.City}}</text>'#10 +
    '   <text name="c2" x="60" y="0" w="30" h="5" fontSize="9" wordWrap="0">{{j.Country}}</text>'#10 +
    '   <text name="c3" x="90" y="0" w="40" h="5" fontSize="9" hAlign="right" wordWrap="0">{{j.Pop}}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

  // XML report: {{CONN}} <- absolute .xml path. query="rows/row".
  XML_A: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="XmlCities" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="x" provider="xml" conn="';
  XML_B: AnsiString =
    '" query="rows/row"/></datasources>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="10">'#10 +
    '   <text name="ttl" x="0" y="0" w="180" h="8" fontSize="16" hAlign="center">Cities (XML source)</text>'#10 +
    '  </band>'#10 +
    '  <band kind="detail" name="xd" height="6" data="x">'#10 +
    '   <text name="c1" x="0"  y="0" w="60" h="5" fontSize="9" wordWrap="0">{{x.City}}</text>'#10 +
    '   <text name="c2" x="60" y="0" w="30" h="5" fontSize="9" wordWrap="0">{{x.Country}}</text>'#10 +
    '   <text name="c3" x="90" y="0" w="40" h="5" fontSize="9" hAlign="right" wordWrap="0">{{x.Pop}}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

var
  Pdf: PPDF; Eng: TRPT;
  Dir: AnsiString;

// Save Xml, render it, export PDF + TEXT. Returns False on any failure.
function RunReport(const Tag, Xml: AnsiString): Boolean;
var
  Job: TRPTJOB; Lrpt, OutPdf, OutTxt: AnsiString;
begin
  Result := False;
  Lrpt   := Dir + '07_' + Tag + '.lrpt';
  OutPdf := Dir + '07_' + Tag + '.pdf';
  OutTxt := Dir + '07_' + Tag + '.txt';
  WriteText(Lrpt, Xml);
  Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
  if Job = nil then begin Writeln(Tag + ': open failed'); DumpRptError(Eng); Exit; end;
  try
    if not rptRender(Job) then begin Writeln(Tag + ': render failed'); DumpRptError(Eng); Exit; end;
    Writeln(Format('%s: rendered %d page(s)', [string(Tag), rptGetPageCount(Job)]));
    if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
      begin Writeln(Tag + ': pdf export failed'); DumpRptError(Eng); Exit; end;
    if not rptExportA(Job, RPT_EXP_TEXT, PAnsiChar(OutTxt)) then
      begin Writeln(Tag + ': text export failed'); DumpRptError(Eng); Exit; end;
    Writeln('wrote ' + string(OutPdf) + ' + ' + string(OutTxt));
    Result := True;
  finally
    rptCloseReport(Job);
  end;
end;

var
  Jsn, Xm: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Jsn := Dir + '07_data.json';
    Xm  := Dir + '07_data.xml';
    WriteText(Jsn, JSON_DATA);
    WriteText(Xm, XML_DATA);

    if not RunReport('json', JSON_A + Jsn + JSON_B) then Halt(2);
    if not RunReport('xml',  XML_A  + Xm  + XML_B)  then Halt(3);
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.

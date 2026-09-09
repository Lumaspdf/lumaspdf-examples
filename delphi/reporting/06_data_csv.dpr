program data_csv_report;
// ===========================================================================
//  LumasReport example 06 -- CSV data source + field interpolation
//  Writes a real CSV (Region,Product,Qty,Price + 6 rows) next to the exe,
//  binds it to a detail band via provider="csv", and prints one line per row
//  with {{d.Region}} {{d.Product}} {{d.Qty}} {{d.Price}} interpolation.
//  Exports PDF, CSV and TEXT so the row values can be grepped back out to
//  prove the data actually flowed through the pipeline.
//  Surface covered: csv provider + qualified {alias.Field} interpolation.
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

const
  CSV_DATA: AnsiString =
    'Region,Product,Qty,Price'#10 +
    'North,Widget,10,2.50'#10 +
    'North,Gadget,4,9.99'#10 +
    'South,Widget,7,2.50'#10 +
    'South,Sprocket,20,1.25'#10 +
    'East,Gadget,3,9.99'#10 +
    'West,Sprocket,15,1.25'#10;

  // {{CSV}} is replaced with the absolute CSV path before the report is saved.
  RPT_A: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="CsvSales" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="d" provider="csv" conn="';
  RPT_B: AnsiString =
    '"/></datasources>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="12">'#10 +
    '   <text name="ttl" x="0" y="0" w="180" h="8" fontSize="16" hAlign="center">Sales by Region</text>'#10 +
    '  </band>'#10 +
    '  <band kind="pageheader" name="ph" height="8">'#10 +
    '   <text name="h1" x="0"   y="0" w="50" h="6" fontSize="9" style="">REGION</text>'#10 +
    '   <text name="h2" x="50"  y="0" w="60" h="6" fontSize="9">PRODUCT</text>'#10 +
    '   <text name="h3" x="110" y="0" w="30" h="6" fontSize="9" hAlign="right">QTY</text>'#10 +
    '   <text name="h4" x="140" y="0" w="40" h="6" fontSize="9" hAlign="right">PRICE</text>'#10 +
    '   <line name="hl" x="0" y="7" w="180" h="0.3" toX="180" toY="0"/>'#10 +
    '  </band>'#10 +
    '  <band kind="detail" name="det" height="6" data="d">'#10 +
    '   <text name="c1" x="0"   y="0" w="50" h="5" fontSize="9" wordWrap="0">{{d.Region}}</text>'#10 +
    '   <text name="c2" x="50"  y="0" w="60" h="5" fontSize="9" wordWrap="0">{{d.Product}}</text>'#10 +
    '   <text name="c3" x="110" y="0" w="30" h="5" fontSize="9" hAlign="right" wordWrap="0">{{d.Qty}}</text>'#10 +
    '   <text name="c4" x="140" y="0" w="40" h="5" fontSize="9" hAlign="right" wordWrap="0">{{d.Price}}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

var
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, Lrpt, Csv, OutPdf, OutCsv, OutTxt, Xml: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir    := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Lrpt   := Dir + '06_data.lrpt';
    Csv    := Dir + '06_data.csv';
    OutPdf := Dir + '06_data.pdf';
    OutCsv := Dir + '06_data_out.csv';
    OutTxt := Dir + '06_data.txt';

    WriteText(Csv, CSV_DATA);
    Xml := RPT_A + Csv + RPT_B;
    WriteText(Lrpt, Xml);

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(2); end;
    try
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(3); end;
      Writeln(Format('rendered %d page(s)', [rptGetPageCount(Job)]));
      if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
        begin Writeln('pdf export failed'); DumpRptError(Eng); Halt(4); end;
      if not rptExportA(Job, RPT_EXP_CSV, PAnsiChar(OutCsv)) then
        begin Writeln('csv export failed'); DumpRptError(Eng); Halt(5); end;
      if not rptExportA(Job, RPT_EXP_TEXT, PAnsiChar(OutTxt)) then
        begin Writeln('text export failed'); DumpRptError(Eng); Halt(6); end;
      Writeln('wrote ' + string(OutPdf));
      Writeln('wrote ' + string(OutCsv));
      Writeln('wrote ' + string(OutTxt));
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.

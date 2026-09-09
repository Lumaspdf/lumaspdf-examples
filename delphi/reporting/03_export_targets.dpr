program export_targets;
// ===========================================================================
//  LumasReport example 03 -- Every export target
//  One small CSV-bound report (reportheader + detail), rendered once, then
//  exported to all 10 supported targets in a loop, reporting success + size.
//
//  Exports covered: rptOpenReportA, rptRender, rptGetPageCount, rptExportA.
//  Constants covered: the full RPT_EXP_* enum (PDF/HTML/CSV/JSON/XML/TEXT/
//                     SVG/XLSX/PNG/BMP).
//  Tags covered: <datasource provider="csv">, band kinds reportheader+detail,
//                {{alias.Field}} interpolation.
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

const
  CSV_DATA: AnsiString =
    'product,qty,price'#10 +
    'Widget,4,9.95'#10 +
    'Gadget,2,19.50'#10 +
    'Sprocket,7,3.25'#10;

  // Parallel arrays: export target id + the file extension it produces.
  N_TARGETS = 10;
  TARGETS: array[0..N_TARGETS-1] of Integer =
    (RPT_EXP_PDF, RPT_EXP_HTML, RPT_EXP_CSV, RPT_EXP_JSON, RPT_EXP_XML,
     RPT_EXP_TEXT, RPT_EXP_SVG, RPT_EXP_XLSX, RPT_EXP_PNG, RPT_EXP_BMP);
  EXTS: array[0..N_TARGETS-1] of string =
    ('pdf', 'html', 'csv', 'json', 'xml', 'txt', 'svg', 'xlsx', 'png', 'bmp');

// Size of a file in bytes, or -1 if it cannot be opened.
function FileSizeOf(const Path: string): Int64;
var FS: TFileStream;
begin
  Result := -1;
  try
    FS := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
    try Result := FS.Size; finally FS.Free; end;
  except
    Result := -1;
  end;
end;

function BuildReportXml(const CsvPath: AnsiString): AnsiString;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="ExportDemo" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="d" provider="csv" conn="' + CsvPath + '"/></datasources>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="14">'#10 +
    '   <text name="ttl" x="0" y="0" w="180" h="8" fontSize="16" hAlign="center">Order Lines</text>'#10 +
    '  </band>'#10 +
    '  <band kind="detail" name="det" height="7" data="d">'#10 +
    '   <text name="p" x="0"   y="0" w="90" h="6" fontSize="10" wordWrap="0">{{d.product}}</text>'#10 +
    '   <text name="q" x="90"  y="0" w="30" h="6" fontSize="10" hAlign="right" wordWrap="0">{{d.qty}}</text>'#10 +
    '   <text name="r" x="120" y="0" w="60" h="6" fontSize="10" hAlign="right" wordWrap="0">{{d.price}}</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;
end;

var
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, Csv, Lrpt, OutFile: AnsiString;
  I: Integer; Ok: Boolean;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir  := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Csv  := Dir + '03_data.csv';
    Lrpt := Dir + '03_report.lrpt';
    WriteText(Csv, CSV_DATA);
    WriteText(Lrpt, BuildReportXml(Csv));

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(2); end;
    try
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(3); end;
      Writeln(Format('rendered %d page(s)', [rptGetPageCount(Job)]));
      Writeln('== Exporting to all targets ==');
      for I := 0 to N_TARGETS - 1 do
      begin
        OutFile := Dir + AnsiString('03_out.' + EXTS[I]);
        Ok := rptExportA(Job, TARGETS[I], PAnsiChar(OutFile));
        if Ok and FileExists(string(OutFile)) then
          Writeln(Format('  [%-4s] id=%d  OK  %d bytes',
            [EXTS[I], TARGETS[I], FileSizeOf(string(OutFile))]))
        else
        begin
          Writeln(Format('  [%-4s] id=%d  FAILED', [EXTS[I], TARGETS[I]]));
          DumpRptError(Eng);
        end;
      end;
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.

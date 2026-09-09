program export_targets;
// Delphi OO example -- LumasPdfOO wrapper (TPDF/TPDFReport/TPDFReportJob).
// Port of examples\c\reporting\03_export_targets.c -- export to all targets.
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

function FileSizeOf(const Path: string): Int64;
begin
  if FileExists(Path) then
    with TFileStream.Create(Path, fmOpenRead or fmShareDenyNone) do
    try Result := Size; finally Free; end
  else Result := -1;
end;

const
  Targets: array[0..9] of Integer =
    (RPT_EXP_PDF, RPT_EXP_HTML, RPT_EXP_CSV, RPT_EXP_JSON, RPT_EXP_XML,
     RPT_EXP_TEXT, RPT_EXP_SVG, RPT_EXP_XLSX, RPT_EXP_PNG, RPT_EXP_BMP);
  Exts: array[0..9] of string =
    ('pdf', 'html', 'csv', 'json', 'xml', 'txt', 'svg', 'xlsx', 'png', 'bmp');

var
  Pdf: TPDF; Rpt: TPDFReport; Job: TPDFReportJob;
  I: Integer;
  Csv, Lrpt, Xml, OutFile: AnsiString;
begin
  Csv := '03_data.csv'; Lrpt := '03_report.lrpt';

  if not BootEngine(Pdf, Rpt) then Halt(1);

  WriteText(Csv,
    'product,qty,price'#10 +
    'Widget,4,9.95'#10 +
    'Gadget,2,19.50'#10 +
    'Sprocket,7,3.25'#10);

  Xml :=
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="ExportDemo" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="d" provider="csv" conn="' + Csv + '"/></datasources>'#10 +
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
  WriteText(Lrpt, Xml);

  Job := TPDFReportJob.Create(Rpt.OpenReportA(PAnsiChar(Lrpt)));
  if Job.Handle = nil then begin Writeln('open failed'); DumpRptError(Rpt.Handle); Halt(2); end;
  if not Job.Render then begin Writeln('render failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Halt(3); end;
  Writeln(Format('rendered %d page(s)', [Job.GetPageCount]));
  Writeln('== Exporting to all targets ==');
  for I := 0 to 9 do
  begin
    OutFile := AnsiString('03_out.' + Exts[I]);
    if Job.ExportA(Targets[I], PAnsiChar(OutFile)) and FileExists(string(OutFile)) then
      Writeln(Format('  [%s] id=%d  OK  %d bytes', [Exts[I], Targets[I], FileSizeOf(string(OutFile))]))
    else begin Writeln(Format('  [%s] id=%d  FAILED', [Exts[I], Targets[I]])); DumpRptError(Rpt.Handle); end;
  end;
  Job.CloseReport;

  Rpt.DeleteEngine;
  Pdf.Free;
end.

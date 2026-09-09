program license_and_errors;
// Delphi OO example -- LumasPdfOO wrapper (TPDF/TPDFReport/TPDFReportJob).
// Port of examples\c\reporting\02_license_and_errors.c -- license info + deliberate errors.
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
  REPORT_XML: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="LicDemo" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="16">'#10 +
    '   <text name="t" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center">License &amp; error demo</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

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

function FeaturesToStr(F: Cardinal): string;
begin
  Result := '';
  if (F and RPT_FEAT_CORE) <> 0 then Result := Result + 'CORE ';
  if (F and RPT_FEAT_EXPORT_PDF) <> 0 then Result := Result + 'PDF ';
  if (F and RPT_FEAT_EXPORT_WEB) <> 0 then Result := Result + 'WEB ';
  if (F and RPT_FEAT_EXPORT_DATA) <> 0 then Result := Result + 'DATA ';
  if (F and RPT_FEAT_PREVIEW) <> 0 then Result := Result + 'PREVIEW ';
  if (F and RPT_FEAT_PRINT) <> 0 then Result := Result + 'PRINT ';
  if (F and RPT_FEAT_PLUGINS) <> 0 then Result := Result + 'PLUGINS ';
  Result := Trim(Result);
end;

function LastErrorCode(Eng: TRPT): Integer;
var Info: TRptErrorInfoC;
begin
  FillChar(Info, SizeOf(Info), 0);
  if rptGetLastError(Eng, @Info) then Result := Info.Code else Result := 0;
end;

procedure ShowError(const Tag: string; Eng: TRPT);
var Info: TRptErrorInfoC;
begin
  FillChar(Info, SizeOf(Info), 0);
  if rptGetLastError(Eng, @Info) and (Info.Code <> 0) then
    Writeln(Format('  %s -> code %d  module=%s  location=%s  msg=%s',
      [Tag, Info.Code, string(AnsiString(Info.Module_)), string(AnsiString(Info.Location)), string(AnsiString(Info.Msg))]))
  else
    Writeln(Format('  %s -> (no structured error reported)', [Tag]));
end;

var
  Pdf: TPDF; Rpt: TPDFReport; Job: TPDFReportJob;
  Info: TRptLicenseInfoC;
  PrevCode: Integer;
  GoodLrpt, BadLrpt, OutPdf: AnsiString;
begin
  GoodLrpt := '02_good.lrpt'; BadLrpt := '02_bad.lrpt'; OutPdf := '02_out.pdf';

  if not BootEngine(Pdf, Rpt) then Halt(1);

  Writeln('== License info ==');
  FillChar(Info, SizeOf(Info), 0);
  Info.StructSize := SizeOf(Info);
  if Rpt.GetLicenseInfo(@Info) then
  begin
    Writeln(Format('  Edition  : %d', [Info.Edition]));
    Writeln(Format('  Features : $%.8X (%s)', [Info.Features, FeaturesToStr(Info.Features)]));
    Writeln(Format('  LicClass : %d', [Info.LicClass]));
    Writeln(Format('  LockClass: %d', [Info.LockClass]));
    if Info.Expiry = 0 then Writeln('  Expiry   : 0 (perpetual / unbound)')
    else Writeln(Format('  Expiry   : %d', [Info.Expiry]));
    Writeln(Format('  Customer : %s', [string(AnsiString(Info.Customer))]));
  end
  else begin Writeln('  rptGetLicenseInfo failed'); DumpRptError(Rpt.Handle); end;

  Writeln('== Deliberate errors ==');

  WriteText(BadLrpt, 'this is not a report at all'#10);
  Job := TPDFReportJob.Create(Rpt.OpenReportA(PAnsiChar(BadLrpt)));
  if Job.Handle = nil then ShowError('open(not-XML .lrpt)', Rpt.Handle)
  else begin Writeln('  open(not-XML .lrpt) -> unexpectedly succeeded'); Job.CloseReport; end;
  Job.Free;

  WriteText(BadLrpt, '<notreport><oops/></notreport>'#10);
  Job := TPDFReportJob.Create(Rpt.OpenReportA(PAnsiChar(BadLrpt)));
  if Job.Handle = nil then ShowError('open(wrong-root .lrpt)', Rpt.Handle)
  else begin Writeln('  open(wrong-root .lrpt) -> unexpectedly succeeded'); Job.CloseReport; end;
  Job.Free;

  PrevCode := LastErrorCode(Rpt.Handle);
  if rptRender(nil) then Writeln('  rptRender(nil) -> unexpectedly succeeded')
  else if LastErrorCode(Rpt.Handle) = PrevCode then
    Writeln(Format('  rptRender(nil) -> returned False; no new engine error (last code still %d)', [PrevCode]))
  else ShowError('rptRender(nil)', Rpt.Handle);

  PrevCode := LastErrorCode(Rpt.Handle);
  if rptExportA(nil, RPT_EXP_PDF, PAnsiChar(OutPdf)) then Writeln('  rptExportA(nil) -> unexpectedly succeeded')
  else if LastErrorCode(Rpt.Handle) = PrevCode then
    Writeln(Format('  rptExportA(nil) -> returned False; no new engine error (last code still %d)', [PrevCode]))
  else ShowError('rptExportA(nil)', Rpt.Handle);

  Writeln('== Valid render ==');
  WriteText(GoodLrpt, REPORT_XML);
  Job := TPDFReportJob.Create(Rpt.OpenReportA(PAnsiChar(GoodLrpt)));
  if Job.Handle = nil then begin Writeln('  open failed'); DumpRptError(Rpt.Handle); Rpt.DeleteEngine; Pdf.Free; Halt(0); end;
  if not Job.Render then begin Writeln('  render failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Rpt.DeleteEngine; Pdf.Free; Halt(0); end;
  Writeln(Format('  rendered %d page(s)', [Job.GetPageCount]));
  if not Job.ExportA(RPT_EXP_PDF, PAnsiChar(OutPdf)) then begin Writeln('  export failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Rpt.DeleteEngine; Pdf.Free; Halt(0); end;
  Writeln('  wrote ' + string(OutPdf));
  Job.CloseReport;

  Rpt.DeleteEngine;
  Pdf.Free;
end.

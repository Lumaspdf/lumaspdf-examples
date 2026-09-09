program hello_report;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF/TPDFReport/TPDFReportJob), NOT the flat API.
// Port of examples\c\reporting\01_hello_report.c -- minimal engine -> render -> PDF.
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
    '<report name="Hello" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="20">'#10 +
    '   <text name="title" x="0" y="0" w="180" h="10" fontSize="20" hAlign="center">Hello, LumasReport!</text>'#10 +
    '   <text name="sub"   x="0" y="12" w="180" h="6" fontSize="10" hAlign="center">The minimal engine -&gt; render -&gt; PDF flow.</text>'#10 +
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

var
  Pdf: TPDF; Rpt: TPDFReport; Job: TPDFReportJob;
  Mj, Mn, Pt: Integer;
  Lrpt, OutPdf: AnsiString;
begin
  Mj := 0; Mn := 0; Pt := 0;
  rptGetVersion(@Mj, @Mn, @Pt);
  Writeln(Format('LumasReport v%d.%d.%d', [Mj, Mn, Pt]));

  if not BootEngine(Pdf, Rpt) then Halt(1);
  Lrpt := '01_hello.lrpt';
  OutPdf := '01_hello.pdf';
  WriteText(Lrpt, REPORT_XML);

  Job := TPDFReportJob.Create(Rpt.OpenReportA(PAnsiChar(Lrpt)));
  if Job.Handle = nil then begin Writeln('open failed'); DumpRptError(Rpt.Handle); Halt(2); end;
  if not Job.Render then begin Writeln('render failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Halt(3); end;
  Writeln(Format('rendered %d page(s)', [Job.GetPageCount]));
  if not Job.ExportA(RPT_EXP_PDF, PAnsiChar(OutPdf)) then
    begin Writeln('export failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Halt(4); end;
  Writeln('wrote ' + string(OutPdf));
  Job.CloseReport;

  Rpt.DeleteEngine;
  Pdf.Free;
end.

program bands;
// Delphi OO example -- LumasPdfOO wrapper (TPDF/TPDFReport/TPDFReportJob).
// Port of examples\c\reporting\04_bands.c -- all band kinds, multi-page grouped.
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

function BuildCsv: AnsiString;
var G, R: Integer;
begin
  Result := 'grp,item,val'#10;
  for G := 1 to 3 do
    for R := 1 to 30 do
      Result := Result + AnsiString(Format('Group-%d,Item %d-%.2d,%d'#10, [G, G, R, G * 100 + R]));
end;

var
  Pdf: TPDF; Rpt: TPDFReport; Job: TPDFReportJob;
  Pages: Integer;
  Csv, Lrpt, OutPdf, Xml: AnsiString;
begin
  Csv := '04_data.csv'; Lrpt := '04_report.lrpt'; OutPdf := '04_out.pdf';

  if not BootEngine(Pdf, Rpt) then Halt(1);

  WriteText(Csv, BuildCsv);

  Xml :=
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="BandsDemo" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="d" provider="csv" conn="' + Csv + '"/></datasources>'#10 +
    ' <styles>'#10 +
    '  <style name="Wm"  fontSize="48" bold="1" textColor="00EEEEEE" hAlign="1" vAlign="1"/>'#10 +
    '  <style name="Ov"  fontSize="8"  textColor="00B0B0B0" hAlign="2"/>'#10 +
    '  <style name="Grp" fontSize="12" bold="1" textColor="00FFFFFF" backColor="002A6099" vAlign="1"/>'#10 +
    ' </styles>'#10 +
    ' <bands>'#10 +
    '  <band kind="background" name="bg" height="297">'#10 +
    '   <text name="wm" x="20" y="120" w="150" h="40" style="Wm" rotation="45" wordWrap="0">BACKGROUND</text>'#10 +
    '  </band>'#10 +
    '  <band kind="overlay" name="ov" height="297">'#10 +
    '   <text name="ol" x="0" y="150" w="180" h="6" style="Ov" rotation="90" wordWrap="0">overlay band</text>'#10 +
    '  </band>'#10 +
    '  <band kind="reportheader" name="rh" height="16">'#10 +
    '   <text name="rt" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center">reportheader band</text>'#10 +
    '  </band>'#10 +
    '  <band kind="pageheader" name="ph" height="8">'#10 +
    '   <text name="pt" x="0" y="0" w="180" h="6" fontSize="9" wordWrap="0">pageheader band - grp / item / val</text>'#10 +
    '  </band>'#10 +
    '  <band kind="groupheader" name="gh" group="d.grp" height="8">'#10 +
    '   <text name="gt" x="0" y="0" w="180" h="7" style="Grp" wordWrap="0">groupheader band: {{d.grp}}</text>'#10 +
    '  </band>'#10 +
    '  <band kind="detail" name="det" height="6" data="d">'#10 +
    '   <text name="di" x="4"   y="0" w="120" h="5" fontSize="9" wordWrap="0">detail band: {{d.item}}</text>'#10 +
    '   <text name="dv" x="130" y="0" w="46"  h="5" fontSize="9" hAlign="right" wordWrap="0">{{d.val}}</text>'#10 +
    '  </band>'#10 +
    '  <band kind="groupfooter" name="gf" group="d.grp" height="7">'#10 +
    '   <text name="ft" x="0" y="1" w="180" h="5" fontSize="9" italic="1" wordWrap="0">groupfooter band: end of {{d.grp}}</text>'#10 +
    '  </band>'#10 +
    '  <band kind="pagefooter" name="pf" height="7">'#10 +
    '   <text name="pft" x="0" y="1" w="180" h="5" fontSize="8" hAlign="center" wordWrap="0">pagefooter band</text>'#10 +
    '  </band>'#10 +
    '  <band kind="summary" name="sm" height="16">'#10 +
    '   <text name="st" x="0" y="2" w="180" h="10" fontSize="14" hAlign="center">summary band - report complete</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;
  WriteText(Lrpt, Xml);

  Job := TPDFReportJob.Create(Rpt.OpenReportA(PAnsiChar(Lrpt)));
  if Job.Handle = nil then begin Writeln('open failed'); DumpRptError(Rpt.Handle); Halt(2); end;
  if not Job.Render then begin Writeln('render failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Halt(3); end;
  Pages := Job.GetPageCount;
  Writeln(Format('rendered %d page(s)', [Pages]));
  if not Job.ExportA(RPT_EXP_PDF, PAnsiChar(OutPdf)) then begin Writeln('export failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Halt(4); end;
  Writeln('wrote ' + string(OutPdf));
  if Pages < 2 then Writeln(Format('FAIL: expected >= 2 pages, got %d', [Pages]))
  else Writeln('OK: multi-page grouped report with all band kinds');
  Job.CloseReport;

  Rpt.DeleteEngine;
  Pdf.Free;
end.

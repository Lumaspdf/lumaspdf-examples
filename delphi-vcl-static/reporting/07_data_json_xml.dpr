program data_json_xml;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Port of examples\c\reporting\07_data_json_xml.c -- JSON and XML data providers.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // binds every engine entry point in-process (MUST be first)
  System.SysUtils, System.Classes,
  Lumas.Rpt.Types, Lumas.Rpt.Errors, Lumas.Rpt.Data.Provider,  // rpt enums/records
  Lumas.Pdf.Wrap.Core,          // TLumasPDFCore
  Lumas.Pdf.Wrap.Classes,       // TLumasPDFReportEngineCore / TLumasPDFReportJobCore
  Lumas.Pdf.Wrap.Imports;       // flat rpt* (rptGetLastError/rptRender/rptExportA nil cases)

const
  PDF_DEMO_KEY: AnsiString = 'LUMAS-LumasReportExamples-DD5D40E0';
  RPT_DEMO_KEY: AnsiString =
    'LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM' +
    '.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA';

var
  gPdf: TLumasPDFCore; gRpt: TLumasPDFReportEngineCore;

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

function BootEngine: Boolean;
var Eng: TRPT;
begin
  Result := False;
  gPdf := TLumasPDFCore.Create;
  gPdf.SetLicenseKey(PAnsiChar(PDF_DEMO_KEY));
  gPdf.RptSetRptLicenseKeyA(PAnsiChar(RPT_DEMO_KEY));
  Eng := gPdf.RptCreateEngineA(nil);
  if Eng = nil then begin Writeln('rptCreateEngine failed:'); DumpRptError(nil); Exit; end;
  gRpt := TLumasPDFReportEngineCore.Create(Eng);
  Result := True;
end;

function RunReport(const Tag: string; const Xml: AnsiString): Boolean;
var Job: TLumasPDFReportJobCore; Lrpt, OutPdf, OutTxt: AnsiString;
begin
  Result := False;
  Lrpt := AnsiString(Format('07_%s.lrpt', [Tag]));
  OutPdf := AnsiString(Format('07_%s.pdf', [Tag]));
  OutTxt := AnsiString(Format('07_%s.txt', [Tag]));
  WriteText(Lrpt, Xml);
  Job := TLumasPDFReportJobCore.Create(gRpt.OpenReportA(PAnsiChar(Lrpt)));
  if Job.Handle = nil then begin Writeln(Format('%s: open failed', [Tag])); DumpRptError(gRpt.Handle); Exit; end;
  if not Job.Render then begin Writeln(Format('%s: render failed', [Tag])); DumpRptError(gRpt.Handle); Job.CloseReport; Exit; end;
  Writeln(Format('%s: rendered %d page(s)', [Tag, Job.GetPageCount]));
  if not Job.ExportA(RPT_EXP_PDF, PAnsiChar(OutPdf)) then begin Writeln(Format('%s: pdf export failed', [Tag])); DumpRptError(gRpt.Handle); Job.CloseReport; Exit; end;
  if not Job.ExportA(RPT_EXP_TEXT, PAnsiChar(OutTxt)) then begin Writeln(Format('%s: text export failed', [Tag])); DumpRptError(gRpt.Handle); Job.CloseReport; Exit; end;
  Writeln(Format('wrote %s + %s', [string(OutPdf), string(OutTxt)]));
  Job.CloseReport;
  Result := True;
end;

var
  Jsn, Xm, Xml: AnsiString;
begin
  Jsn := '07_data.json'; Xm := '07_data.xml';

  if not BootEngine then Halt(1);

  WriteText(Jsn, '[{"City":"Paris","Country":"FR","Pop":2100},{"City":"Lyon","Country":"FR","Pop":515},{"City":"Nice","Country":"FR","Pop":340}]');
  WriteText(Xm,
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<rows>'#10 +
    ' <row City="Berlin" Country="DE" Pop="3600"/>'#10 +
    ' <row City="Munich" Country="DE" Pop="1500"/>'#10 +
    ' <row City="Hamburg" Country="DE" Pop="1900"/>'#10 +
    '</rows>'#10);

  Xml :=
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="JsonCities" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="j" provider="json" conn="' + Jsn + '" query=""/></datasources>'#10 +
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
  if not RunReport('json', Xml) then begin gRpt.DeleteEngine; gPdf.Free; Halt(0); end;

  Xml :=
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="XmlCities" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="x" provider="xml" conn="' + Xm + '" query="rows/row"/></datasources>'#10 +
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
  if not RunReport('xml', Xml) then begin gRpt.DeleteEngine; gPdf.Free; Halt(0); end;

  gRpt.DeleteEngine;
  gPdf.Free;
end.

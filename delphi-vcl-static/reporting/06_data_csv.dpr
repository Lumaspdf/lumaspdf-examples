program data_csv;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Port of examples\c\reporting\06_data_csv.c -- CSV data provider.
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

function BootEngine(out Pdf: TLumasPDFCore; out Rpt: TLumasPDFReportEngineCore): Boolean;
var Eng: TRPT;
begin
  Result := False;
  Pdf := TLumasPDFCore.Create;
  Pdf.SetLicenseKey(PAnsiChar(PDF_DEMO_KEY));
  Pdf.RptSetRptLicenseKeyA(PAnsiChar(RPT_DEMO_KEY));
  Eng := Pdf.RptCreateEngineA(nil);
  if Eng = nil then begin Writeln('rptCreateEngine failed:'); DumpRptError(nil); Exit; end;
  Rpt := TLumasPDFReportEngineCore.Create(Eng);
  Result := True;
end;

var
  Pdf: TLumasPDFCore; Rpt: TLumasPDFReportEngineCore; Job: TLumasPDFReportJobCore;
  Lrpt, Csv, OutPdf, OutCsv, OutTxt, Xml: AnsiString;
begin
  Lrpt := '06_data.lrpt'; Csv := '06_data.csv'; OutPdf := '06_data.pdf';
  OutCsv := '06_data_out.csv'; OutTxt := '06_data.txt';

  if not BootEngine(Pdf, Rpt) then Halt(1);

  WriteText(Csv,
    'Region,Product,Qty,Price'#10 +
    'North,Widget,10,2.50'#10 +
    'North,Gadget,4,9.99'#10 +
    'South,Widget,7,2.50'#10 +
    'South,Sprocket,20,1.25'#10 +
    'East,Gadget,3,9.99'#10 +
    'West,Sprocket,15,1.25'#10);

  Xml :=
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="CsvSales" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <datasources><datasource alias="d" provider="csv" conn="' + Csv + '"/></datasources>'#10 +
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
  WriteText(Lrpt, Xml);

  Job := TLumasPDFReportJobCore.Create(Rpt.OpenReportA(PAnsiChar(Lrpt)));
  if Job.Handle = nil then begin Writeln('open failed'); DumpRptError(Rpt.Handle); Halt(2); end;
  if not Job.Render then begin Writeln('render failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Halt(3); end;
  Writeln(Format('rendered %d page(s)', [Job.GetPageCount]));
  if not Job.ExportA(RPT_EXP_PDF, PAnsiChar(OutPdf)) then begin Writeln('pdf export failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Halt(4); end;
  if not Job.ExportA(RPT_EXP_CSV, PAnsiChar(OutCsv)) then begin Writeln('csv export failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Halt(5); end;
  if not Job.ExportA(RPT_EXP_TEXT, PAnsiChar(OutTxt)) then begin Writeln('text export failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Halt(6); end;
  Writeln('wrote ' + string(OutPdf));
  Writeln('wrote ' + string(OutCsv));
  Writeln('wrote ' + string(OutTxt));
  Job.CloseReport;

  Rpt.DeleteEngine;
  Pdf.Free;
end.

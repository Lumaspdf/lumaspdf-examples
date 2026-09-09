program elements;
// Delphi OO example -- LumasPdfOO wrapper (TPDF/TPDFReport/TPDFReportJob).
// Port of examples\c\reporting\05_elements.c -- every element kind.
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

var
  Bmp: array[0 .. 54 + 192 - 1] of Byte;
  Bi: Integer;

procedure PutB(V: Integer); begin Bmp[Bi] := Byte(V and $FF); Inc(Bi); end;
procedure PutW(V: Integer); begin PutB(V and $FF); PutB((V shr 8) and $FF); end;
procedure PutD(V: Integer); begin PutB(V and $FF); PutB((V shr 8) and $FF); PutB((V shr 16) and $FF); PutB((V shr 24) and $FF); end;

procedure WriteBmp8x8(const Path: string);
var X, Y: Integer; FS: TFileStream;
begin
  Bi := 0;
  PutB(Ord('B')); PutB(Ord('M'));
  PutD(54 + 192);
  PutD(0);
  PutD(54);
  PutD(40);
  PutD(8); PutD(8);
  PutW(1);
  PutW(24);
  PutD(0);
  PutD(192);
  PutD(2835); PutD(2835);
  PutD(0); PutD(0);
  for Y := 0 to 7 do
    for X := 0 to 7 do
      if ((X + Y) and 1) = 0 then begin PutB(0); PutB(0); PutB(255); end
      else begin PutB(255); PutB(0); PutB(0); end;
  FS := TFileStream.Create(Path, fmCreate);
  try FS.WriteBuffer(Bmp[0], SizeOf(Bmp)); finally FS.Free; end;
end;

var
  Pdf: TPDF; Rpt: TPDFReport; Job: TPDFReportJob;
  Lrpt, Sub, Img, OutPdf, Xml, SubXml: AnsiString;
begin
  Lrpt := '05_elements.lrpt'; Sub := '05_sub.lrpt'; Img := '05_img.bmp'; OutPdf := '05_elements.pdf';

  if not BootEngine(Pdf, Rpt) then Halt(1);

  SubXml :=
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Sub" tagLangVersion="1">'#10 +
    ' <page width="70" height="30" marginLeft="1" marginTop="1" marginRight="1" marginBottom="1"/>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="sh" height="10">'#10 +
    '   <text name="st" x="0" y="0" w="66" h="6" fontSize="8">Subreport content here.</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;
  WriteText(Sub, SubXml);
  WriteBmp8x8(string(Img));

  Xml :=
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Elements" tagLangVersion="1">'#10 +
    ' <page width="210" height="297" marginLeft="15" marginTop="15" marginRight="15" marginBottom="15"/>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="rh" height="150">'#10 +
    '   <text name="title" x="0" y="0" w="180" h="10" fontSize="18" hAlign="center">Every Element Kind</text>'#10 +
    '   <text name="note"  x="0" y="12" w="180" h="6" fontSize="9" hAlign="center">text / line / shape / image / barcode / subreport</text>'#10 +
    '   <line  name="rule" x="0" y="20" w="180" h="0.3" toX="180" toY="0"/>'#10 +
    '   <shape name="rect" x="0"  y="26" w="55" h="22" shape="0"/>'#10 +
    '   <shape name="rrct" x="63" y="26" w="55" h="22" shape="1"/>'#10 +
    '   <shape name="elps" x="126" y="26" w="55" h="22" shape="2"/>'#10 +
    '   <text name="l1" x="0"   y="49" w="55" h="5" fontSize="7" hAlign="center">shape=0 rect</text>'#10 +
    '   <text name="l2" x="63"  y="49" w="55" h="5" fontSize="7" hAlign="center">shape=1 roundrect</text>'#10 +
    '   <text name="l3" x="126" y="49" w="55" h="5" fontSize="7" hAlign="center">shape=2 ellipse</text>'#10 +
    '   <image name="pic" x="0" y="58" w="24" h="24" source="' + Img + '" stretch="1"/>'#10 +
    '   <text name="il" x="0" y="83" w="40" h="5" fontSize="7">8x8 BMP image</text>'#10 +
    '   <barcode name="qr"  x="40"  y="58" w="24" h="24" type="0" text="QR:LumasReport"/>'#10 +
    '   <barcode name="pdf" x="70"  y="58" w="40" h="24" type="1" text="PDF417-DATA-001"/>'#10 +
    '   <barcode name="dm"  x="116" y="58" w="24" h="24" type="2" text="DataMatrix99"/>'#10 +
    '   <barcode name="az"  x="146" y="58" w="24" h="24" type="3" text="AZTEC-XYZ"/>'#10 +
    '   <text name="bl" x="40" y="83" w="140" h="5" fontSize="7">barcodes: QR / PDF417 / DataMatrix / Aztec</text>'#10 +
    '   <subreport name="sub" x="0" y="92" w="90" h="30" ref="05_sub.lrpt"/>'#10 +
    '   <text name="sl" x="0" y="123" w="120" h="5" fontSize="7">^ subreport (05_sub.lrpt) merged above</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;
  WriteText(Lrpt, Xml);

  Job := TPDFReportJob.Create(Rpt.OpenReportA(PAnsiChar(Lrpt)));
  if Job.Handle = nil then begin Writeln('open failed'); DumpRptError(Rpt.Handle); Halt(2); end;
  if not Job.Render then begin Writeln('render failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Halt(3); end;
  Writeln(Format('rendered %d page(s)', [Job.GetPageCount]));
  if not Job.ExportA(RPT_EXP_PDF, PAnsiChar(OutPdf)) then begin Writeln('export failed'); DumpRptError(Rpt.Handle); Job.CloseReport; Halt(4); end;
  Writeln('wrote ' + string(OutPdf));
  Job.CloseReport;

  Rpt.DeleteEngine;
  Pdf.Free;
end.

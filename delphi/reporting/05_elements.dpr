program elements_report;
// ===========================================================================
//  LumasReport example 05 -- Every element kind
//  A single report band that exercises the full element vocabulary:
//    <text> (x2), <line>, <shape> (0=rect, 1=roundrect, 2=ellipse),
//    <image> (a hand-built 8x8 24-bit BMP written to disk), <barcode>
//    (0=QR, 1=PDF417, 2=DataMatrix, 3=Aztec) and a <subreport> that pulls
//    in a second .lrpt (05_sub.lrpt, one text band).
//  Surface covered: TRptElementKind + TRptShapeKind + TRptBarcodeKind + subreport.
// ===========================================================================
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LumasPdf;

{$I _shared.inc}

// Build a minimal but valid 8x8 24-bit BMP as a raw byte string (red/blue
// checkerboard). Nested procs append little-endian bytes to the accumulator.
function MakeBmp8x8: AnsiString;
var
  Sb: AnsiString;
  X, Y: Integer;

  procedure B(V: Byte);
  begin Sb := Sb + AnsiChar(V); end;

  procedure W(V: Word);
  begin B(V and $FF); B((V shr 8) and $FF); end;

  procedure D(V: Cardinal);
  begin B(V and $FF); B((V shr 8) and $FF); B((V shr 16) and $FF); B((V shr 24) and $FF); end;

begin
  Sb := '';
  // BITMAPFILEHEADER (14 bytes)
  B(Ord('B')); B(Ord('M'));
  D(54 + 192);          // total file size (header 54 + pixels 192)
  D(0);                 // reserved
  D(54);                // offset to pixel data
  // BITMAPINFOHEADER (40 bytes)
  D(40);                // header size
  D(8); D(8);           // width, height
  W(1);                 // planes
  W(24);                // bits per pixel
  D(0);                 // BI_RGB (no compression)
  D(192);               // image byte size (8 rows * 24 bytes)
  D(2835); D(2835);     // 72 DPI in pixels/metre
  D(0); D(0);           // palette entries used / important
  // pixel data, bottom-up, BGR; each 24-byte row is already 4-byte aligned
  for Y := 0 to 7 do
    for X := 0 to 7 do
      if ((X + Y) and 1) = 0 then
        begin B(0); B(0); B(255); end     // red
      else
        begin B(255); B(0); B(0); end;    // blue
  Result := Sb;
end;

const
  // Second report pulled in by the <subreport> element.
  SUB_XML: AnsiString =
    '<?xml version="1.0" encoding="UTF-8"?>'#10 +
    '<report name="Sub" tagLangVersion="1">'#10 +
    ' <page width="70" height="30" marginLeft="1" marginTop="1" marginRight="1" marginBottom="1"/>'#10 +
    ' <bands>'#10 +
    '  <band kind="reportheader" name="sh" height="10">'#10 +
    '   <text name="st" x="0" y="0" w="66" h="6" fontSize="8">Subreport content here.</text>'#10 +
    '  </band>'#10 +
    ' </bands>'#10 +
    '</report>'#10;

  // Main report, split around the <image source="..."> value so the absolute
  // BMP path can be concatenated in without any string-type juggling.
  MAIN_A: AnsiString =
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
    '   <image name="pic" x="0" y="58" w="24" h="24" source="';
  MAIN_B: AnsiString =
    '" stretch="1"/>'#10 +
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

var
  Pdf: PPDF; Eng: TRPT; Job: TRPTJOB;
  Dir, Lrpt, Sub, Img, OutPdf, Xml: AnsiString;
begin
  if not BootEngine(Pdf, Eng) then Halt(1);
  try
    Dir    := AnsiString(IncludeTrailingPathDelimiter(GetCurrentDir));
    Lrpt   := Dir + '05_elements.lrpt';
    Sub    := Dir + '05_sub.lrpt';
    Img    := Dir + '05_img.bmp';
    OutPdf := Dir + '05_elements.pdf';

    WriteText(Sub, SUB_XML);
    WriteText(Img, MakeBmp8x8);
    Xml := MAIN_A + Img + MAIN_B;   // backslashes are fine in XML attrs
    WriteText(Lrpt, Xml);

    Job := rptOpenReportA(Eng, PAnsiChar(Lrpt));
    if Job = nil then begin Writeln('open failed'); DumpRptError(Eng); Halt(2); end;
    try
      if not rptRender(Job) then begin Writeln('render failed'); DumpRptError(Eng); Halt(3); end;
      Writeln(Format('rendered %d page(s)', [rptGetPageCount(Job)]));
      if not rptExportA(Job, RPT_EXP_PDF, PAnsiChar(OutPdf)) then
        begin Writeln('export failed'); DumpRptError(Eng); Halt(4); end;
      Writeln('wrote ' + string(OutPdf));
    finally
      rptCloseReport(Job);
    end;
  finally
    rptDeleteEngine(Eng);
    pdfDeletePDF(Pdf);
  end;
end.

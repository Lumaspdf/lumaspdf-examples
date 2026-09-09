program table_layout;
{$APPTYPE CONSOLE}
(*
  LumasPDF XFA "flavor tour" example 7/10 -- TABLE LAYOUT
  (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 5.3).

  Mirrors cpp\tools\xfa_render_test.dpr's driver shape exactly (same
  pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
  pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile ->
  pdfDeletePDF export sequence through the real LumasPdf.dll), narrowed to
  this one example's own fixture (07_table_layout.xdp) instead of the
  7-fixture batch xfa_render_test.dpr drives.

  This program does NOT rebuild LumasPdf.dll -- it only links against the
  wrapper unit (wrappers\delphi\LumasPdf.pas) and loads the ALREADY-BUILT
  DLL at runtime (copied next to this exe, same convention every
  cpp\tools\build_xfa_*.bat script and examples\delphi\hello_world already
  use -- Windows DLL search order checks the exe's own directory first).

  What layout="table" demonstrates here: "ProductTable" is a 4-column
  (Product/Price/Stock/Rating) subform with columnWidths="216pt 108pt
  108pt 108pt" and 6 layout="row" children (1 header + 5 data rows) --
  Lumas.Pdf.Xfa.Layout.Table.pas computes the column/row geometry, and
  Lumas.Pdf.Xfa.Render.pas's RenderTableBox/RenderTableCell hand that
  geometry to the real TLumasPdfDoc.DrawTable primitive (not a hand-rolled
  per-field draw loop) -- see that unit's own header comment for the full
  delegation contract. Each column authors a DIFFERENT <para hAlign>
  (Product=left, Price=right, Stock=center, Rating=right, on every row,
  not just the header) specifically to exercise the real bug fix found and
  fixed earlier this session: RenderTableCell now actually reads
  CellBox.Src.ParaNode's hAlign attribute (previously every cell, no
  matter its authored alignment, drew flush-left).
*)
uses
  System.SysUtils,
  System.IOUtils,
  Lumas.Pdf.Xml in '..\..\..\..\src\Lumas.Pdf.Xml.pas',
  LumasPdf in '..\..\..\..\wrappers\delphi\LumasPdf.pas';

function ExtractPacket(XdpRoot: TXmlNode; const LocalName: string): RawByteString;
var
  Node: TXmlNode;
  S: string;
begin
  Result := '';
  Node := XdpRoot.FindChild(LocalName);
  if Node = nil then Exit;
  S := XmlSerialize(Node);
  Result := RawByteString(UTF8Encode(S));
end;

function RenderFixture(const XdpPath, OutPdfPath: string): Integer;
var
  Raw: string;
  XdpRoot: TXmlNode;
  TemplateBuf, DatasetsBuf: RawByteString;
  PDF: PPDF;
  Idx: Integer;
begin
  Result := -100;
  Writeln('=== ', ExtractFileName(XdpPath), ' -> ', ExtractFileName(OutPdfPath), ' ===');
  if not FileExists(XdpPath) then
  begin
    Writeln('FILE-NOT-FOUND: ', XdpPath);
    Exit;
  end;
  Raw := TFile.ReadAllText(XdpPath, TEncoding.UTF8);
  XdpRoot := XmlParse(Raw);
  if XdpRoot = nil then
  begin
    Writeln('XML-PARSE-FAIL');
    Exit;
  end;
  try
    TemplateBuf := ExtractPacket(XdpRoot, 'template');
    DatasetsBuf := ExtractPacket(XdpRoot, 'datasets');
    if TemplateBuf = '' then
    begin
      Writeln('NO-TEMPLATE-PACKET');
      Exit;
    end;
    Writeln('template packet bytes: ', Length(TemplateBuf));
    Writeln('datasets packet bytes: ', Length(DatasetsBuf));

    PDF := pdfNewPDF;
    if PDF = nil then
    begin
      Writeln('pdfNewPDF FAILED');
      Exit;
    end;
    try
      if not pdfCreateNewPDFA(PDF, PAnsiChar(AnsiString(OutPdfPath))) then
      begin
        Writeln('pdfCreateNewPDFA FAILED');
        Exit;
      end;

      Idx := pdfCreateXFAStreamA(PDF, 'template', @TemplateBuf[1], Length(TemplateBuf));
      Writeln('pdfCreateXFAStreamA(template) -> index ', Idx);
      if Idx < 0 then
      begin
        Writeln('pdfCreateXFAStreamA(template) FAILED');
        Exit;
      end;

      if DatasetsBuf <> '' then
      begin
        Idx := pdfCreateXFAStreamA(PDF, 'datasets', @DatasetsBuf[1], Length(DatasetsBuf));
        Writeln('pdfCreateXFAStreamA(datasets) -> index ', Idx);
        if Idx < 0 then
        begin
          Writeln('pdfCreateXFAStreamA(datasets) FAILED');
          Exit;
        end;
      end
      else
        Writeln('(no datasets packet found in this fixture -- template-only render)');

      Result := pdfRenderXFAForm(PDF);
      Writeln('pdfRenderXFAForm -> ', Result);
      if Result < 0 then
      begin
        Writeln('pdfRenderXFAForm FAILED, code ', Result);
        Exit;
      end;

      if not pdfCloseFile(PDF) then
      begin
        Writeln('pdfCloseFile FAILED');
        Result := -101;
        Exit;
      end;
      Writeln('OK: wrote ', OutPdfPath);
    finally
      pdfDeletePDF(PDF);
    end;
  finally
    XdpRoot.Free;
  end;
end;

var
  R1: Integer;
begin
  R1 := RenderFixture(
    ExtractFilePath(ParamStr(0)) + '07_table_layout.xdp',
    ExtractFilePath(ParamStr(0)) + '07_table_layout.pdf');
  Writeln('RESULT|07_table_layout=', R1);
end.

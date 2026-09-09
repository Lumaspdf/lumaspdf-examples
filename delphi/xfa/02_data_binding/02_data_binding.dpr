program _02_data_binding;
{$APPTYPE CONSOLE}
(*
  LumasPDF XFA "flavor tour" example 2 of 10 -- DATA BINDING
  (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 6: implicit by-name binding AND
  explicit <bind match="dataRef" ref="..."/> SOM path binding against a
  datasets packet).

  Mirrors cpp\tools\xfa_render_test.dpr EXACTLY (same DLL boundary, same
  export call sequence, same packet-extraction approach via Lumas.Pdf.Xml) --
  this driver only swaps in this example's own fixture and adds a bit of
  human-readable narration since it's a standalone "flavor tour" example, not
  a differential-gate driver:

    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile

  Does NOT touch/rebuild LumasPdf.dll -- links against the already-built,
  gate-green engine DLL exactly as it stands (copied next to this exe by
  build_02_data_binding.bat, same copy-DLL-next-to-exe convention every
  examples\* driver in this project follows).
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
  R: Integer;
begin
  Writeln('LumasPDF XFA flavor tour -- example 2/10: Data Binding');
  Writeln('(implicit by-name + explicit dataRef SOM path + match=none literal)');
  Writeln('');
  R := RenderFixture(
    ExtractFilePath(ParamStr(0)) + '02_data_binding.xdp',
    ExtractFilePath(ParamStr(0)) + '02_data_binding.render.pdf');
  Writeln('');
  Writeln('RESULT|02_data_binding=', R);
end.

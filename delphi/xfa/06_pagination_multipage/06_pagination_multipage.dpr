program pagination_multipage;
{$APPTYPE CONSOLE}
(*
  LumasPDF XFA dynamic engine "flavor tour" example 6 of 10 --
  MULTI-PAGE PAGINATION (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 5.4:
  pageSet/pageArea/contentArea, forced overflow across multiple pages,
  leader/trailer "continued" subforms).

  Mirrors cpp\tools\xfa_render_test.dpr's own real-DLL loading sequence
  exactly (this is a standalone driver, NOT a rebuild of LumasPdf.dll --
  it links only against the already-built wrappers\delphi\LumasPdf.pas and
  the already-built LumasPdf.dll):

    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
    pdfCreateXFAStreamA('datasets',...) -> pdfXFAFormPageCount (pre-flight,
    CheckPageCount) -> pdfRenderXFAForm -> pdfCloseFile -> pdfDeletePDF

  Packet extraction follows xfa_render_test.dpr's exact convention: this
  fixture bundles BOTH <template> and <xfa:datasets> under one <xdp:xdp>
  root, and AddXFAStream/pdfCreateXFAStreamA expect each packet's OWN root
  element bytes, so this driver parses the .xdp once via Lumas.Pdf.Xml,
  FindChild's out the <template>/<datasets> subtrees, and re-serializes
  each into its own standalone buffer before handing it to
  pdfCreateXFAStreamA.

  CheckPageCount=4: hand-derived in README.md from 06_pagination_multipage.xdp's
  own geometry (contentArea 400pt tall, row/leader/trailer h=20pt each, 70
  <Line> records) using the REAL, already-implemented, gate-green pagination
  algorithm documented in XFA_FIXTURE_EXPECTATIONS.md sec 12.1 (trailer
  height reserved on EVERY page's capacity math unconditionally, including
  the true last page; leader height reserved on every page except the
  first) -- NOT the superseded "lookahead" policy sec 0.3/sec 6 originally
  described (both policies agree for the smaller fx06 fixture, but diverge
  at this example's larger scale the same way sec 12.1's fx13 companion
  fixture demonstrates). This driver calls pdfXFAFormPageCount BEFORE
  pdfRenderXFAForm and asserts the two agree, exactly like
  xfa_render_test.dpr's own fx06 CheckPageCount=3 assertion.
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

// CheckPageCount>=0: also calls the pdfXFAFormPageCount pre-flight export
// BEFORE rendering, asserting it matches CheckPageCount exactly -- same
// convention as xfa_render_test.dpr's own RenderFixture.
function RenderExample(const XdpPath, OutPdfPath: string; CheckPageCount: Integer = -1): Integer;
var
  Raw: string;
  XdpRoot: TXmlNode;
  TemplateBuf, DatasetsBuf: RawByteString;
  PDF: PPDF;
  Idx: Integer;
  Pre: Integer;
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

      if CheckPageCount >= 0 then
      begin
        Pre := pdfXFAFormPageCount(PDF);
        Writeln('pdfXFAFormPageCount (pre-flight, before any AppendPage) -> ', Pre);
        if Pre <> CheckPageCount then
        begin
          Writeln('PAGECOUNT-MISMATCH: expected ', CheckPageCount, ' got ', Pre);
          Result := -102;
          Exit;
        end;
      end;

      Result := pdfRenderXFAForm(PDF);
      Writeln('pdfRenderXFAForm -> ', Result);
      if Result < 0 then
      begin
        Writeln('pdfRenderXFAForm FAILED, code ', Result);
        Exit;
      end;
      if (CheckPageCount >= 0) and (Result <> CheckPageCount) then
      begin
        Writeln('RENDER-PAGECOUNT-MISMATCH: pre-flight said ', CheckPageCount,
          ' but render produced ', Result);
        Result := -103;
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
  R := RenderExample(
    ExtractFilePath(ParamStr(0)) + '06_pagination_multipage.xdp',
    ExtractFilePath(ParamStr(0)) + '06_pagination_multipage.pdf', 4);
  Writeln('RESULT|06_pagination_multipage=', R);
end.

program picture_clause_formatting;
{$APPTYPE CONSOLE}
(*
  LumasPDF XFA dynamic engine "flavor tour" example 8 of 10 -- PICTURE-CLAUSE
  FORMATTING (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 6.4).

  Mirrors cpp\tools\xfa_render_test.dpr / examples\delphi\xfa\04_flow_layout's
  own real-DLL loading sequence exactly (this is a standalone driver, NOT a
  rebuild of LumasPdf.dll -- it links only against the already-built
  wrappers\delphi\LumasPdf.pas and the already-built LumasPdf.dll):

    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
    -> pdfDeletePDF

  Packet extraction follows xfa_render_test.dpr's exact convention: this
  fixture bundles BOTH <template> and <xfa:datasets> under one <xdp:xdp>
  root, and AddXFAStream/pdfCreateXFAStreamA expect each packet's OWN root
  element bytes, so this driver parses the .xdp once via Lumas.Pdf.Xml,
  FindChild's out the <template>/<datasets> subtrees, and re-serializes
  each into its own standalone buffer before handing it to
  pdfCreateXFAStreamA.
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

      // Phase-6 config gate defaults to enabled (Lumas.Pdf.Document.pas
      // FXFAScriptEnabled := True in Create), but this driver sets it
      // explicitly anyway so GrandTotalField's <calculate> script is
      // guaranteed to run regardless of that default ever changing --
      // this example's whole point is the calculate-then-format pipeline,
      // so it does not rely on an implicit default for that.
      Writeln('pdfSetXFAScriptEnabled(1) -> ', pdfSetXFAScriptEnabled(PDF, 1));

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
  R := RenderFixture(
    ExtractFilePath(ParamStr(0)) + '08_picture_clause_formatting.xdp',
    ExtractFilePath(ParamStr(0)) + '08_picture_clause_formatting.pdf');
  Writeln('RESULT|08_picture_clause_formatting=', R);
end.

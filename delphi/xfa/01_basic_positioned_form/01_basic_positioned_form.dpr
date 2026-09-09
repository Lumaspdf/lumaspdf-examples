program basic_positioned_form;
{$APPTYPE CONSOLE}
(*
  "Flavor tour" example 1 of 10: POSITIONED LAYOUT (plan sec 5.1 -- static
  field positioning, no flow/occur/pagination).

  This driver mirrors cpp\tools\xfa_render_test.dpr's own render-driver
  pattern EXACTLY (same packet-extraction helper, same call sequence, same
  error handling) -- it is NOT a new pipeline, just that same proven
  approach pointed at this tour's own .xdp instead of the engine's internal
  fx* fixtures. It renders 01_basic_positioned_form.xdp (a realistic
  "Employee Information" HR form, five statically-positioned/data-bound
  fields + decorative draws, single page, layout="position" throughout)
  through the REAL, already-built LumasPdf.dll:

    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile

  This driver does not rebuild or relink the engine DLL in any way -- it
  only links, at compile time, against the existing public wrapper unit
  wrappers\delphi\LumasPdf.pas, and at run time loads whatever
  E:\LUMASPDFSDK\LumasPdf.dll is already sitting on disk.
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

function RenderExample(const XdpPath, OutPdfPath: string): Integer;
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
        Writeln('(no datasets packet found -- template-only render)');

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
  R1 := RenderExample(
    ExtractFilePath(ParamStr(0)) + '01_basic_positioned_form.xdp',
    ExtractFilePath(ParamStr(0)) + 'output.pdf');
  Writeln('RESULT|01_basic_positioned_form=', R1);
end.

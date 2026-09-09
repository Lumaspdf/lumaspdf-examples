program pagination_multipage_vcl;
{$APPTYPE CONSOLE}
(*
  VCL-static-component-flavour port of
  examples\delphi\xfa\06_pagination_multipage (flavor-tour example 6 of
  10: full multi-page pagination -- pageSet/pageArea/contentArea, forced
  overflow of a 70-row "Invoice Line Items" table across 4 pages, and
  leader/trailer "continued" banner subforms via
  <overflow leader=... trailer=...>).

  PURE VCL static example -- the engine is linked INTO this exe
  (LUMAS_STATIC, runtime packages OFF). NO LumasPdf.dll at run time.
  Lumas.Pdf.Wrap.Static MUST be the first unit in the uses clause. The XFA
  pipeline is driven through TLumasPDFCore (Lumas.Pdf.Wrap.Core) -- the flat
  pdfXxx(Handle,...) API re-exposed as methods -- same pattern as
  examples\vcl_static\smoke_test / acroform\check_boxes.

  No XML parsing here: 06_pagination_multipage.template.xml / .datasets.xml
  are the already pre-split raw packet bytes (produced once by the
  flat-Delphi tour's split_xfa_packets tool) sitting next to this .dpr.

  Call sequence (matches the flat original's own, incl. the pre-flight page
  count check): TLumasPDFCore.Create -> pdf.CreateNewPDFA ->
  pdf.CreateXFAStreamA('template',...) -> pdf.CreateXFAStreamA('datasets',...) ->
  pdf.XFAFormPageCount (pre-flight, CheckPageCount=4) -> pdf.RenderXFAForm ->
  pdf.CloseFile -> pdf.Free

  CheckPageCount=4 is hand-derived in the flat original's README.md from
  this fixture's own geometry (contentArea 400pt tall, row/leader/trailer
  h=20pt each, 70 <Line> records) -- unchanged by this port, since the
  fixture and the engine's pagination algorithm are identical; only the
  calling surface (component methods instead of flat pdfXxx(Handle,...)
  calls) differs.
*)
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  System.IOUtils,
  Lumas.Pdf.Wrap.Core;

function ReadPacket(const Path: string): TBytes;
begin
  if FileExists(Path) then
    Result := TFile.ReadAllBytes(Path)
  else
    Result := nil;
end;

// CheckPageCount>=0: also calls the XFAFormPageCount pre-flight method
// BEFORE rendering, asserting it matches CheckPageCount exactly -- same
// convention as the flat-Delphi original's own RenderExample.
function RenderExample(const TemplatePath, DatasetsPath, OutPdfPath: string;
  CheckPageCount: Integer = -1): Integer;
var
  TemplateBuf, DatasetsBuf: TBytes;
  pdf: TLumasPDFCore;
  Idx, Pre: Integer;
begin
  Result := -100;
  Writeln('=== ', ExtractFileName(TemplatePath), ' + ', ExtractFileName(DatasetsPath),
    ' -> ', ExtractFileName(OutPdfPath), ' ===');
  if not FileExists(TemplatePath) then
  begin
    Writeln('FILE-NOT-FOUND: ', TemplatePath);
    Exit;
  end;
  TemplateBuf := ReadPacket(TemplatePath);
  DatasetsBuf := ReadPacket(DatasetsPath);
  Writeln('template packet bytes: ', Length(TemplateBuf));
  Writeln('datasets packet bytes: ', Length(DatasetsBuf));

  pdf := TLumasPDFCore.Create;
  try
    if not pdf.CreateNewPDFA(PAnsiChar(AnsiString(OutPdfPath))) then
    begin
      Writeln('CreateNewPDFA FAILED');
      Exit;
    end;

    Idx := pdf.CreateXFAStreamA('template', @TemplateBuf[0], Length(TemplateBuf));
    Writeln('CreateXFAStreamA(template) -> index ', Idx);
    if Idx < 0 then
    begin
      Writeln('CreateXFAStreamA(template) FAILED');
      Exit;
    end;

    if Length(DatasetsBuf) > 0 then
    begin
      Idx := pdf.CreateXFAStreamA('datasets', @DatasetsBuf[0], Length(DatasetsBuf));
      Writeln('CreateXFAStreamA(datasets) -> index ', Idx);
      if Idx < 0 then
      begin
        Writeln('CreateXFAStreamA(datasets) FAILED');
        Exit;
      end;
    end
    else
      Writeln('(no datasets packet found in this fixture -- template-only render)');

    if CheckPageCount >= 0 then
    begin
      Pre := pdf.XFAFormPageCount;
      Writeln('XFAFormPageCount (pre-flight, before any AppendPage) -> ', Pre);
      if Pre <> CheckPageCount then
      begin
        Writeln('PAGECOUNT-MISMATCH: expected ', CheckPageCount, ' got ', Pre);
        Result := -102;
        Exit;
      end;
    end;

    Result := pdf.RenderXFAForm;
    Writeln('RenderXFAForm -> ', Result);
    if Result < 0 then
    begin
      Writeln('RenderXFAForm FAILED, code ', Result);
      Exit;
    end;
    if (CheckPageCount >= 0) and (Result <> CheckPageCount) then
    begin
      Writeln('RENDER-PAGECOUNT-MISMATCH: pre-flight said ', CheckPageCount,
        ' but render produced ', Result);
      Result := -103;
      Exit;
    end;

    if not pdf.CloseFile then
    begin
      Writeln('CloseFile FAILED');
      Result := -101;
      Exit;
    end;
    Writeln('OK: wrote ', OutPdfPath);
  finally
    pdf.Free; // = pdfDeletePDF
  end;
end;

var
  ExeDir: string;
  R: Integer;
begin
  ExeDir := ExtractFilePath(ParamStr(0));
  R := RenderExample(
    ExeDir + '06_pagination_multipage.template.xml',
    ExeDir + '06_pagination_multipage.datasets.xml',
    ExeDir + 'output.pdf', 4);
  Writeln('RESULT|06_pagination_multipage=', R);
end.

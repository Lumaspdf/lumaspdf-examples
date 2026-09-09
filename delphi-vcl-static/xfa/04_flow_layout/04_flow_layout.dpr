program flow_layout_vcl;
{$APPTYPE CONSOLE}
(*
  VCL-static-component-flavour port of examples\delphi\xfa\04_flow_layout
  (flavor-tour example 4 of 10: flow layout -- layout="tb" vertical
  stacking (TermsPanel, 6 clauses) and layout="lr-tb" left-to-right
  wrapping (SkillsPanel, 9 tags, wraps across 3 lines) -- no fixed x/y on
  the flowed children).

  PURE VCL static example -- the engine is linked INTO this exe
  (LUMAS_STATIC, runtime packages OFF). NO LumasPdf.dll at run time.
  Lumas.Pdf.Wrap.Static MUST be the first unit in the uses clause. The XFA
  pipeline is driven through TLumasPDFCore (Lumas.Pdf.Wrap.Core) -- the flat
  pdfXxx(Handle,...) API re-exposed as methods -- same pattern as
  examples\vcl_static\smoke_test / acroform\check_boxes.

  No XML parsing here: 04_flow_layout.template.xml / .datasets.xml are the
  already pre-split raw packet bytes (produced once by the flat-Delphi
  tour's split_xfa_packets tool) sitting next to this .dpr.

  Call sequence: TLumasPDFCore.Create -> pdf.CreateNewPDFA ->
  pdf.CreateXFAStreamA('template',...) -> pdf.CreateXFAStreamA('datasets',...) ->
  pdf.RenderXFAForm -> pdf.CloseFile -> pdf.Free
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

function RenderExample(const TemplatePath, DatasetsPath, OutPdfPath: string): Integer;
var
  TemplateBuf, DatasetsBuf: TBytes;
  pdf: TLumasPDFCore;
  Idx: Integer;
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
      Writeln('(no datasets packet found -- template-only render)');

    Result := pdf.RenderXFAForm;
    Writeln('RenderXFAForm -> ', Result);
    if Result < 0 then
    begin
      Writeln('RenderXFAForm FAILED, code ', Result);
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
  R1: Integer;
begin
  ExeDir := ExtractFilePath(ParamStr(0));
  R1 := RenderExample(
    ExeDir + '04_flow_layout.template.xml',
    ExeDir + '04_flow_layout.datasets.xml',
    ExeDir + 'output.pdf');
  Writeln('RESULT|04_flow_layout=', R1);
end.

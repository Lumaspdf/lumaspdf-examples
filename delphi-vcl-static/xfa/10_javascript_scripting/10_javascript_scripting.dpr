program javascript_scripting_vcl;
{$APPTYPE CONSOLE}
(*
  VCL-static-component-flavour port of
  examples\delphi\xfa\10_javascript_scripting (flavor-tour example 10 of
  10: <script contentType="application/x-javascript"> calculate scripts --
  this.rawValue getter/setter, xfa.resolveNode(path).rawValue cross-field
  references, and per-instance JS on occur-repeated rows -- via BESEN,
  already embedded in this Delphi engine, wired into the SAME
  pdfRenderXFAForm pipeline FormCalc already uses (IXfaScriptHost seam). No
  new export was needed for JS scripting, so this port needed none either.

  PURE VCL static example -- the engine is linked INTO this exe
  (LUMAS_STATIC, runtime packages OFF). NO LumasPdf.dll at run time.
  Lumas.Pdf.Wrap.Static MUST be the first unit in the uses clause. The XFA
  pipeline is driven through TLumasPDFCore (Lumas.Pdf.Wrap.Core) -- the flat
  pdfXxx(Handle,...) API re-exposed as methods -- same pattern as
  examples\vcl_static\smoke_test / acroform\check_boxes.

  No XML parsing here: 10_javascript_scripting.template.xml / .datasets.xml
  are the already pre-split raw packet bytes (produced once by the
  flat-Delphi tour's split_xfa_packets tool) sitting next to this .dpr.

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
    Writeln('RenderXFAForm -> ', Result, ' (expected: page count >= 1)');
    if Result < 1 then
    begin
      Writeln('RENDER-FAILED, code ', Result);
      Exit;
    end;

    if not pdf.CloseFile then
    begin
      Writeln('CloseFile FAILED');
      Result := -101;
      Exit;
    end;
    Writeln('Wrote ', OutPdfPath, ' (', Result, ' page(s))');
  finally
    pdf.Free; // = pdfDeletePDF
  end;
end;

var
  ExeDir: string;
  Rc: Integer;
begin
  ExeDir := ExtractFilePath(ParamStr(0));
  Rc := RenderExample(
    ExeDir + '10_javascript_scripting.template.xml',
    ExeDir + '10_javascript_scripting.datasets.xml',
    ExeDir + 'output.pdf');
  if Rc >= 1 then
    Writeln('OK: JavaScript-scripted form rendered, ', Rc, ' page(s). Open output.pdf and confirm:')
  else
    Writeln('FAILED, see errors above.');
  Writeln('  - UnitPriceWithTax  ~= 21.59  (19.99 * 1.08)');
  Writeln('  - OrderSummary      = "Purchase Order PO-1042 for Acme Robotics"');
  Writeln('  - 3 Line rows, Total = Qty*UnitCost per row (50.00 / 90.00 / 89.75)');
end.

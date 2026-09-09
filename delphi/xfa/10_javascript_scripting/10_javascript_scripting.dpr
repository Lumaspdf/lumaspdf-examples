program javascript_scripting;
{$APPTYPE CONSOLE}
(*
  XFA "flavor tour" example 10 of 10 -- JS-as-XFA-script.

  STATUS: VERIFIED 2026-07-24, re-confirmed 2026-07-25 against the fresh
  engine DLL. This driver mirrors the established render pattern from
  cpp\tools\xfa_render_test.dpr (parse .xdp -> extract template/datasets
  packets -> pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA x2 ->
  pdfRenderXFAForm -> pdfCloseFile) -- JS scripting needed no new export,
  plugging into the SAME pdfRenderXFAForm pipeline FormCalc already uses via
  the existing IXfaScriptHost seam. See README.md for the confirmed
  checklist values.

  Scope note: this exercises XFA-scoped JS only (this.rawValue getter/setter
  + xfa.resolveNode(path).rawValue), via BESEN on this Delphi engine. As of
  2026-07-25 the C++ port also has a real JS-as-XFA-script mirror (QuickJS-
  backed, see cpp\src\pdf\xfa_script_js.cpp) with byte-identical output on
  the shared fx21/fx21b fixtures -- both engines are done. Separately, the
  engine's document-level (non-XFA) pdfExecuteJavaScript* JS execution is
  ALSO now real on both engines (Acrobat-style getField/console/AF* form
  functions, via cpp\src\pdf\pdf_js.cpp / Lumas.Pdf.JS.pas) -- a separate
  feature, not exercised by this XFA-scoped example.

  Does NOT rebuild LumasPdf.dll -- links against the existing
  wrappers\delphi\LumasPdf.pas wrapper unit exactly like every other example
  in this "flavor tour".
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
  Idx, Rc: Integer;
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
      end;

      Rc := pdfRenderXFAForm(PDF);
      Writeln('pdfRenderXFAForm -> ', Rc, ' (expected: page count >= 1)');
      if Rc < 1 then
      begin
        Writeln('RENDER-FAILED, code ', Rc);
        Exit;
      end;

      if not pdfCloseFile(PDF) then
      begin
        Writeln('pdfCloseFile FAILED');
        Exit;
      end;
      Writeln('Wrote ', OutPdfPath, ' (', Rc, ' page(s))');
      Result := Rc;
    finally
      pdfDeletePDF(PDF);
    end;
  finally
    XdpRoot.Free;
  end;
end;

var
  ExeDir: string;
  Rc: Integer;
begin
  try
    ExeDir := ExtractFilePath(ParamStr(0));
    Rc := RenderExample(
      ExeDir + '10_javascript_scripting.xdp',
      ExeDir + 'output.pdf');
    if Rc >= 1 then
      Writeln('OK: JavaScript-scripted form rendered, ', Rc, ' page(s). Open output.pdf and confirm:')
    else
      Writeln('FAILED, see errors above.');
    Writeln('  - UnitPriceWithTax  ~= 21.59  (19.99 * 1.08)');
    Writeln('  - OrderSummary      = "Purchase Order PO-1042 for Acme Robotics"');
    Writeln('  - 3 Line rows, Total = Qty*UnitCost per row (50.00 / 90.00 / 89.75)');
    Writeln('  If any of these are wrong or missing, the JS bridge contract in the .xdp');
    Writeln('  needs adjusting to match the FINAL implementation -- see the .xdp header comment.');
  except
    on E: Exception do
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
  end;
end.

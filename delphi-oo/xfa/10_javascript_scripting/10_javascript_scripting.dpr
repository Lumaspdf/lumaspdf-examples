program javascript_scripting;
{$APPTYPE CONSOLE}
(*
  Delphi-OO port of the flat "flavor tour" example 10 of 10 -- JS-as-XFA-
  script. Same fixture/DLL/pipeline as
  examples\delphi\xfa\10_javascript_scripting\10_javascript_scripting.dpr
  (STATUS there: VERIFIED 2026-07-24, re-confirmed 2026-07-25 against the
  fresh engine DLL) -- only the call surface differs: this driver uses the
  class-based OO wrapper (wrappers\delphi\LumasPdfOO.pas's TPDF) instead of
  the flat pdfXxx(Handle,...) functions:

    TPDF.Create          ~ pdfNewPDF
    pdf.CreateNewPDFA     ~ pdfCreateNewPDFA(Handle, ...)
    pdf.CreateXFAStreamA  ~ pdfCreateXFAStreamA(Handle, ...)
    pdf.RenderXFAForm     ~ pdfRenderXFAForm(Handle)
    pdf.CloseFile         ~ pdfCloseFile(Handle)
    TPDF.Free             ~ pdfDeletePDF

  <script contentType="application/x-javascript"> calculate scripts, wired
  minimally and XFA-only into the SAME pdf.RenderXFAForm pipeline FormCalc
  already uses, via the existing IXfaScriptHost seam (BESEN, not QuickJS --
  see Lumas.Pdf.Xfa.Script.JS.pas header). Exercises XFA-scoped JS only
  (this.rawValue getter/setter + xfa.resolveNode(path).rawValue).

  Packet files are PRE-SPLIT (10_javascript_scripting.template.xml/
  .datasets.xml, produced once by examples\delphi\xfa\split_xfa_packets.cpp)
  -- read directly as raw bytes, no XML parsing needed.

  Does NOT rebuild LumasPdf.dll -- links only against the already-built
  wrappers\delphi\LumasPdf.pas / LumasPdfOO.pas units and the already-built
  engine DLL copied alongside this exe.
*)
uses
  System.SysUtils,
  System.IOUtils,
  LumasPdf   in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

function ReadPacket(const Path: string): RawByteString;
var
  B: TBytes;
begin
  Result := '';
  if not FileExists(Path) then Exit;
  B := TFile.ReadAllBytes(Path);
  if Length(B) = 0 then Exit;
  SetLength(Result, Length(B));
  Move(B[0], Result[1], Length(B));
end;

function RenderExample(const ExeDir, Name, OutPdfName: string): Integer;
var
  TemplateBuf, DatasetsBuf: RawByteString;
  pdf: TPDF;
  Idx: Integer;
begin
  Result := -100;
  Writeln('=== ', Name, ' (Delphi-OO/TPDF) -> ', OutPdfName, ' ===');

  TemplateBuf := ReadPacket(ExeDir + Name + '.template.xml');
  DatasetsBuf := ReadPacket(ExeDir + Name + '.datasets.xml');
  if TemplateBuf = '' then
  begin
    Writeln('NO-TEMPLATE-PACKET (', Name, '.template.xml missing or empty)');
    Exit;
  end;
  Writeln('template packet bytes: ', Length(TemplateBuf));
  Writeln('datasets packet bytes: ', Length(DatasetsBuf));

  pdf := TPDF.Create;
  try
    if not pdf.CreateNewPDFA(PAnsiChar(AnsiString(ExeDir + OutPdfName))) then
    begin
      Writeln('pdf.CreateNewPDFA FAILED');
      Exit;
    end;

    Idx := pdf.CreateXFAStreamA('template', @TemplateBuf[1], Length(TemplateBuf));
    Writeln('pdf.CreateXFAStreamA(template) -> index ', Idx);
    if Idx < 0 then
    begin
      Writeln('pdf.CreateXFAStreamA(template) FAILED');
      Exit;
    end;

    if DatasetsBuf <> '' then
    begin
      Idx := pdf.CreateXFAStreamA('datasets', @DatasetsBuf[1], Length(DatasetsBuf));
      Writeln('pdf.CreateXFAStreamA(datasets) -> index ', Idx);
      if Idx < 0 then
      begin
        Writeln('pdf.CreateXFAStreamA(datasets) FAILED');
        Exit;
      end;
    end;

    Result := pdf.RenderXFAForm;
    Writeln('pdf.RenderXFAForm -> ', Result, ' (expected: page count >= 1)');
    if Result < 1 then
    begin
      Writeln('RENDER-FAILED, code ', Result);
      Exit;
    end;

    if not pdf.CloseFile then
    begin
      Writeln('pdf.CloseFile FAILED');
      Exit;
    end;
    Writeln('Wrote ', OutPdfName, ' (', Result, ' page(s))');
  finally
    pdf.Free;
  end;
end;

var
  ExeDir: string;
  Rc: Integer;
begin
  try
    ExeDir := ExtractFilePath(ParamStr(0));
    Rc := RenderExample(ExeDir, '10_javascript_scripting', 'output.pdf');
    if Rc >= 1 then
      Writeln('OK: JavaScript-scripted form rendered, ', Rc, ' page(s). Open output.pdf and confirm:')
    else
      Writeln('FAILED, see errors above.');
    Writeln('  - UnitPriceWithTax  ~= 21.59  (19.99 * 1.08)');
    Writeln('  - OrderSummary      = "Purchase Order PO-1042 for Acme Robotics"');
    Writeln('  - 3 Line rows, Total = Qty*UnitCost per row (50.00 / 90.00 / 89.75)');
    Writeln('  If any of these are wrong or missing, the JS bridge contract in the template');
    Writeln('  needs adjusting -- see the flat original''s 10_javascript_scripting.xdp header comment.');
  except
    on E: Exception do
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
  end;
end.

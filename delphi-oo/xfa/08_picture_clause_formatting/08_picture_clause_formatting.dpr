program picture_clause_formatting;
{$APPTYPE CONSOLE}
(*
  Delphi-OO port of the flat "flavor tour" example 8 of 10: PICTURE-CLAUSE
  FORMATTING (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 6.4: real num{}/
  date{}/text{} picture patterns, applied both to plain bound values and to
  a FormCalc <calculate> result, proving the calculate-then-format pipeline
  order). Same fixture/DLL/pipeline as
  examples\delphi\xfa\08_picture_clause_formatting\08_picture_clause_formatting.dpr
  -- only the call surface differs: this driver uses the class-based OO
  wrapper (wrappers\delphi\LumasPdfOO.pas's TPDF) instead of the flat
  pdfXxx(Handle,...) functions:

    TPDF.Create             ~ pdfNewPDF
    pdf.CreateNewPDFA        ~ pdfCreateNewPDFA(Handle, ...)
    pdf.CreateXFAStreamA     ~ pdfCreateXFAStreamA(Handle, ...)
    pdf.SetXFAScriptEnabled  ~ pdfSetXFAScriptEnabled(Handle, ...)
    pdf.RenderXFAForm        ~ pdfRenderXFAForm(Handle)
    pdf.CloseFile            ~ pdfCloseFile(Handle)
    TPDF.Free                ~ pdfDeletePDF

  Packet files are PRE-SPLIT (08_picture_clause_formatting.template.xml/
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
    end
    else
      Writeln('(no datasets packet found -- template-only render)');

    // Phase-6 config gate defaults to enabled (Lumas.Pdf.Document.pas
    // FXFAScriptEnabled := True in Create), but this driver sets it
    // explicitly anyway so GrandTotalField's <calculate> script is
    // guaranteed to run regardless of that default ever changing.
    Writeln('pdf.SetXFAScriptEnabled(1) -> ', pdf.SetXFAScriptEnabled(1));

    Result := pdf.RenderXFAForm;
    Writeln('pdf.RenderXFAForm -> ', Result);
    if Result < 0 then
    begin
      Writeln('pdf.RenderXFAForm FAILED, code ', Result);
      Exit;
    end;

    if not pdf.CloseFile then
    begin
      Writeln('pdf.CloseFile FAILED');
      Result := -101;
      Exit;
    end;
    Writeln('OK: wrote ', OutPdfName);
  finally
    pdf.Free;
  end;
end;

var
  R: Integer;
begin
  R := RenderExample(ExtractFilePath(ParamStr(0)), '08_picture_clause_formatting', '08_picture_clause_formatting.pdf');
  Writeln('RESULT|08_picture_clause_formatting=', R);
  if R >= 1 then
  begin
    Writeln('Expect (verify with pypdf against 08_picture_clause_formatting.pdf):');
    Writeln('  Purchase Receipt -- Picture-Clause Formatting');
    Writeln('  Customer: Acme Corp');
    Writeln('  Unit Price: 1,875.50');
    Writeln('  Discount: ($125.00)');
    Writeln('  Date: July 24, 2026');
    Writeln('  Phone: 555-123-4567');
    Writeln('  845.25 620.00 410.25');
    Writeln('  Grand Total: 1,875.50   (calculate-then-format: Item1+Item2+Item3, THEN num{zzz,zz9.99})');
  end;
end.

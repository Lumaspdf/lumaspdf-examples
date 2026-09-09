program basic_positioned_form;
{$APPTYPE CONSOLE}
(*
  Delphi-OO port of the flat "flavor tour" example 1 of 10: POSITIONED
  LAYOUT (plan sec 5.1 -- static field positioning, no flow/occur/
  pagination). Same fixture, same real DLL, same render pipeline as
  examples\delphi\xfa\01_basic_positioned_form\01_basic_positioned_form.dpr
  -- the ONLY difference is that this driver calls the class-based OO
  surface in wrappers\delphi\LumasPdfOO.pas (TPDF) instead of the flat
  pdfXxx(Handle, ...) functions in wrappers\delphi\LumasPdf.pas:

    TPDF.Create            ~ pdfNewPDF
    pdf.CreateNewPDFA       ~ pdfCreateNewPDFA(Handle, ...)
    pdf.CreateXFAStreamA    ~ pdfCreateXFAStreamA(Handle, ...)
    pdf.RenderXFAForm       ~ pdfRenderXFAForm(Handle)
    pdf.CloseFile           ~ pdfCloseFile(Handle)
    TPDF.Free               ~ pdfDeletePDF

  Packet files are PRE-SPLIT (see examples\delphi\xfa\split_xfa_packets.cpp)
  -- 01_basic_positioned_form.template.xml / .datasets.xml already hold the
  raw <template>/<xfa:datasets> subtree bytes, so this driver just reads
  them as raw bytes; it needs no XML library at all (the flat original
  parses the bundled .xdp itself via Lumas.Pdf.Xml -- this OO port skips
  that step since the split has already been done once).

  Renders 01_basic_positioned_form's "Employee Information" HR form (five
  statically-positioned/data-bound fields + decorative draws, single page,
  layout="position" throughout) through the real, already-built
  LumasPdf.dll. Does NOT rebuild the engine DLL -- links only against the
  existing wrappers\delphi\LumasPdf.pas / LumasPdfOO.pas units.
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

  pdf := TPDF.Create; // = pdfNewPDF
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
    pdf.Free; // = pdfDeletePDF
  end;
end;

var
  R1: Integer;
begin
  R1 := RenderExample(ExtractFilePath(ParamStr(0)), '01_basic_positioned_form', 'output.pdf');
  Writeln('RESULT|01_basic_positioned_form=', R1);
  if R1 >= 1 then
  begin
    Writeln('OK: single-page positioned "Employee Information" form rendered.');
    Writeln('Open output.pdf and confirm masthead + 5 statically-placed fields');
    Writeln('(name, employee ID, department, hire date, full-time checkbox) +');
    Writeln('photo-placeholder box, all layout="position" with explicit x/y/w/h.');
  end;
end.

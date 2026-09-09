program acroform_widget_synthesis;
{$APPTYPE CONSOLE}
(*
  Delphi-OO port of the flat "flavor tour" example 9 of 10: ACROFORM-WIDGET
  SYNTHESIS. Demonstrates pdf.SetXFARenderMode(1): turning an XFA form into
  a REAL fillable AcroForm PDF (plan sec 7/8, Lumas.Pdf.Xfa.AcroSynth.pas):

    - textEdit / numericEdit / dateTimeEdit -> /FT Tx
    - checkButton (standalone, or exclGroup radio group) -> /FT Btn
    - choiceList                                          -> /FT Ch
    - button (whole-box pushbutton, real bevel /AP)        -> /FT Btn
    - imageEdit is NOT synthesized by design (no native fillable image
      field type in ISO 32000-1) -- this example does not use one.

  Same fixture/DLL/pipeline (renders TWICE: mode0 then mode1) as
  examples\delphi\xfa\09_acroform_widget_synthesis\09_acroform_widget_synthesis.dpr
  -- only the call surface differs: this driver uses the class-based OO
  wrapper (wrappers\delphi\LumasPdfOO.pas's TPDF) instead of the flat
  pdfXxx(Handle,...) functions:

    TPDF.Create           ~ pdfNewPDF
    pdf.CreateNewPDFA      ~ pdfCreateNewPDFA(Handle, ...)
    pdf.CreateXFAStreamA   ~ pdfCreateXFAStreamA(Handle, ...)
    pdf.SetXFARenderMode   ~ pdfSetXFARenderMode(Handle, ...)  -- THE extra
                              call this example needs before rendering, only
                              for the mode1 pass (mode0 renders with no call
                              at all, exercising the untouched default path)
    pdf.RenderXFAForm      ~ pdfRenderXFAForm(Handle)
    pdf.CloseFile          ~ pdfCloseFile(Handle)
    TPDF.Free              ~ pdfDeletePDF

    mode0.pdf -- Mode 0 (default): flattened ink only, no /AcroForm/Fields.
    mode1.pdf -- Mode 1: flattened ink PLUS real synthesized AcroForm
                 fillable widgets (/AcroForm/Fields, 9 top-level fields).

  Packet files are PRE-SPLIT (09_acroform_widget_synthesis.template.xml/
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

// Mode: 0 = flatten-to-ink only (default, no pdf.SetXFARenderMode call at
// all); 1 = also synthesize real AcroForm fillable widgets.
function RenderExample(const ExeDir, Name, OutPdfName: string; Mode: Integer): Integer;
var
  TemplateBuf, DatasetsBuf: RawByteString;
  pdf: TPDF;
  Idx, Prev: Integer;
begin
  Result := -100;
  Writeln('=== ', Name, ' (Delphi-OO/TPDF, mode=', Mode, ') -> ', OutPdfName, ' ===');

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

    if Mode <> 0 then
    begin
      Prev := pdf.SetXFARenderMode(Mode);
      Writeln('pdf.SetXFARenderMode(', Mode, ') -> previous=', Prev, ' (expect 0, the default)');
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
      Result := -101;
      Exit;
    end;
    Writeln('OK: wrote ', OutPdfName, ' (', Result, ' page(s))');
  finally
    pdf.Free;
  end;
end;

var
  ExeDir: string;
  R0, R1: Integer;
begin
  try
    ExeDir := ExtractFilePath(ParamStr(0));

    R0 := RenderExample(ExeDir, '09_acroform_widget_synthesis', 'mode0.pdf', 0);
    R1 := RenderExample(ExeDir, '09_acroform_widget_synthesis', 'mode1.pdf', 1);

    Writeln;
    Writeln('RESULT|mode0=', R0, '|mode1=', R1);
    if (R0 >= 1) and (R1 >= 1) then
    begin
      Writeln('OK: both renders succeeded.');
      Writeln('  mode0.pdf -- flattened ink only, NO /AcroForm/Fields.');
      Writeln('  mode1.pdf -- flattened ink PLUS a REAL fillable AcroForm:');
      Writeln('    ApplicantName (Tx), YearsExperience (Tx), ApplicationDate (Tx),');
      Writeln('    EmploymentType (Btn radio, 3 Kids: Full-time/Part-time/Contract),');
      Writeln('    Department (Ch combo, 6 options), SubmitButton (Btn pushbutton, real bevel /AP),');
      Writeln('    Employer[0].EmployerName / Employer[1].EmployerName / Employer[2].EmployerName (Tx x3).');
      Writeln('  Open mode1.pdf in a real PDF reader (Acrobat, Chrome, Edge, etc.) --');
      Writeln('  it is a genuinely fillable form: click into the fields and type.');
    end
    else
      Writeln('FAILED, see errors above.');
  except
    on E: Exception do
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
  end;
end.

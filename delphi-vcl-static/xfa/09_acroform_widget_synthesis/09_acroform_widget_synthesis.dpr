program acroform_widget_synthesis_vcl;
{$APPTYPE CONSOLE}
(*
  VCL-static-component-flavour port of
  examples\delphi\xfa\09_acroform_widget_synthesis (flavor-tour example 9
  of 10: pdf.SetXFARenderMode(1) -- turning an XFA form into a REAL
  fillable AcroForm PDF (textEdit/numericEdit/dateTimeEdit -> /FT Tx,
  checkButton exclGroup -> one /FT Btn radio group, choiceList -> /FT Ch,
  button -> /FT Btn pushbutton with a real bevel /AP)).

  PURE VCL static example -- the engine is linked INTO this exe
  (LUMAS_STATIC, runtime packages OFF). NO LumasPdf.dll at run time.
  Lumas.Pdf.Wrap.Static MUST be the first unit in the uses clause. The XFA
  pipeline is driven through TLumasPDFCore (Lumas.Pdf.Wrap.Core) -- the flat
  pdfXxx(Handle,...) API re-exposed as methods -- same pattern as
  examples\vcl_static\smoke_test / acroform\check_boxes.

  No XML parsing here: 09_acroform_widget_synthesis.template.xml /
  .datasets.xml are the already pre-split raw packet bytes (produced once
  by the flat-Delphi tour's split_xfa_packets tool) sitting next to this
  .dpr.

  Renders the SAME packets TWICE, exactly like the flat-Delphi original,
  through the component-method form of that driver's own real-DLL export
  sequence:

    TLumasPDFCore.Create -> pdf.CreateNewPDFA -> pdf.CreateXFAStreamA('template',...) ->
    pdf.CreateXFAStreamA('datasets',...) -> [pdf.SetXFARenderMode(1) only for
    the second pass] -> pdf.RenderXFAForm -> pdf.CloseFile -> pdf.Free

      mode0.pdf -- Mode 0 (default): flattened ink only, no /AcroForm/Fields.
      mode1.pdf -- Mode 1: flattened ink PLUS real synthesized AcroForm
                   fillable widgets (/AcroForm/Fields, 9 top-level fields).

  This is the ONE example in the tour that needs an extra call before
  rendering (SetXFARenderMode) -- everything else in this tour uses the
  plain CreateXFAStreamA(x2) -> RenderXFAForm sequence with no extra config
  call in between.
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

// Mode: 0 = flatten-to-ink only (default, no SetXFARenderMode call at all --
// exercises the untouched default path); 1 = also synthesize real AcroForm
// fillable widgets.
function RenderExample(const TemplatePath, DatasetsPath, OutPdfPath: string; Mode: Integer): Integer;
var
  TemplateBuf, DatasetsBuf: TBytes;
  pdf: TLumasPDFCore;
  Idx, Prev: Integer;
begin
  Result := -100;
  Writeln('=== ', ExtractFileName(TemplatePath), ' (mode=', Mode, ') -> ',
    ExtractFileName(OutPdfPath), ' ===');
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
    end;

    if Mode <> 0 then
    begin
      Prev := pdf.SetXFARenderMode(Mode);
      Writeln('SetXFARenderMode(', Mode, ') -> previous=', Prev, ' (expect 0, the default)');
    end;

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
    Writeln('OK: wrote ', OutPdfPath, ' (', Result, ' page(s))');
  finally
    pdf.Free; // = pdfDeletePDF
  end;
end;

var
  ExeDir, TemplatePath, DatasetsPath: string;
  R0, R1: Integer;
begin
  try
    ExeDir := ExtractFilePath(ParamStr(0));
    TemplatePath := ExeDir + '09_acroform_widget_synthesis.template.xml';
    DatasetsPath := ExeDir + '09_acroform_widget_synthesis.datasets.xml';

    R0 := RenderExample(TemplatePath, DatasetsPath, ExeDir + 'mode0.pdf', 0);
    R1 := RenderExample(TemplatePath, DatasetsPath, ExeDir + 'mode1.pdf', 1);

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

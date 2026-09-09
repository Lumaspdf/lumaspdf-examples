program acroform_widget_synthesis;
{$APPTYPE CONSOLE}
(*
  LumasPDF XFA "flavor tour" example 9 of 10 -- ACROFORM-WIDGET SYNTHESIS.

  Demonstrates pdfSetXFARenderMode(doc, 1): turning an XFA form into a REAL
  fillable AcroForm PDF (plan sec 7/8, Lumas.Pdf.Xfa.AcroSynth.pas):

    - textEdit / numericEdit / dateTimeEdit -> /FT Tx
    - checkButton (standalone, or exclGroup radio group)  -> /FT Btn
    - choiceList                                          -> /FT Ch
    - button (whole-box pushbutton, real bevel /AP)       -> /FT Btn
    - imageEdit is NOT synthesized by design (no native fillable image
      field type in ISO 32000-1) -- this example does not use one.

  Renders the SAME 09_acroform_widget_synthesis.xdp TWICE, through the
  exact real-DLL public export sequence every other example in this tour
  uses (mirrors cpp\tools\xfa_render_test.dpr and this project's own
  xfa_render_fx10_golden.dpr, the fx10-specific sibling that first added the
  Render-Mode config export to this call sequence):

    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
    pdfCreateXFAStreamA('datasets',...) -> [pdfSetXFARenderMode(doc,1) only
    for the second pass] -> pdfRenderXFAForm -> pdfCloseFile -> pdfDeletePDF

      mode0.pdf -- Mode 0 (default): flattened ink only, no /AcroForm
      mode1.pdf -- Mode 1: flattened ink PLUS real synthesized AcroForm
                   fillable widgets (/AcroForm/Fields)

  This is a STANDALONE driver -- it does NOT rebuild LumasPdf.dll (no call
  to tools\build_dll.bat anywhere in this file or its build_and_run.bat
  sibling). It links only against the already-built wrappers\delphi\
  LumasPdf.pas and the already-built LumasPdf.dll, exactly like every other
  example in this tour.
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

// Mode: 0 = flatten-to-ink only (default, no pdfSetXFARenderMode call at
// all -- exercises the untouched default path); 1 = also synthesize real
// AcroForm fillable widgets.
function RenderExample(const XdpPath, OutPdfPath: string; Mode: Integer): Integer;
var
  Raw: string;
  XdpRoot: TXmlNode;
  TemplateBuf, DatasetsBuf: RawByteString;
  PDF: PPDF;
  Idx, Prev: Integer;
begin
  Result := -100;
  Writeln('=== ', ExtractFileName(XdpPath), ' (mode=', Mode, ') -> ', ExtractFileName(OutPdfPath), ' ===');
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

      if Mode <> 0 then
      begin
        Prev := pdfSetXFARenderMode(PDF, Mode);
        Writeln('pdfSetXFARenderMode(PDF, ', Mode, ') -> previous=', Prev, ' (expect 0, the default)');
      end;

      Result := pdfRenderXFAForm(PDF);
      Writeln('pdfRenderXFAForm -> ', Result, ' (expected: page count >= 1)');
      if Result < 1 then
      begin
        Writeln('RENDER-FAILED, code ', Result);
        Exit;
      end;

      if not pdfCloseFile(PDF) then
      begin
        Writeln('pdfCloseFile FAILED');
        Result := -101;
        Exit;
      end;
      Writeln('OK: wrote ', OutPdfPath, ' (', Result, ' page(s))');
    finally
      pdfDeletePDF(PDF);
    end;
  finally
    XdpRoot.Free;
  end;
end;

var
  ExeDir, XdpPath: string;
  R0, R1: Integer;
begin
  try
    ExeDir := ExtractFilePath(ParamStr(0));
    XdpPath := ExeDir + '09_acroform_widget_synthesis.xdp';

    R0 := RenderExample(XdpPath, ExeDir + 'mode0.pdf', 0);
    R1 := RenderExample(XdpPath, ExeDir + 'mode1.pdf', 1);

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

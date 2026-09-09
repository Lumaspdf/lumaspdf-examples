program _02_data_binding;
{$APPTYPE CONSOLE}
(*
  Delphi-OO port of the flat "flavor tour" example 2 of 10: DATA BINDING
  (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 6: implicit by-name binding AND
  explicit <bind match="dataRef" ref="..."/> SOM path binding, plus a
  <bind match="none"/> literal, all against one genuinely nested
  <xfa:datasets> packet). Same fixture/DLL/pipeline as
  examples\delphi\xfa\02_data_binding\02_data_binding.dpr -- only the call
  surface differs: this driver uses the class-based OO wrapper
  (wrappers\delphi\LumasPdfOO.pas's TPDF) instead of the flat pdfXxx(Handle,...)
  functions:

    TPDF.Create          ~ pdfNewPDF
    pdf.CreateNewPDFA     ~ pdfCreateNewPDFA(Handle, ...)
    pdf.CreateXFAStreamA  ~ pdfCreateXFAStreamA(Handle, ...)
    pdf.RenderXFAForm     ~ pdfRenderXFAForm(Handle)
    pdf.CloseFile         ~ pdfCloseFile(Handle)
    TPDF.Free             ~ pdfDeletePDF

  Packet files are PRE-SPLIT: 02_data_binding.template.xml/.datasets.xml
  already hold the raw <template>/<xfa:datasets> subtree bytes (produced
  once by examples\delphi\xfa\split_xfa_packets.cpp), so this driver reads
  them directly as bytes -- no XML parsing needed.

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
  Writeln('LumasPDF XFA flavor tour (Delphi-OO) -- example 2/10: Data Binding');
  Writeln('(implicit by-name + explicit dataRef SOM path + match=none literal)');
  Writeln('');
  R := RenderExample(ExtractFilePath(ParamStr(0)), '02_data_binding', '02_data_binding.render.pdf');
  Writeln('');
  Writeln('RESULT|02_data_binding=', R);
  if R >= 1 then
  begin
    Writeln('Expect (verify with pypdf against 02_data_binding.render.pdf):');
    Writeln('  Customer Name (implicit)              = Acme Robotics LLC');
    Writeln('  Account ID (implicit)                 = ACCT-88213');
    Writeln('  Street (implicit, nested subform)     = 500 Innovation Way');
    Writeln('  State (implicit, nested subform)      = IL');
    Writeln('  Zip (implicit, nested subform)        = 62704');
    Writeln('  Shipping City (dataRef, 3 levels deep) = Springfield');
    Writeln('  Primary Contact Email (dataRef, 4 deep) = ap@acmerobotics.example');
    Writeln('  Status (match=none literal)            = Active - Verified (NOT PENDING_CLOSURE)');
  end;
end.

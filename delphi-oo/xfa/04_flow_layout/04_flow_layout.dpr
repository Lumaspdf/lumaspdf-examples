program flow_layout;
{$APPTYPE CONSOLE}
(*
  Delphi-OO port of the flat "flavor tour" example 4 of 10: FLOW LAYOUT
  (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 5.3: layout="tb" vertical
  stacking + layout="lr-tb" left-to-right wrapping). Same fixture/DLL/
  pipeline as examples\delphi\xfa\04_flow_layout\04_flow_layout.dpr -- only
  the call surface differs: this driver uses the class-based OO wrapper
  (wrappers\delphi\LumasPdfOO.pas's TPDF) instead of the flat
  pdfXxx(Handle,...) functions:

    TPDF.Create          ~ pdfNewPDF
    pdf.CreateNewPDFA     ~ pdfCreateNewPDFA(Handle, ...)
    pdf.CreateXFAStreamA  ~ pdfCreateXFAStreamA(Handle, ...)
    pdf.RenderXFAForm     ~ pdfRenderXFAForm(Handle)
    pdf.CloseFile         ~ pdfCloseFile(Handle)
    TPDF.Free             ~ pdfDeletePDF

  Packet files are PRE-SPLIT (04_flow_layout.template.xml/.datasets.xml,
  produced once by examples\delphi\xfa\split_xfa_packets.cpp) -- read
  directly as raw bytes, no XML parsing needed.

  The layout geometry itself (TermsPanel tb-stacking, SkillsPanel lr-tb
  wrapping across 3 lines) is independently hand-derived and cross-checked
  in the original example's README.md via the project's own
  cpp\tools\xfa_layout_dump.exe self-oracle -- that check is orthogonal to
  the DLL render pipeline and is not duplicated in this OO port; this driver
  focuses on proving the OO call surface renders the SAME fixture correctly
  through the SAME real DLL.

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
  R := RenderExample(ExtractFilePath(ParamStr(0)), '04_flow_layout', '04_flow_layout.pdf');
  Writeln('RESULT|04_flow_layout=', R);
  if R >= 1 then
  begin
    Writeln('OK: one-page "Employment Application" rendered.');
    Writeln('TermsPanel (layout=tb): 6 clauses stack at x=36, y=92/116/140/164/188/212 (+24 each).');
    Writeln('SkillsPanel (layout=lr-tb): 9 tags wrap 4/4/1 across 3 lines at y=270/290/310,');
    Writeln('  x=36/146/256/366 per line (each tag w=110, container w=540).');
    Writeln('Re-verify geometry independently with cpp\tools\xfa_layout_dump.exe against the');
    Writeln('sibling flat-Delphi fixture examples\delphi\xfa\04_flow_layout\04_flow_layout.xdp.');
  end;
end.

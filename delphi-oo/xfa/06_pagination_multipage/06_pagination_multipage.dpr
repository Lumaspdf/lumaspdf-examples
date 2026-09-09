program pagination_multipage;
{$APPTYPE CONSOLE}
(*
  Delphi-OO port of the flat "flavor tour" example 6 of 10: MULTI-PAGE
  PAGINATION (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 5.4: pageSet/
  pageArea/contentArea, forced overflow across multiple pages, leader/
  trailer "continued" subforms). Same fixture/DLL/pipeline/CheckPageCount
  assertion as
  examples\delphi\xfa\06_pagination_multipage\06_pagination_multipage.dpr --
  only the call surface differs: this driver uses the class-based OO
  wrapper (wrappers\delphi\LumasPdfOO.pas's TPDF) instead of the flat
  pdfXxx(Handle,...) functions:

    TPDF.Create            ~ pdfNewPDF
    pdf.CreateNewPDFA       ~ pdfCreateNewPDFA(Handle, ...)
    pdf.CreateXFAStreamA    ~ pdfCreateXFAStreamA(Handle, ...)
    pdf.XFAFormPageCount    ~ pdfXFAFormPageCount(Handle)
    pdf.RenderXFAForm       ~ pdfRenderXFAForm(Handle)
    pdf.CloseFile           ~ pdfCloseFile(Handle)
    TPDF.Free               ~ pdfDeletePDF

  CheckPageCount=4: hand-derived in the flat original's README.md from
  06_pagination_multipage's own geometry (contentArea 400pt tall, row/
  leader/trailer h=20pt each, 70 <Line> records). This driver calls
  pdf.XFAFormPageCount BEFORE pdf.RenderXFAForm and asserts the two agree.

  Packet files are PRE-SPLIT (06_pagination_multipage.template.xml/
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

function RenderExample(const ExeDir, Name, OutPdfName: string; CheckPageCount: Integer = -1): Integer;
var
  TemplateBuf, DatasetsBuf: RawByteString;
  pdf: TPDF;
  Idx, Pre: Integer;
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

    if CheckPageCount >= 0 then
    begin
      Pre := pdf.XFAFormPageCount;
      Writeln('pdf.XFAFormPageCount (pre-flight, before any AppendPage) -> ', Pre);
      if Pre <> CheckPageCount then
      begin
        Writeln('PAGECOUNT-MISMATCH: expected ', CheckPageCount, ' got ', Pre);
        Result := -102;
        Exit;
      end;
    end;

    Result := pdf.RenderXFAForm;
    Writeln('pdf.RenderXFAForm -> ', Result);
    if Result < 0 then
    begin
      Writeln('pdf.RenderXFAForm FAILED, code ', Result);
      Exit;
    end;
    if (CheckPageCount >= 0) and (Result <> CheckPageCount) then
    begin
      Writeln('RENDER-PAGECOUNT-MISMATCH: pre-flight said ', CheckPageCount,
        ' but render produced ', Result);
      Result := -103;
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
  R := RenderExample(ExtractFilePath(ParamStr(0)), '06_pagination_multipage', '06_pagination_multipage.pdf', 4);
  Writeln('RESULT|06_pagination_multipage=', R);
  if R = 4 then
  begin
    Writeln('OK: 4-page invoice rendered, matching the hand-derived page count.');
    Writeln('Expected row split: page1=19 rows(no leader,trailer), page2=18(leader+trailer),');
    Writeln('page3=18(leader+trailer), page4=15(leader,no trailer) -- 19+18+18+15=70 lines.');
  end;
end.

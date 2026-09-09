program _03_formcalc_calculations;
{$APPTYPE CONSOLE}
(*
  Delphi-OO port of the flat "flavor tour" example 3 of 10: FORMCALC
  CALCULATIONS (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 4: the FormCalc
  lexer/parser/VM/38-builtin engine, Phase 3). Same fixture/DLL/pipeline as
  examples\delphi\xfa\03_formcalc_calculations\03_formcalc_calculations.dpr
  -- only the call surface differs: this driver uses the class-based OO
  wrapper (wrappers\delphi\LumasPdfOO.pas's TPDF) instead of the flat
  pdfXxx(Handle,...) functions:

    TPDF.Create          ~ pdfNewPDF
    pdf.CreateNewPDFA     ~ pdfCreateNewPDFA(Handle, ...)
    pdf.CreateXFAStreamA  ~ pdfCreateXFAStreamA(Handle, ...)
    pdf.RenderXFAForm     ~ pdfRenderXFAForm(Handle)
    pdf.CloseFile         ~ pdfCloseFile(Handle)
    TPDF.Free             ~ pdfDeletePDF

  This example's 14 calculate-only fields exercise 11 of the v1 catalog's
  real FormCalc builtins (Sum, Avg, Round, Count, If, Concat, Upper, Left,
  Date2Num, Num2Date, DateFmt) plus '*'/'-' arithmetic and '>=' comparison --
  see this folder's README.md for the full calculation graph and the
  hand-computed expected value of every field.

  Packet files are PRE-SPLIT (03_formcalc_calculations.template.xml/
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
  Writeln('LumasPDF XFA flavor tour (Delphi-OO) -- example 3/10: FormCalc Calculations');
  Writeln('(Sum/Avg/Round/Count, If, Concat/Upper/Left, Date2Num/Num2Date/DateFmt)');
  Writeln('');
  R := RenderExample(ExtractFilePath(ParamStr(0)), '03_formcalc_calculations', '03_formcalc_calculations.render.pdf');
  Writeln('');
  Writeln('RESULT|03_formcalc_calculations=', R);
  if R >= 1 then
  begin
    Writeln('Expect (verify with pypdf against 03_formcalc_calculations.render.pdf):');
    Writeln('  Item1Total=37.5  Item2Total=90  Item3Total=40');
    Writeln('  TotalQty=10  Subtotal=167.5  AvgUnitPrice=21.83  ItemCount=3');
    Writeln('  DiscountLabel=Bulk Discount  DiscountAmount=16.75  GrandTotal=150.75');
    Writeln('  FullName=Alex Nguyen  CustomerInitial=A');
    Writeln('  OrderDateNum display=2026-07-15  OrderDateFormatted=7/15/26');
  end;
end.

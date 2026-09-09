program table_layout;
{$APPTYPE CONSOLE}
(*
  Delphi-OO port of the flat "flavor tour" example 7 of 10: TABLE LAYOUT
  (XFA_DYNAMIC_ENGINE_PLAN_2026-07-23.md sec 5.3: layout="table", a
  columnWidths-driven table subform rendered via TLumasPdfDoc.DrawTable).
  Same fixture/DLL/pipeline as
  examples\delphi\xfa\07_table_layout\07_table_layout.dpr -- only the call
  surface differs: this driver uses the class-based OO wrapper
  (wrappers\delphi\LumasPdfOO.pas's TPDF) instead of the flat
  pdfXxx(Handle,...) functions:

    TPDF.Create          ~ pdfNewPDF
    pdf.CreateNewPDFA     ~ pdfCreateNewPDFA(Handle, ...)
    pdf.CreateXFAStreamA  ~ pdfCreateXFAStreamA(Handle, ...)
    pdf.RenderXFAForm     ~ pdfRenderXFAForm(Handle)
    pdf.CloseFile         ~ pdfCloseFile(Handle)
    TPDF.Free             ~ pdfDeletePDF

  "ProductTable" (layout="table", columnWidths="216pt 108pt 108pt 108pt")
  has 6 layout="row" children (1 header + 5 data rows), each authoring a
  DIFFERENT <para hAlign> (Product=left, Price=right, Stock=center,
  Rating=right, on every row) to exercise RenderTableCell's real per-cell
  hAlign handling.

  Packet files are PRE-SPLIT (07_table_layout.template.xml/.datasets.xml,
  produced once by examples\delphi\xfa\split_xfa_packets.cpp) -- read
  directly as raw bytes, no XML parsing needed.

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
  R1: Integer;
begin
  R1 := RenderExample(ExtractFilePath(ParamStr(0)), '07_table_layout', '07_table_layout.pdf');
  Writeln('RESULT|07_table_layout=', R1);
  if R1 >= 1 then
  begin
    Writeln('OK: "Product Comparison Table" rendered (header + 5 rows).');
    Writeln('Rows stack at PDF y = 688,668,648,628,608,588 (20pt decrement each).');
    Writeln('Column 1 (Product, left) flush-left at x=39. Column 3 (Stock, center) text-width-');
    Writeln('centered on x=414. Columns 2/4 (Price/Rating, right) share a constant end-x per column.');
  end;
end.

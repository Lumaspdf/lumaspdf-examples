program table_templates;
// Delphi OO port of examples\c\tables\templates\table_templates.c
// Uses the OO TPDF class for the PDF handle and the FLAT tbl* externals for
// the table. Imports every page of sample_multipage.pdf as a template and lays
// them out two per row in a table (tfScaleToRect), drawing across as many
// pages as needed.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf   in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

// Table flag missing from the wrapper enum (from LumasPdf.pas):
const
  tfScaleToRect: TTableFlags = $8;

function ErrProc(const Data: Pointer; ErrCode: Integer;
  const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then
    Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TPDF;
  tbl: ITBL;
  i, pageCount, tmpl, rowNum: Integer;
  err: TPDFError;
begin
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');

    pdf.SetPageCoords(Ord(pcTopDown));
    pdf.SetImportFlags2(if2UseProxy);

    pdf.OpenImportFileA('..\..\..\..\sample_multipage.pdf', ptOpen, '');

    pageCount := pdf.GetInPageCount;
    if pageCount < 1 then
    begin
      Writeln('Help file not found!');
      Exit;
    end;

    tbl := tblCreateTable(pdf.Handle, pageCount div 4 + 1, 2, 512.12, 0.0);
    tblSetBoxProperty(tbl, -1, -1, tbpBorderWidth, 1.0, 1.0, 1.0, 1.0);
    tblSetBoxProperty(tbl, -1, -1, tbpCellPadding, 5.0, 5.0, 5.0, 5.0);
    tblSetGridWidth(tbl, 1.0, 1.0);
    tblSetFlags(tbl, -1, -1, tfScaleToRect);

    pdf.SetPageFormat(Ord(pfUS_Letter));

    rowNum := 0;
    for i := 1 to pageCount do
    begin
      tmpl := pdf.ImportPage(i);
      if (i and 1) <> 0 then rowNum := tblAddRow(tbl, 335.0);
      tblSetCellTemplate(tbl, rowNum, (i - 1) and 1, True, coCenter, coCenter, tmpl, 0.0, 0.0);
    end;

    pdf.Append;
    tblDrawTable(tbl, 50.0, 50.0, 742.0);
    while tblHaveMore(tbl) do
    begin
      pdf.EndPage;
      pdf.Append;
      tblDrawTable(tbl, 50.0, 50.0, 742.0);
    end;
    pdf.EndPage;

    tblDeleteTable(tbl);

    err.StructSize := SizeOf(err);
    for i := 0 to pdf.GetErrLogMessageCount - 1 do
    begin
      pdf.GetErrLogMessage(i, err);
      if err.Msg <> nil then Writeln(string(AnsiString(err.Msg)));
    end;

    if pdf.HaveOpenDoc then
    begin
      if not pdf.OpenOutputFileA('out.pdf') then Exit;
      if pdf.CloseFile then Writeln('Done: out.pdf');
    end;
  finally
    pdf.Free;
  end;
end.

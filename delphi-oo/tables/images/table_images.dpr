program table_images;
// Delphi OO port of examples\c\tables\images\table_images.c
// Uses the OO TPDF class for the PDF handle and the FLAT tbl* externals for
// the table (the table flags used are not in the wrapper enum, so flat tbl*
// is cleanest). Lays every *.jpg in test_files\images into a 4-column table
// (one image per cell, native image colour space), draws it, then redraws
// with tfScaleToRect and a caption.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf   in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

// Table flags missing from the wrapper enum (from LumasPdf.pas):
const
  tfScaleToRect: TTableFlags = $8;
  tfUseImageCS:  TTableFlags = $10;

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
  imgDir, full: AnsiString;
  sr: TSearchRec;
  i, rowNum, res: Integer;
  fullSize: Int64;
  err: TPDFError;
begin
  imgDir := '..\..\..\..\test_files\images\';

  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');

    pdf.SetPageCoords(Ord(pcTopDown));
    pdf.SetResolution(300);

    tbl := tblCreateTable(pdf.Handle, 100, 4, 500.0, 125.0);
    tblSetBoxProperty(tbl, -1, -1, tbpBorderWidth, 1.0, 1.0, 1.0, 1.0);
    tblSetBoxProperty(tbl, -1, -1, tbpCellPadding, 5.0, 5.0, 5.0, 5.0);
    tblSetGridWidth(tbl, 1.0, 1.0);
    tblSetFlags(tbl, -1, -1, tfUseImageCS);

    res := FindFirst(string(imgDir) + '*.jpg', faAnyFile, sr);
    if res <> 0 then
    begin
      Writeln('Test images not found!');
      tblDeleteTable(tbl);
      Exit;
    end;

    i := 1;
    fullSize := sr.Size;
    rowNum := tblAddRow(tbl, 125.0);
    full := imgDir + AnsiString(sr.Name);
    tblSetCellImageA(tbl, rowNum, 0, True, coCenter, coCenter, 0.0, 0.0, PAnsiChar(full), 1);

    while FindNext(sr) = 0 do
    begin
      if i = 4 then begin rowNum := tblAddRow(tbl, 100.0); i := 0; end;
      Inc(fullSize, sr.Size);
      full := imgDir + AnsiString(sr.Name);
      tblSetCellImageA(tbl, rowNum, i, True, coCenter, coCenter, 0.0, 0.0, PAnsiChar(full), 1);
      Inc(i);
    end;
    FindClose(sr);

    pdf.Append;
    tblDrawTable(tbl, 50.0, 50.0, 742.0);
    while tblHaveMore(tbl) do
    begin
      pdf.EndPage;
      if fullSize > 104857600 then pdf.FlushPages(fpfDefault);
      pdf.Append;
      tblDrawTable(tbl, 50.0, 50.0, 742.0);
    end;
    pdf.EndPage;

    // Draw the same table again but this time with tfScaleToRect
    tblSetFlags(tbl, -1, -1, tfScaleToRect or tfUseImageCS);
    pdf.Append;
    pdf.SetFontA('Arial', fsRegular, 12.0, True, cp1252);
    pdf.WriteTextA(50.0, 50.0, 'The same table but the flag tfScaleToRect was set.');
    tblDrawTable(tbl, 50.0, 65.0, 742.0);
    while tblHaveMore(tbl) do
    begin
      pdf.EndPage;
      if fullSize > 104857600 then pdf.FlushPages(fpfDefault);
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

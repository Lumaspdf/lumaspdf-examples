program table_text;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF/TPDFTable), NOT the flat API.
// Builds a 3x3 table demonstrating cell text alignment, draws it, then redraws it
// with a 90-degree cell orientation.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf     in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO   in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TPDF;
  tbl: TPDFTable;
  i, rowNum: Integer;
  err: TPDFError;
  txt: AnsiString;
begin
  txt := 'The cell alignment can be set for text, images, and templates...';
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');
    pdf.SetPageCoords(Ord(pcTopDown));

    tbl := TPDFTable.Create(pdf.CreateTable(3, 3, 500.0, 100.0));
    try
      tbl.SetBoxProperty(-1, -1, tbpBorderWidth, 1.0, 1.0, 1.0, 1.0);
      tbl.SetFontA(-1, -1, 'Arial', fsRegular, True, cp1252);
      tbl.SetFontA(-1, 1, 'Arial', fsBold, True, cp1252);
      tbl.SetGridWidth(1.0, 1.0);

      rowNum := tbl.AddRow(-1.0);
      tbl.SetCellTextA(TTextAlign(rowNum), TTextAlign(0), taLeft,   coTop, PAnsiChar(txt), Cardinal(-1));
      tbl.SetCellTextA(TTextAlign(rowNum), TTextAlign(1), taCenter, coTop, PAnsiChar(txt), Cardinal(-1));
      tbl.SetCellTextA(TTextAlign(rowNum), TTextAlign(2), taRight,  coTop, PAnsiChar(txt), Cardinal(-1));

      rowNum := tbl.AddRow(-1.0);
      tbl.SetCellTextA(TTextAlign(rowNum), TTextAlign(0), taLeft,   coCenter, PAnsiChar(txt), Cardinal(-1));
      tbl.SetCellTextA(TTextAlign(rowNum), TTextAlign(1), taCenter, coCenter, PAnsiChar(txt), Cardinal(-1));
      tbl.SetCellTextA(TTextAlign(rowNum), TTextAlign(2), taRight,  coCenter, PAnsiChar(txt), Cardinal(-1));

      rowNum := tbl.AddRow(-1.0);
      tbl.SetCellTextA(TTextAlign(rowNum), TTextAlign(0), taLeft,   coBottom, PAnsiChar(txt), Cardinal(-1));
      tbl.SetCellTextA(TTextAlign(rowNum), TTextAlign(1), taCenter, coBottom, PAnsiChar(txt), Cardinal(-1));
      tbl.SetCellTextA(TTextAlign(rowNum), TTextAlign(2), taRight,  coBottom, PAnsiChar(txt), Cardinal(-1));

      pdf.Append;
      tbl.DrawTable(50.0, 50.0, 742.0);
      while tbl.HaveMore do
      begin
        pdf.EndPage;
        pdf.Append;
        tbl.DrawTable(50.0, 50.0, 742.0);
      end;
      pdf.EndPage;

      // change the cell orientation to 90 degrees
      tbl.SetCellOrientation(-1, -1, 90);
      pdf.Append;
      pdf.SetFontA('Arial', fsRegular, 12.0, True, cp1252);
      pdf.WriteTextA(50.0, 50.0, 'The same table but the cell orientation was changed to 90 degrees.');
      tbl.DrawTable(50.0, 65.0, 742.0);
      while tbl.HaveMore do
      begin
        pdf.EndPage;
        pdf.Append;
        tbl.DrawTable(50.0, 50.0, 737.0);
      end;
      pdf.EndPage;

      tbl.DeleteTable;
    finally
      tbl.Free;
    end;

    err.StructSize := SizeOf(err);
    for i := 0 to pdf.GetErrLogMessageCount - 1 do
      if pdf.GetErrLogMessage(i, err) and (err.Msg <> nil) then
        Writeln(string(AnsiString(err.Msg)));

    if pdf.HaveOpenDoc then
    begin
      if not pdf.OpenOutputFileA('out.pdf') then Exit;
      if pdf.CloseFile then Writeln('Done: out.pdf');
    end;
  finally
    pdf.Free;
  end;
end.

program probe_test;
// Delphi OO example -- step-by-step probe of the TPDF flow + TPDFTable helper.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(Format('ERR %d: %s', [ErrCode, string(AnsiString(ErrMessage))]));
  Result := 0;
end;

var
  pdf: TPDF;
  tbl: TPDFTable;
  r: Integer;
  dir, outFile: string;
begin
  dir := ExtractFilePath(ParamStr(0));

  pdf := TPDF.Create;
  try
    Writeln('Create ok');
    pdf.SetOnErrorProc(nil, @ErrProc);
    Writeln(Format('CreateNewPDF('''') = %d', [Ord(pdf.CreateNewPDFA(''))]));
    Writeln(Format('SetPageCoords = %d', [Ord(pdf.SetPageCoords(Ord(pcTopDown)))]));
    Writeln(Format('Append = %d', [Ord(pdf.Append)]));
    Writeln(Format('SetFont = %d', [Ord(pdf.SetFontA('Arial', fsRegular, 12.0, True, cp1252))]));
    Writeln(Format('WriteText = %d', [Ord(pdf.WriteTextA(50, 50, 'probe'))]));

    tbl := TPDFTable.Create(pdf.CreateTable(3, 3, 500.0, 100.0));
    try
      Writeln('Table created');
      r := tbl.AddRow(-1.0);
      Writeln(Format('AddRow = %d', [r]));
      Writeln(Format('SetCellText = %d', [Ord(tbl.SetCellTextA(Cardinal(r), 0, taLeft, coTop, 'cell', Cardinal(-1)))]));
      Writeln(Format('DrawTable = %f', [tbl.DrawTable(50.0, 80.0, 700.0)]));
      Writeln(Format('HaveMore = %d', [Ord(tbl.HaveMore)]));
    finally
      tbl.DeleteTable;
      tbl.Free;
    end;

    Writeln(Format('EndPage = %d', [Ord(pdf.EndPage)]));
    Writeln(Format('GetPageCount = %d', [pdf.GetPageCount]));
    Writeln(Format('HaveOpenDoc = %d', [Ord(pdf.HaveOpenDoc)]));
    outFile := dir + 'probe_out.pdf';
    Writeln(Format('OpenOutputFile = %d', [Ord(pdf.OpenOutputFileA(PAnsiChar(AnsiString(outFile))))]));
    Writeln(Format('CloseFile = %d', [Ord(pdf.CloseFile)]));
  finally
    pdf.Free;
  end;
end.

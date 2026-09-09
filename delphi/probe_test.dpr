program probe_test;
{$APPTYPE CONSOLE}
// Step-by-step probe of the TPDF-class flow used by the console examples
// (CreateNewPDF('') in-memory + OpenOutputFile at the end + TPDFTable).
uses
  SysUtils,
  LumasPdfApi in 'include\LumasPdfApi.pas';

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln('ERR ', ErrCode, ': ', string(AnsiString(ErrMessage)));
  Result := 0;
end;

var pdf: TPDF; tbl: TPDFTable; outFile: string; r: Integer;
begin
  pdf := TPDF.Create;
  Writeln('Create ok');
  pdf.SetOnErrorProc(nil, @ErrProc);
  Writeln('CreateNewPDF('''') = ', pdf.CreateNewPDF(''));
  Writeln('SetPageCoords = ', pdf.SetPageCoords(pcTopDown));
  Writeln('Append = ', pdf.Append);
  Writeln('SetFont = ', pdf.SetFont('Arial', fsRegular, 12.0, true, cp1252));
  Writeln('WriteText = ', pdf.WriteText(50, 50, 'probe'));
  tbl := TPDFTable.Create(pdf, 3, 3, 500.0, 100.0);
  Writeln('Table created');
  r := tbl.AddRow(-1.0);
  Writeln('AddRow = ', r);
  Writeln('SetCellText = ', tbl.SetCellText(r, 0, taLeft, coTop, 'cell'));
  Writeln('DrawTable = ', tbl.DrawTable(50.0, 80.0, 700.0));
  Writeln('HaveMore = ', tbl.HaveMore);
  tbl.Free;
  Writeln('EndPage = ', pdf.EndPage);
  Writeln('GetPageCount = ', pdf.GetPageCount);
  Writeln('HaveOpenDoc = ', pdf.HaveOpenDoc);
  outFile := ExtractFilePath(ParamStr(0)) + 'probe_out.pdf';
  Writeln('OpenOutputFile = ', pdf.OpenOutputFile(outFile));
  Writeln('CloseFile = ', pdf.CloseFile);
  pdf.Free;
end.

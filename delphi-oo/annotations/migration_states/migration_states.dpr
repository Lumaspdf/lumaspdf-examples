program migration_states;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
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
  annot, reply: Integer;
  outFile: AnsiString;
begin
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');
    pdf.SetPageCoords(Ord(pcTopDown));

    pdf.Append;
    annot := pdf.SquareAnnotA(50.0, 50.0, 200.0, 100.0, 3.0, NO_COLOR, 255, csDeviceRGB, 'Jim', 'Test', 'Just test...');
    reply := pdf.SetAnnotMigrationStateA(annot, asCompleted, 'Harry');
    pdf.SetAnnotStringA(reply, Ord(asContent), 'The state was set to Completed!');

    reply := pdf.SetAnnotMigrationStateA(reply, asAccepted, 'Jim');
    pdf.SetAnnotStringA(reply, Ord(asContent), 'The state was set to Accepted!');
    pdf.EndPage;

    if pdf.HaveOpenDoc then
    begin
      outFile := AnsiString(ExtractFilePath(ParamStr(0)) + 'out.pdf');
      if not pdf.OpenOutputFileA(PAnsiChar(outFile)) then Exit;
      if pdf.CloseFile then
        Writeln('PDF file "' + string(outFile) + '" successfully created!');
    end;
  finally
    pdf.Free;
  end;
end.

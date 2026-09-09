program measure_lines;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf     in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO   in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

const
  clCream = 15793151;
  clBlack = 0;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TPDF;
  a: Integer;
  x, y, w, h: Double;
  outFile, txt: AnsiString;
  p: TLineAnnotParms;
begin
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');
    pdf.SetPageCoords(Ord(pcTopDown));

    pdf.Append;

    w := 300.0;
    h := 100.0;
    x := pdf.GetPageWidth / 2;
    y := pdf.GetPageHeight / 2;

    pdf.SaveGraphicState;

    pdf.SetGStateFlags(gfRealTopDownCoords, False);
    pdf.RotateCoords(-30.0, x, y);

    x := -w / 2;
    y := -h / 2;

    pdf.SetFillColor(clCream);
    pdf.Rectangle(x, y, w, h, Ord(fmFillStroke));

    txt := AnsiString(Format('%.1f', [w], TFormatSettings.Invariant));
    a := pdf.LineAnnotA(x, y, x + w, y, 1.0, leClosedArrow, leClosedArrow, clBlack, clBlack, csDeviceRGB, 'This is a measure line', 'Measure Line', PAnsiChar(txt));

    FillChar(p, SizeOf(p), 0);
    p.StructSize := SizeOf(p);
    p.Caption := True;                { Content of LineAnnot() is used as caption. }
    p.LeaderLineLen := 10.0;
    p.LeaderLineExtend := 4.0;
    p.LeaderLineOffset := 2.0;
    pdf.SetLineAnnotParms(a, -1, 0.0, @p);

    txt := AnsiString(Format('%.1f', [h], TFormatSettings.Invariant));
    a := pdf.LineAnnotA(x, y + h, x, y, 1.0, leClosedArrow, leClosedArrow, clBlack, clBlack, csDeviceRGB, 'This is a measure line', 'Measure Line', PAnsiChar(txt));
    pdf.SetLineAnnotParms(a, -1, 0.0, @p);

    pdf.RestoreGraphicState;

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

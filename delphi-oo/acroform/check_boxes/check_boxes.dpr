program check_boxes;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf     in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO   in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

const
  clLtGray = 12632256;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TPDF;
  act, f, r: Integer;
  y: Double;
  outFile: AnsiString;
begin
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');
    pdf.SetPageCoords(Ord(pcTopDown));

    pdf.Append;
    pdf.SetFontA('Helvetica', fsRegular, 10.0, False, cp1252);
    pdf.WriteTextA(50.0, 50.0, 'Normal check boxes.');

    pdf.ChangeFontSize(1.0);
    f := pdf.CreateCheckBox('N1', 'C1', 1, -1, 50.0, 70.0, 20.0, 20.0);
    pdf.SetCheckBoxDefState(f, True);
    f := pdf.CreateCheckBox('N2', 'C2', 1, -1, 80.0, 70.0, 20.0, 20.0);
    pdf.SetCheckBoxDefState(f, True);
    f := pdf.CreateCheckBox('N3', 'C1', 1, -1, 110.0, 70.0, 20.0, 20.0);
    pdf.SetCheckBoxDefState(f, True);

    pdf.ChangeFontSize(10.0);
    pdf.WriteTextA(50.0, 100.0, 'Field group with check boxes.');

    pdf.ChangeFontSize(1.0);
    pdf.CreateCheckBox('G1', 'C1', 0, -1, 50.0, 120.0, 20.0, 20.0);
    pdf.CreateCheckBox('G1', 'C2', 0, -1, 80.0, 120.0, 20.0, 20.0);
    pdf.CreateCheckBox('G1', 'C1', 1, -1, 110.0, 120.0, 20.0, 20.0);

    pdf.ChangeFontSize(10.0);
    pdf.WriteFTextExA(50.0, 150.0, 220.0, -1.0, Ord(taLeft),
      'This group works like a radio button but only radio buttons get a round border if the check box character is set to ccCircle. No problem, set the border width to zero and draw the circle in background if needed.');

    y := pdf.GetPageHeight - pdf.GetLastTextPosY + 10.0;

    pdf.ChangeFontSize(1.0);
    pdf.SetCheckBoxChar(Ord(ccCircle));
    pdf.CreateCheckBox('G2', 'C1', 0, -1, 50.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('G2', 'C2', 0, -1, 80.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('G2', 'C3', 1, -1, 110.0, y, 20.0, 20.0);

    pdf.ChangeFontSize(10.0);
    pdf.WriteFTextExA(300.0, 50.0, 250.0, -1.0, Ord(taLeft),
      'This is a radio button. Since Acrobat 7 it is no longer possible to deselect the active check box, except with a reset form or Javascript action.');

    y := pdf.GetPageHeight - pdf.GetLastTextPosY + 10.0;

    pdf.ChangeFontSize(15.0);
    r := pdf.CreateRadioButton('Radio1', 'R1', 1, -1, 300.0, y, 20.0, 20.0);
    pdf.SetCheckBoxDefState(r, False);
    pdf.CreateCheckBox('', 'R2', 0, r, 330.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('', 'R3', 0, r, 360.0, y, 20.0, 20.0);

    pdf.ChangeFontSize(10.0);
    f := pdf.CreateButtonA('Reset', 'Reset', -1, 400.0, y, 60.0, 20.0);
    pdf.SetFieldColor(f, Ord(fcBackColor), Ord(csDeviceRGB), clLtGray);
    pdf.SetFieldBorderStyle(f, Ord(bsBevelled));

    act := pdf.CreateResetAction;
    pdf.AddActionToObj(Ord(otField), Ord(oeOnMouseUp), act, f);
    pdf.AddFieldToFormAction(act, r, True);

    y := y + 40.0;
    pdf.ChangeFontSize(10.0);
    pdf.WriteFTextExA(300.0, y, 250.0, -1.0, Ord(taLeft),
      'The RadioIsUnion flag has only an effect if at least two check boxes use the same export value.');
    y := pdf.GetPageHeight - pdf.GetLastTextPosY + 10.0;

    pdf.ChangeFontSize(15.0);
    r := pdf.CreateRadioButton('Radio2', 'R1', 1, -1, 300.0, y, 20.0, 20.0);
    pdf.SetFieldFlags(r, ffRadioIsUnion, False);
    pdf.CreateCheckBox('', 'R2', 0, r, 330.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('', 'R1', 1, r, 360.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('', 'R2', 0, r, 390.0, y, 20.0, 20.0);
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

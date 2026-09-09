program field_groups;
// PURE VCL static example -- engine linked into this exe (LUMAS_STATIC), no LumasPdf.dll.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  Lumas.Pdf.Types,
  Lumas.Pdf.Wrap.Core;

const
  clLtGray = 12632256;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
  act, f: Integer;
  base, y: Double;
  outFile: AnsiString;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');
    pdf.SetPageCoords(Ord(pcTopDown));

    pdf.Append;
    pdf.SetFontA('Helvetica', fsRegular, 12.0, False, cp1252);
    pdf.SetLeading(14.0);
    pdf.WriteFTextExA(50.0, 50.0, pdf.GetPageWidth - 100.0, -1.0, Ord(taJustify),
      'The six text fields share the same value. Such an array of fields is called a field group. All fields in the group must be of the same type.'#13#13 +
      'A field group can be created in two different ways: either create two or more fields with the same name or pass the handle of the base field as Parent to the children. ' +
      'The latter way is more efficient since it is not required to search for the parent field when a child will be created.'#13#13 +
      'Enter some more text into a field to see the difference between auto size and fixed font size.');

    base := pdf.GetPageHeight - pdf.GetLastTextPosY + 20.0;

    pdf.WriteFTextExA(50.0, base, 200.0, -1.0, Ord(taLeft), 'Font size <= 1.0 means auto size.');

    y := pdf.GetPageHeight - pdf.GetLastTextPosY + 10.0;

    pdf.ChangeFontSize(1.0);
    f := pdf.CreateTextField('Auto', -1, 0, 0, 50.0, y, 200.0, 20.0);
    pdf.SetTextFieldValueA(f, 'Some text...', 'Some text...', taLeft);

    y := y + 30.0;
    pdf.CreateTextField('', f, 0, 0, 50.0, y, 200.0, 30.0);

    y := y + 40.0;
    pdf.CreateTextField('', f, 0, 0, 50.0, y, 200.0, 40.0);

    pdf.ChangeFontSize(12.0);
    pdf.WriteFTextExA(345.0, base, 200.0, -1.0, Ord(taLeft), 'The same fields with a fixed font size.');

    y := pdf.GetPageHeight - pdf.GetLastTextPosY + 10.0;

    pdf.ChangeFontSize(12.0);
    pdf.CreateTextField('', f, 0, 0, 345.0, y, 200.0, 20.0);

    y := y + 30.0;
    pdf.ChangeFontSize(24.0);
    pdf.CreateTextField('', f, 0, 0, 345.0, y, 200.0, 30.0);

    y := y + 40.0;
    pdf.ChangeFontSize(34.0);
    pdf.CreateTextField('', f, 0, 0, 345.0, y, 200.0, 40.0);

    pdf.ChangeFontSize(18.0);
    f := pdf.CreateButtonA('Reset', 'Reset', -1, 222.5, y + 80.0, 150.0, 25.0);
    pdf.SetFieldColor(f, Ord(fcBackColor), Ord(csDeviceRGB), clLtGray);
    pdf.SetFieldBorderStyle(f, Ord(bsBevelled));

    act := pdf.CreateResetAction;
    pdf.AddActionToObj(Ord(otField), Ord(oeOnMouseUp), act, f);
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

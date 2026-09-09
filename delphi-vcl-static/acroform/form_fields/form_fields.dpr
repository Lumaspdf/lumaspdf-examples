program form_fields;
// PURE VCL static example -- engine linked into this exe (LUMAS_STATIC), no LumasPdf.dll.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  Lumas.Pdf.Types,
  Lumas.Pdf.Wrap.Core;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
  f, r: Integer;
  y: Double;
  outFile: AnsiString;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');
    pdf.SetPageCoords(Ord(pcTopDown));

    pdf.Append;
    y := 50.0;
    pdf.SetFontA('Helvetica', fsRegular, 10.0, False, cp1252);
    pdf.WriteTextA(50.0, y, 'Text fields:');

    y := y + 15.0;
    f := pdf.CreateTextField('Text1', -1, 0, 0, 50.0, y, 200.0, 20.0);
    pdf.SetTextFieldValueA(f, '', 'Single line text...', taLeft);

    y := y + 30.0;
    f := pdf.CreateTextField('Text2', -1, 1, 0, 50.0, y, 200.0, 50.0);
    pdf.SetTextFieldValueA(f, '', 'This field accepts multi-line text. The maximum text length can be restricted if necessary.', taLeft);

    y := y + 60.0;
    pdf.WriteTextA(50.0, y, 'A password field:');
    y := y + 15.0;
    f := pdf.CreateTextField('Text3', -1, 0, 0, 50.0, y, 200.0, 20.0);
    pdf.SetFieldFlags(f, ffPassword, False);
    pdf.SetTextFieldValueA(f, '', '**********', taLeft);

    y := y + 30.0;
    pdf.WriteTextA(50.0, y, 'A fixed length field separated into combs:');
    y := y + 15.0;
    f := pdf.CreateTextField('Text4', -1, 0, 10, 50.0, y, 200.0, 20.0);
    pdf.SetFieldFlags(f, ffComb, False);

    y := 50.0;
    pdf.WriteTextA(350.0, y, 'Choice fields:');
    y := y + 15.0;
    f := pdf.CreateComboBox('Combo1', 1, -1, 350.0, y, 200.0, 20.0);
    pdf.AddValToChoiceFieldA(f, '', ' Select a value...', 1);
    pdf.AddValToChoiceFieldA(f, 'Apple', 'Apple', 0);
    pdf.AddValToChoiceFieldA(f, 'Banana', 'Banana', 0);
    pdf.AddValToChoiceFieldA(f, 'Pear', 'Pear', 0);
    pdf.AddValToChoiceFieldA(f, 'Grape', 'Grape', 0);
    pdf.AddValToChoiceFieldA(f, 'Orange', 'Orange', 0);

    y := y + 30.0;
    f := pdf.CreateListBox('List', True, -1, 350.0, y, 200.0, 50.0);
    pdf.AddValToChoiceFieldA(f, 'Apple', 'Apple', 0);
    pdf.AddValToChoiceFieldA(f, 'Banana', 'Banana', 1);
    pdf.AddValToChoiceFieldA(f, 'Pear', 'Pear', 0);
    pdf.AddValToChoiceFieldA(f, 'Grape', 'Grape', 0);
    pdf.AddValToChoiceFieldA(f, 'Orange', 'Orange', 0);

    y := y + 60.0;
    pdf.WriteTextA(350.0, y, 'Editable combo box:');
    y := y + 15.0;
    f := pdf.CreateComboBox('Combo2', 1, -1, 350.0, y, 200.0, 20.0);
    pdf.AddValToChoiceFieldA(f, 'Apple', 'Apple', 0);
    pdf.AddValToChoiceFieldA(f, 'Banana', 'Banana', 0);
    pdf.AddValToChoiceFieldA(f, 'Pear', 'Pear', 0);
    pdf.AddValToChoiceFieldA(f, 'Grape', 'Grape', 0);
    pdf.AddValToChoiceFieldA(f, 'Orange', 'Orange', 0);
    pdf.SetFieldFlags(f, ffEdit, False);
    pdf.SetFieldExpValueA(f, 1000, 'Select or enter a value...', '', True);

    y := y + 30.0;
    pdf.WriteTextA(350.0, y, 'Check boxes / Radio buttons:');

    y := y + 15.0;
    pdf.ChangeFontSize(1.0);
    pdf.CreateCheckBox('N1', 'C1', 1, -1, 350.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('N2', 'C2', 1, -1, 380.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('N3', 'C1', 1, -1, 410.0, y, 20.0, 20.0);

    pdf.CreateCheckBox('G1', 'C1', 0, -1, 450.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('G1', 'C2', 0, -1, 480.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('G1', 'C1', 1, -1, 510.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('G1', 'C2', 0, -1, 540.0, y, 20.0, 20.0);

    y := y + 30.0;
    pdf.ChangeFontSize(15.0);
    pdf.SetCheckBoxChar(Ord(ccCircle));
    r := pdf.CreateRadioButton('Radio1', 'R1', 1, -1, 350.0, y, 20.0, 20.0);
    pdf.SetCheckBoxDefState(r, False);
    pdf.CreateCheckBox('', 'R2', 0, r, 380.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('', 'R3', 0, r, 410.0, y, 20.0, 20.0);

    r := pdf.CreateRadioButton('Radio2', 'R1', 1, -1, 450.0, y, 20.0, 20.0);
    pdf.SetFieldFlags(r, ffRadioIsUnion, False);
    pdf.CreateCheckBox('', 'R2', 0, r, 480.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('', 'R1', 1, r, 510.0, y, 20.0, 20.0);
    pdf.CreateCheckBox('', 'R2', 0, r, 540.0, y, 20.0, 20.0);
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

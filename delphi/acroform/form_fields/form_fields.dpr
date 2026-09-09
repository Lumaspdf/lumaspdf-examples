program image_extraction;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  Classes,
  {$IF RTLVersion >= 23}Vcl.{$IFEND}Graphics,
  ShellAPI,
  LumasPdfApi in '..\..\include\LumasPdfApi.pas';

{
   Note that the dynapdf.dll must be copied into the output directory or into a
   Windwos search path (e.g. %WINDOWS%/System32) before the application can be executed!
}

// Error callback function.
// If the function name should not appear at the beginning of the error message set
// the flag emNoFuncNames (pdf.SetErrorMode(emNoFuncNames);). 
function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

procedure CreateFormFields;
var f, r: Integer; y: double; pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      pdf.SetPageCoords(pcTopDown);

      pdf.Append;
         y := 50.0;
         pdf.SetFont('Helvetica', fsRegular, 10.0, false, cp1252);
         pdf.WriteText(50.0, y, 'Text fields:');

         y := y + 15.0;
         f := pdf.CreateTextField('Text1', -1, false, 0, 50.0, y, 200.0, 20.0);
         pdf.SetTextFieldValue(f, '', 'Single line text...', taLeft);

         y := y + 30.0;
         f := pdf.CreateTextField('Text2', -1, true, 0, 50.0, y, 200.0, 50.0);
         pdf.SetTextFieldValue(f, '', 'This field accepts multi-line text. The maximum text length can be restricted if necessary.', taLeft);

         y := y + 60.0;
         pdf.WriteText(50.0, y, 'A password field:');
         y := y + 15.0;
         f := pdf.CreateTextField('Text3', -1, false, 0, 50.0, y, 200.0, 20.0);
         pdf.SetFieldFlags(f, ffPassword, false);
         pdf.SetTextFieldValue(f, '', '**********', taLeft);

         y := y + 30.0;
         pdf.WriteText(50.0, y, 'A fixed length field separated into combs:');
         y := y + 15.0;
         f := pdf.CreateTextField('Text4', -1, false, 10, 50.0, y, 200.0, 20.0);
         pdf.SetFieldFlags(f, ffComb, false);


         y := 50.0;
         pdf.WriteText(350.0, y, 'Choice fields:');
         y := y + 15.0;
         f := pdf.CreateComboBox('Combo1', true, -1, 350.0, y, 200.0, 20.0);
         pdf.AddValToChoiceField(f, '', ' Select a value...', true);
         pdf.AddValToChoiceField(f, 'Apple',  'Apple',  false);
         pdf.AddValToChoiceField(f, 'Banana', 'Banana', false);
         pdf.AddValToChoiceField(f, 'Pear',   'Pear',   false);
         pdf.AddValToChoiceField(f, 'Grape',  'Grape',  false);
         pdf.AddValToChoiceField(f, 'Orange', 'Orange', false);

         y := y + 30.0;
         f := pdf.CreateListBox('List', true, -1, 350.0, y, 200.0, 50.0);
         pdf.AddValToChoiceField(f, 'Apple',  'Apple',  false);
         pdf.AddValToChoiceField(f, 'Banana', 'Banana', true);
         pdf.AddValToChoiceField(f, 'Pear',   'Pear',   false);
         pdf.AddValToChoiceField(f, 'Grape',  'Grape',  false);
         pdf.AddValToChoiceField(f, 'Orange', 'Orange', false);

         y := y + 60.0;
         pdf.WriteText(350.0, y, 'Editable combo box:');
         y := y + 15.0;
         f := pdf.CreateComboBox('Combo2', true, -1, 350.0, y, 200.0, 20.0);
         pdf.AddValToChoiceField(f, 'Apple',  'Apple',  false);
         pdf.AddValToChoiceField(f, 'Banana', 'Banana', false);
         pdf.AddValToChoiceField(f, 'Pear',   'Pear',   false);
         pdf.AddValToChoiceField(f, 'Grape',  'Grape',  false);
         pdf.AddValToChoiceField(f, 'Orange', 'Orange', false);
         pdf.SetFieldFlags(f, ffEdit, false);
         pdf.SetFieldExpValue(f, 1000, 'Select or enter a value...', '', true);

         y := y + 30.0;
         pdf.WriteText(350.0, y, 'Check boxes / Radio buttons:');

         y := y + 15.0;
         pdf.ChangeFontSize(1.0);
         pdf.CreateCheckBox('N1', 'C1', true, -1, 350.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('N2', 'C2', true, -1, 380.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('N3', 'C1', true, -1, 410.0, y, 20.0, 20.0);

         pdf.CreateCheckBox('G1', 'C1', false, -1, 450.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('G1', 'C2', false, -1, 480.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('G1', 'C1', true,  -1, 510.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('G1', 'C2', false, -1, 540.0, y, 20.0, 20.0);

         y := y + 30.0;
         pdf.ChangeFontSize(15.0);
         pdf.SetCheckBoxChar(ccCircle);
         r := pdf.CreateRadioButton('Radio1', 'R1', true, -1, 350.0, y, 20.0, 20.0);
         pdf.SetCheckBoxDefState(r, false);
         pdf.CreateCheckBox('', 'R2', false, r, 380.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('', 'R3', false, r, 410.0, y, 20.0, 20.0);

         r := pdf.CreateRadioButton('Radio2', 'R1', true, -1, 450.0, y, 20.0, 20.0);
         pdf.SetFieldFlags(r, ffRadioIsUnion, false);
         pdf.CreateCheckBox('', 'R2', false, r, 480.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('', 'R1', true,  r, 510.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('', 'R2', false, r, 540.0, y, 20.0, 20.0);

      pdf.EndPage;
      // No fatal error occurred?
      if pdf.HaveOpenDoc then begin
         // We write the file into the application directory.
         GetDir(0, outFile);
         outFile := outFile + '\out.pdf';
         if not pdf.OpenOutputFile(outFile) then begin
            pdf.Free;
            Readln;
            Exit;
         end;
         if pdf.CloseFile then begin
            Writeln(Format('PDF file "%s" successfully created!', [outFile]));
            ShellExecute(0, PChar('open'), PChar(OutFile), nil, nil, SW_SHOWMAXIMIZED);
         end;
      end;
   except
      on E: Exception do begin
         Writeln(E.Message);
      end;
   end;
   if pdf <> nil then pdf.Free;
end;
  
begin
   CreateFormFields;
end.

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

procedure CreateCheckBoxes();
var act, f, r: Integer; y: double; pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;

      pdf.SetOnErrorProc(nil, PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      pdf.SetPageCoords(pcTopDown);

      pdf.Append;
         pdf.SetFont('Helvetica', fsRegular, 10.0, false, cp1252);
         pdf.WriteText(50.0, 50.0, 'Normal check boxes.');

         pdf.ChangeFontSize(1.0);
         f := pdf.CreateCheckBox('N1', 'C1', true, -1, 50.0,  70.0, 20.0, 20.0);
         pdf.SetCheckBoxDefState(f, true);
         f := pdf.CreateCheckBox('N2', 'C2', true, -1, 80.0,  70.0, 20.0, 20.0);
         pdf.SetCheckBoxDefState(f, true);
         f := pdf.CreateCheckBox('N3', 'C1', true, -1, 110.0, 70.0, 20.0, 20.0);
         pdf.SetCheckBoxDefState(f, true);

         pdf.ChangeFontSize(10.0);
         pdf.WriteText(50.0, 100.0, 'Field group with check boxes.');

         pdf.ChangeFontSize(1.0);
         pdf.CreateCheckBox('G1', 'C1', false, -1, 50.0, 120.0, 20.0, 20.0);
         pdf.CreateCheckBox('G1', 'C2', false, -1, 80.0, 120.0, 20.0, 20.0);
         pdf.CreateCheckBox('G1', 'C1', true, -1, 110.0, 120.0, 20.0, 20.0);

         pdf.ChangeFontSize(10.0);
         pdf.WriteFTextEx(50.0, 150.0, 220.0, -1.0, taLeft, 'This group works like a radio button but only radio buttons get a round border if the check box character is set to ccCircle. No problem, set the border width to zero and draw the circle in background if needed.');

         y := pdf.GetPageHeight - pdf.GetLastTextPosY + 10.0;

         pdf.ChangeFontSize(1.0);
         pdf.SetCheckBoxChar(ccCircle);
         pdf.CreateCheckBox('G2', 'C1', false, -1, 50.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('G2', 'C2', false, -1, 80.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('G2', 'C3', true, -1, 110.0, y, 20.0, 20.0);


         pdf.ChangeFontSize(10.0);
         pdf.WriteFTextEx(300.0, 50.0, 250.0, -1.0, taLeft, 'This is a radio button. Since Acrobat 7 it is no longer possible to deselect the active check box, except with a reset form or Javascript action.');

         y := pdf.GetPageHeight - pdf.GetLastTextPosY + 10.0;

         pdf.ChangeFontSize(15.0);
         r := pdf.CreateRadioButton('Radio1', 'R1', true, -1, 300.0, y, 20.0, 20.0);
         pdf.SetCheckBoxDefState(r, false);
         pdf.CreateCheckBox('', 'R2', false, r, 330.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('', 'R3', false, r, 360.0, y, 20.0, 20.0);

         pdf.ChangeFontSize(10.0);
         f := pdf.CreateButton('Reset', 'Reset', -1, 400.0, y, 60.0, 20.0);
         pdf.SetFieldColor(f, fcBackColor, csDeviceRGB, clLtGray);
         pdf.SetFieldBorderStyle(f, bsBevelled);

         act := pdf.CreateResetAction;
         pdf.AddActionToObj(otField, oeOnMouseUp, act, f);
         pdf.AddFieldToFormAction(act, r, true);

         y := y + 40.0;
         pdf.ChangeFontSize(10.0);
         pdf.WriteFTextEx(300.0, y, 250.0, -1.0, taLeft, 'The RadioIsUnion flag has only an effect if at least two check boxes use the same export value.');
         y := pdf.GetPageHeight - pdf.GetLastTextPosY + 10.0;

         pdf.ChangeFontSize(15.0);
         r := pdf.CreateRadioButton('Radio2', 'R1', true, -1, 300.0, y, 20.0, 20.0);
         pdf.SetFieldFlags(r, ffRadioIsUnion, false);
         pdf.CreateCheckBox('', 'R2', false, r, 330.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('', 'R1', true, r, 360.0, y, 20.0, 20.0);
         pdf.CreateCheckBox('', 'R2', false, r, 390.0, y, 20.0, 20.0);
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
   CreateCheckBoxes();
end.

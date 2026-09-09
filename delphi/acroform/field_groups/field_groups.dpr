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
   Note that the LumasPdf.dll must be copied into the output directory or into a
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

procedure CreateFieldGroup;
var act, f: Integer; base, y: double; pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      pdf.SetPageCoords(pcTopDown);

      pdf.Append;
         pdf.SetFont('Helvetica', fsRegular, 12.0, false, cp1252);
         pdf.SetLeading(14.0);
         pdf.WriteFTextEx(50.0, 50.0, pdf.GetPageWidth - 100.0, -1.0, taJustify,
            'The six text fields share the same value. Such an array of fields is called a field group. All fields in the group must be of the same type.'#13#13
           +'A field group can be created in two different ways: either create two or more fields with the same name or pass the handle of the base field as Parent to the children. '
           +'The latter way is more efficient since it is not required to search for the parent field when a child will be created.'#13#13
           +'Enter some more text into a field to see the difference between auto size and fixed font size.');

         // GetLastTextPosY() returns bottom up coordinates. We must subtract the value from the page height.
         base := pdf.GetPageHeight - pdf.GetLastTextPosY + 20.0;

         pdf.WriteFTextEx(50.0, base, 200.0, -1.0, taLeft, 'Font size <= 1.0 means auto size.');

         y := pdf.GetPageHeight - pdf.GetLastTextPosY + 10.0;

         pdf.ChangeFontSize(1.0);
         f := pdf.CreateTextField('Auto', -1, false, 0, 50.0, y, 200.0, 20.0);
         pdf.SetTextFieldValue(f, 'Some text...', 'Some text...', taLeft);

         y := y + 30.0;
         pdf.CreateTextField('', f, false, 0, 50.0, y, 200.0, 30.0);

         y := y + 40.0;
         pdf.CreateTextField('', f, false, 0, 50.0, y, 200.0, 40.0);

         pdf.ChangeFontSize(12.0);
         pdf.WriteFTextEx(345.0, base, 200.0, -1.0, taLeft, 'The same fields with a fixed font size.');

         y := pdf.GetPageHeight - pdf.GetLastTextPosY + 10.0;

         pdf.ChangeFontSize(12.0);
         pdf.CreateTextField('', f, false, 0, 345.0, y, 200.0, 20.0);

         y := y +  30.0;
         pdf.ChangeFontSize(24.0);
         pdf.CreateTextField('', f, false, 0, 345.0, y, 200.0, 30.0);

         y := y + 40.0;
         pdf.ChangeFontSize(34.0);
         pdf.CreateTextField('', f, false, 0, 345.0, y, 200.0, 40.0);

         pdf.ChangeFontSize(18.0);
         f := pdf.CreateButton('Reset', 'Reset', -1, 222.5, y + 80.0, 150.0, 25.0);
         pdf.SetFieldColor(f, fcBackColor, csDeviceRGB, clLtGray);
         pdf.SetFieldBorderStyle(f, bsBevelled);

         act := pdf.CreateResetAction;
         pdf.AddActionToObj(otField, oeOnMouseUp, act, f);
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
   CreateFieldGroup;
end.

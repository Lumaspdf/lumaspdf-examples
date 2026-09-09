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

procedure CreateFormFields;
var a: Integer; pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      pdf.SetPageCoords(pcTopDown);

      pdf.Append;

        // A pre-defined stamp is scaled to the given width. The language can be set right before creating the stamp.
        a := pdf.StampAnnot(rsApproved, 135.0, 50.0, 300.0, 10.0, 'Test app', 'Stamp Annotations', 'The default language is English!');
        pdf.SetAnnotColor(a, fcBorderColor, csDeviceRGB, rgb(120, 190, 92));

        pdf.SetLanguage('DE');
        a := pdf.StampAnnot(rsApproved, 135.0, 150.0, 300.0, 10.0, 'Test app', 'Stamp Annotations', 'The same stamp in German!');
        pdf.SetAnnotColor(a, fcBorderColor, csDeviceRGB, rgb(230, 65, 132));

        pdf.SetLanguage('FR');
        a := pdf.StampAnnot(rsApproved, 135.0, 250.0, 300.0, 10.0, 'Test app', 'Stamp Annotations', 'The same stamp in French!');
        pdf.SetAnnotColor(a, fcBorderColor, csDeviceRGB, rgb(78, 157, 232));

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

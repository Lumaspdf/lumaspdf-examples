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
var d, w: double; pdf: TPDF; outFile, text: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      pdf.SetPageCoords(pcTopDown);

      pdf.Append;
         text := 'Some text on a page...';
         pdf.SetFont('Helvetica', fsRegular, 20.0, false, cp1252);

         d := pdf.GetDescent;
         w := pdf.GetTextWidth(text);

         pdf.WriteText(50.0, 50.0, text);
         pdf.HighlightAnnot(atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, 'Test app', 'Highligh Annotations', 'This is a highlight annotation');

         pdf.WriteText(50.0, 80.0, text);
         pdf.HighlightAnnot(atSquiggly, 50.0, 80.0 + d, w, 20.0, clRed, 'Test app', 'Squiggly Annotations', 'This is a squiggly annotation');

         pdf.WriteText(50.0, 110.0, text);
         pdf.HighlightAnnot(atStrikeOut, 50.0, 110.0 + d, w, 20.0, clRed, 'Test app', 'Strikeout Annotations', 'This is a strikeout annotation');

         pdf.WriteText(50.0, 140.0, text);
         pdf.HighlightAnnot(atUnderline, 50.0, 140.0 + d, w, 20.0, clRed, 'Test app', 'Underline Annotations', 'This is a underline annotation');
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

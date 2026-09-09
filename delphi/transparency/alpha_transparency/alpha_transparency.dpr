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
// the flag emNoFuncNames (pdf..SetErrorMode(emNoFuncNames);). 
function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

procedure TransparentObject;
var gs, img: Integer; pdf: TPDF; outFile: String; g: TPDFExtGState;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later
      
      pdf.SetPageCoords(pcTopDown);

      // Disable color key masking for images
      pdf.SetUseTransparency(false);

      pdf.Append;

         pdf.SetFont('Helvetica', fsRegular, 12.0, false, cp1252);
         pdf.WriteText(50.0, 50.0, 'Fill Alpha = 0.5');

         pdf.Rectangle(50.0, 70.0, 110.0, 160.0, fmFill);
         pdf.SetFillColor(clWhite);
         pdf.WriteText(55.0, 75.0, 'Background');

         pdf.InitExtGState(g);
         g.FillAlpha := 0.5;
         gs := pdf.CreateExtGState(g);
         pdf.SetExtGState(gs);

         img := pdf.InsertImageEx(60.0, 84.0, 200.0, 0.0, '../../../test_files/images/tree-frog-69813_640.jpg', 0);

         // To restore an extended graphics state, create a second one that restores the changes made before and activate this state.
         g.FillAlpha := 1.0;
         gs := pdf.CreateExtGState(g);
         pdf.SetExtGState(gs);

         pdf.SetFillColor(clBlack);
         pdf.WriteText(340.0, 50.0, 'Fill Alpha = 1.0 (default)');
         pdf.Rectangle(340.0, 70.0, 110.0, 160.0, fmFill);
         pdf.SetFillColor(clWhite);
         pdf.WriteText(345.0, 75.0, 'Background');
         pdf.PlaceImage(img, 350.0, 84.0, 200.0, 0.0);

      pdf.EndPage;
      
      // No fatal error occurred?
      if pdf.HaveOpenDoc then begin
         // We write the file into the application directory.
         GetDir(0, outFile);
         outFile := outFile + '\out.pdf.';
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
   TransparentObject;
end.

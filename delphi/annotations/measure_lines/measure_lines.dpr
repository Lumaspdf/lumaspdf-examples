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

procedure CreateMeasureLines;
var a: Integer; x, y, w, h: double; pdf: TPDF; outFile, txt: String; p: TLineAnnotParms;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      pdf.SetPageCoords(pcTopDown);

      pdf.Append;

         w := 300.0;
         h := 100.0;
         x := pdf.GetPageWidth  / 2;
         y := pdf.GetPageHeight / 2;

         // We save the graphics state because the coordinate system will be rotated.
         // After RestoreGraphicState() we have the non-rotated coordinate system back.
         pdf.SaveGraphicState;

            pdf.SetGStateFlags(gfRealTopDownCoords, false); // This simplifies the handling a little bit.
            pdf.RotateCoords(-30.0, x, y);

            x := -w / 2;
            y := -h / 2;

            pdf.SetFillColor(clCream);
            pdf.Rectangle(x, y, w, h, fmFillStroke);

            txt := Format('%.1f', [w]);
            a := pdf.LineAnnot(x, y, x + w, y, 1.0, leClosedArrow, leClosedArrow, clBlack, clBlack, csDeviceRGB, 'This is a measure line', 'Measure Line', txt);

            FillChar(p, SizeOf(p), 0);
            p.StructSize       := SizeOf(p);
            p.Caption          := true;      // The parameter Content of LineAnnot() is used as caption.
            p.LeaderLineLen    := 10.0;
            p.LeaderLineExtend := 4.0;       // Try different values to understand what these parameters change.
            p.LeaderLineOffset := 2.0;
            pdf.SetLineAnnotParms(a, -1, 0.0, @p);

            txt := Format('%.1f', [h]);
            a := pdf.LineAnnot(x, y+h, x, y, 1.0, leClosedArrow, leClosedArrow, clBlack, clBlack, csDeviceRGB, 'This is a measure line', 'Measure Line', txt);
            // The parameters are exactly the same as above
            pdf.SetLineAnnotParms(a, -1, 0.0, @p);

         pdf.RestoreGraphicState;

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
   CreateMeasureLines;
end.


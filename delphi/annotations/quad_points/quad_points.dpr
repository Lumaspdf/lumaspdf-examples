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

procedure IncY(Points: PFltPoint; Count: Cardinal; Value: Single);
begin
   while (Count > 0) do begin
      Points^.y := Points^.y + Value;
      Dec(Count);
      Inc(Points);
   end;
end;

procedure CreateFormFields;
var a: Integer; d, w: Single; pdf: TPDF; outFile, text: String; points: Array[0..3]of TFltPoint;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      pdf.SetPageCoords(pcTopDown);

      pdf.Append;

         pdf.SaveGraphicState;

            pdf.SetGStateFlags(gfRealTopDownCoords, false); // This simplifies the handling a little bit.
            pdf.RotateCoords(-30, 50.0, 200.0);

            text := 'Some rotated text on a page...';
            pdf.SetFont('Helvetica', fsRegular, 20.0, false, cp1252);

            d := pdf.GetDescent;
            w := pdf.GetTextWidth(text);

            // Highlight annotations do not consider coordinate transformations made on a page.
            // To get such annotations rotated we must set the annotation's quad points.
            // SetAnnotQuadPoints() considers transformations of the coordinate system.

            pdf.WriteText(0.0, 0.0, text);
            a := pdf.HighlightAnnot(atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, 'Test app', 'Highligh Annotations', 'This is a highlight annotation');
            // Consider the unusual order of the points!
            points[0].x := 0.0;      // x1 -> Top left corner
            points[0].y := d;        // y1 -> Top left corner
            points[1].x := w;        // x2 -> Top right corner
            points[1].y := d;        // y2 -> Top right corner
            points[2].x := 0.0;      // x3 -> Bottom left corner
            points[2].y := 20.0 + d; // y3 -> Bottom left corner
            points[3].x := w;        // x4 -> Bottom right corner
            points[3].y := 20.0 + d; // y4 -> Bottom right corner
            pdf.SetAnnotQuadPoints(a, @points[0], 4);

            pdf.WriteText(0.0, 30.0, text);
            a := pdf.HighlightAnnot(atSquiggly, 50.0, 80.0, w, 20.0, clRed, 'Test app', 'Squiggly Annotations', 'This is a squiggly annotation');
            // Update the y-coordinates
            IncY(@points[0], 4, 30.0);
            pdf.SetAnnotQuadPoints(a, @points[0], 4);

            pdf.WriteText(0.0, 60.0, text);
            a := pdf.HighlightAnnot(atStrikeOut, 50.0, 110.0, w, 20.0, clRed, 'Test app', 'Strikeout Annotations', 'This is a strikeout annotation');
            // Update the y-coordinates
            IncY(@points[0], 4, 30.0);
            pdf.SetAnnotQuadPoints(a, @points[0], 4);

            pdf.WriteText(0.0, 90.0, text);
            a := pdf.HighlightAnnot(atUnderline, 50.0, 140.0, w, 20.0, clRed, 'Test app', 'Underline Annotations', 'This is a underline annotation');
            // Update the y-coordinates
            IncY(@points[0], 4, 30.0);
            pdf.SetAnnotQuadPoints(a, @points[0], 4);

            text := 'Link annotations support quad points too';
            w    := pdf.GetTextWidth(text);
            pdf.WriteText(0.0, 120.0, text);
            // Link annotations support quad points too.
            a := pdf.WebLink(0.0, 120.0, w, 20, 'www.dynaforms.com');
            pdf.SetAnnotBorderWidth(a, 1.0);
            pdf.SetAnnotColor(a, fcBorderColor, csDeviceRGB, clBlue);
            points[0].x := 0.0;       // x1 -> Top left corner
            points[0].y := 120.0 + d; // y1 -> Top left corner
            points[1].x := w;         // x2 -> Top right corner
            points[1].y := 120.0 + d; // y2 -> Top right corner
            points[2].x := 0.0;       // x3 -> Bottom left corner
            points[2].y := 140.0 + d; // y3 -> Bottom left corner
            points[3].x := w;         // x4 -> Bottom right corner
            points[3].y := 140.0 + d; // y4 -> Bottom right corner
            pdf.SetAnnotQuadPoints(a, @points[0], 4);

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
   CreateFormFields;
end.

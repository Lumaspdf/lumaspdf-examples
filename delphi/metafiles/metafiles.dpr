program metafiles;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  ShellAPI,
  Classes,
  LumasPdfApi in '..\include\LumasPdfApi.pas';

{
   Note that the dynapdf.dll must be copied into the output directory or into a
   Windwos search path (e.g. %WINDOWS%/System32) before the application can be executed!
}

// Error callback function.
// If the function name should not appear at the beginning of the error message set
// the flag emNoFuncNames (pdf.SetErrorMode(emNoFuncNames);). 
function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

const CLR_RED: Cardinal = 255;
const MARGIN:  Double   = 10.0;

procedure PlaceEMFCentered(PDF: TPDF; const MFile: String; Width, Height: Double); overload;
var x, y, w, h, sx: Double; r: TRectL;
begin
   PDF.GetLogMetafileSize(AnsiString(MFile), r);
   w      := r.Right - r.Left;
   h      := r.Bottom - r.Top;
   Width  := Width  - 2.0 * MARGIN;
   Height := Height - 2.0 * MARGIN;
   sx := Width / w;

   if (h * sx <= Height) then begin
      x := MARGIN;
      h := h * sx;
      // If the file should not be centered vertically then set y to MARGIN.
      y := (Height - h) / 2.0;

      PDF.InsertMetafile(AnsiString(MFile), x, y, Width, 0.0);
      PDF.SetStrokeColor(CLR_RED);
      PDF.Rectangle(x, y, Width, h, fmStroke);
   end else begin
      sx := Height / h;
      w  := w * sx;
      x  := (Width - w) / 2.0;
      y  := MARGIN;
      PDF.InsertMetafile(AnsiString(MFile), x, y, 0.0, Height);
      PDF.SetStrokeColor(CLR_RED);
      PDF.Rectangle(x, y, w, Height, fmStroke);
   end;
end;

procedure DrawMetafiles();
var pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create();
      pdf.SetOnErrorProc(nil, @ErrProc);
      if not pdf.CreateNewPDF('') then begin // The output file is opened later
         pdf.Free;
         Exit;
      end;

      pdf.SetPageCoords(pcTopDown);

      pdf.Append;
      {
         We use a landscape paper format in this example. SetOrientationEx() rotates the coordinate
         system according to the orientation and sets the page orientation. You can now work with page
         as if it was not rotated. The real page format is still DIN A4 (this is the default format).
         The difference to SetOrientation() is that this function does not change the page's coordinate
         system.

         It would also be possible to use a user defined paper format without changing the page
         orientation but the disadvantage is that a printer driver must then manually rotate the page
         because landscape paper formats do not exist in most printers. This step requires an
         additional interaction with the user which is simply not required when creating landscape
         paper formats in the right way.
      }
      pdf.SetOrientationEx(90);

      // This file transforms the coordinate system very often and uses clipping regions. The metafile
      // is scaled to the page width without changing its aspect ratio.
      PlaceEMFCentered(pdf, '../../test_files/coords.emf', pdf.GetPageWidth, pdf.GetPageHeight);
      pdf.EndPage;

      pdf.Append;
      pdf.SetOrientationEx(90);
      // Simple test of line and standard patterns
      PlaceEMFCentered(pdf, '../../test_files/fulltest.emf', pdf.GetPageWidth, pdf.GetPageHeight);
      pdf.EndPage;

      pdf.Append;
      pdf.SetOrientationEx(90);
      // Simple test of line and standard patterns
      PlaceEMFCentered(pdf, '../../test_files/gdi.emf', pdf.GetPageWidth, pdf.GetPageHeight);
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
      end;
      if pdf.CloseFile then begin
         Writeln(Format('PDF file "%s" successfully created!', [outFile]));
         ShellExecute(0, PChar('open'), PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
      end;
   except
      on E: Exception do Writeln(E.Message);
   end;
   if pdf <> nil then pdf.Free;
end;
  
begin
   DrawMetafiles;
end.

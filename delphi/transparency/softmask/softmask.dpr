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
// the flag emNoFuncNames (pdf..SetErrorMode(emNoFuncNames);). 
function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

procedure CreateSoftMask;
var gs, grp, sh: Integer; pdf: TPDF; outFile: String; g: TPDFExtGState; bbox: TPDFRect;
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
         pdf.WriteText(50.0, 50.0, 'Transparency effect with a soft mask.');

         pdf.InsertImageEx(50.0, 80.0, pdf.GetPageWidth - 100.0, 0.0, '../../../test_files/images/meadow-110719_640.jpg', 1);

         // Note that a transparency group that it used as soft mask has no own coordinate system. The esiest way to avoid coordinate
         // issues is to create the transparency group in the full size of the page or template in which it is used. The real bounding
         // box can be computed after the transparency group was fully defined.
         grp := pdf.BeginTransparencyGroup(0.0, 0.0, pdf.GetPageWidth, pdf.GetPageHeight, true, false, esDeviceGray, -1);
            pdf.SetColorSpace(csDeviceGray);
            sh := pdf.CreateRadialShading(400.0, 230.0, 20.0, 400.0, 230.0, 150.0, 1.0, 255, 0, true, false);
            pdf.ApplyShading(sh);
            // Optional but recommended: Compute the real bounding of the group if it is used as soft mask.
            pdf.ComputeBBox(bbox, cbfNone);
            pdf.SetBBox(pbMediaBox, bbox.Left, bbox.Bottom, bbox.Right, bbox.Top);
         pdf.EndTemplate;

         pdf.InitExtGState(g);
         g.SoftMask := pdf.CreateSoftMask(grp, smtLuminosity, 0);
         gs := pdf.CreateExtGState(g);

         // Activate the mask and draw an image
         pdf.SetExtGState(gs);
         pdf.InsertImageEx(220.0, 80.0, 500.0, 0.0, '../../../test_files/images/tree-frog-69813_640.jpg', 1);

         // The soft mask can be deactivated as follows:
         pdf.InitExtGState(g);
         g.SoftMaskNone := true;
         gs := pdf.CreateExtGState(g);
         pdf.SetExtGState(gs);

         pdf.WriteText(50.0, 400.0, 'The soft mask is now deactivated.');
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
   CreateSoftMask;
end.

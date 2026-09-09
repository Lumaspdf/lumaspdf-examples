program signature_ap;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, ShellAPI, LumasPdfApi in '..\include\LumasPdfApi.pas';

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

procedure TestSignatureAP();
var sigField, sh: Integer; pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.CreateNewPDF(''); // The output file is opened later
      pdf.SetOnErrorProc(nil, @ErrProc);

      pdf.Append;
      pdf.SetFont('Arial', fsNone, 14.0, true, cp1252);
      pdf.WriteFText(taLeft, 'This file is digitally signed with a self sign certificate. '
         + 'The appearance of the signature field is created with normal classic-API functions. However, it '
         + 'would also be possible to import a PDF page, an EMF file, or an image into the '
         + 'appearance template.'#10#10
         + 'When creating an individual signature appearance make sure to place the validation icon '
         + 'properly with PlaceSigFieldValidateIcon(). The appearance of the validation icon '
         + 'depends on the Acrobat version with which the file is opened. However, the unscaled size '
         + 'of that icon is always 100.0 x 100.0 Units. It can be scaled to every size you want '
         + 'but it is usually best to preserve the aspect ratio and the icon must be placed fully '
         + 'inside the appearance template.');

      { ---------------------- Signature field appearance ---------------------- }

      sigField := pdf.CreateSigField('Signature', -1, 200.0, 500.0, 200.0, 80.0);
      pdf.SetFieldColor(sigField, fcBorderColor, csDeviceRGB, NO_COLOR);
      // Place the validation icon on the left side of the signature field.
      pdf.PlaceSigFieldValidateIcon(sigField, 0.0, 15.0, 50.0, 50.0);
      {
         This function creates a template into which you can draw whatever you want. The template
         is already opened when calling the function; it must be closed when finish with EndTemplate().
         An appearance template of a signature field is reserved for this field. It must not be placed
         on another page!

         In addition, it makes no sense to create an appearance template when the file is not digitally
         signed later. Empty signature fields cannot contain a user defined appearance.
      }
      pdf.CreateSigFieldAP(sigField);

      pdf.SaveGraphicState;
      pdf.Rectangle(0.0, 0.0, 200.0, 80.0, fmNoFill);
      pdf.ClipPath(cmWinding, fmNoFill);
      sh := pdf.CreateAxialShading(0.0, 0.0, 200.0, 0.0, 0.5, RGB(120, 120, 220), RGB(255,255,255), true, true);
      pdf.ApplyShading(sh);
      pdf.RestoreGraphicState;

      pdf.SaveGraphicState;
      pdf.Ellipse(50.5, 1.0, 148.5, 78.0, fmNoFill);
      pdf.ClipPath(cmWinding, fmNoFill);
      sh := pdf.CreateAxialShading(0.0, 0.0, 0.0, 78.0, 2.0, RGB(255,255,255), RGB(120, 120, 220), true, true);
      pdf.ApplyShading(sh);
      pdf.RestoreGraphicState;

      pdf.SetFont('Arial', fsBold or fsUnderlined, 11.0, true, cp1252);
      pdf.SetFillColor(RGB(120, 120, 220));
      pdf.WriteFTextEx(50.0, 60.0, 150.0, -1.0, taCenter, 'Digitally signed by:');
      pdf.SetFont('Arial', fsBold or fsItalic, 18.0, true, cp1252);
      pdf.SetFillColor(RGB(100, 100, 200));
      pdf.WriteFTextEx(50.0, 45.0, 150.0, -1.0, taCenter, 'LumasPDF');

      pdf.EndTemplate; // Close the appearance template.

      { ------------------------------------------------------------------------ }

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
      {
         Note: If the certificate cannot be found or when using a wrong password the PDF file is still
         in memory. This is required to enable entering another password or certificate file.
         The function can be called in a while statement if the user should be able to enter
         another password or certificate file. However, if it is not possible to sign the file
         successfully then you must free the resources manually by calling FreePDF. In this example,
         the entire PDF instance is freed whether or not the file could be signed. This is safe because
         Free() makes always sure that all resources are freed.
      }
      if pdf.CloseAndSignFile('../../test_files/test_cert.pfx', '123456', 'Test', '') then begin
         Writeln(Format('PDF file "%s" successfully created!', [outFile]));
         ShellExecute(0, PChar('open'), PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
      end;
   except
      on E: Exception do Writeln(E.Message);
   end;
   if pdf <> nil then pdf.Free;
   Readln;
end;

begin
   TestSignatureAP;
end.

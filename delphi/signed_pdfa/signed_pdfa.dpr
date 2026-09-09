program signed_pdfa;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, ShellAPI, LumasPdfApi in '..\include\LumasPdfApi.pas';

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

procedure TestSignedPDFA();
var sigField, sh: Integer; pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.CreateNewPDF(''); // The output file is opened later
      pdf.SetOnErrorProc(nil, @ErrProc);

      pdf.Append;
      pdf.SetFont('Arial', fsNone, 10.0, true, cp1252);
      pdf.WriteFText(taLeft, 'This is a PDF/A 1b compatible PDF file that was digitally signed with '
         +'a self sign certificate. Because PDF/A requires that all fonts are embedded it is important '
         +'to avoid the usage of the 14 Standard fonts.'#13#13

         +'When signing a PDF/A compliant PDF file with the default settings (without creation of a user '
         +'defined appearance) the font Arial must be available on the system because it is used to print '
         +'the certificate properties into the signature field.'#13#13

         +'The font Arial must also be available if an empty signature field was added to the file '
         +'without signing it when closing the PDF file. Yes, it is still possible to sign a PDF/A '
         +'compliant PDF file later with Adobe''s Acrobat. The signed PDF file is still compatible '
         +'to PDF/A. If you use a third party solution to digitally sign the PDF file then test '
         +'whether the signed file is still valid with the PDF/A 1b preflight tool included in Acrobat 8 '
         +'Professional.'#13#13

         +'Signature fields must be visible and the print flag must be set (default). CheckConformance() '
         +'adjusts these flags if necessary and produces a warning if changes were applied. If no changes '
         +'should be allowed, just return -1 in the error callback function. If the error callback function '
         +'returns 0, DynaPDF assumes that the prior changes were accepted and processing continues.'#13#13

         +'\FC[255]Notice:\FC[0]'#13
         +'It makes no sense to execute CheckConformance() without an error callback function or error event '
         +'in VB. If you cannot see what happens during the execution of CheckConformance(), it is '
         +'completely useless to use this function!'#13#13

         +'CheckConformance() should be used to find the right settings to create PDF/A compatible PDF files. '
         +'Once the the settings were found it is usually not longer recommended to execute this function. '
         +'However, it is of course possible to use CheckConformance() as a general approach to make sure '
         +'that files created with DynaPDF are PDF/A compatible.');

      { ---------------------- Signature field appearance ---------------------- }

      sigField := pdf.CreateSigField('Signature', -1, 200.0, 400.0, 200.0, 80.0);
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
      pdf.WriteFTextEx(50.0, 45.0, 150.0, -1.0, taCenter, 'DynaPDF');

      pdf.EndTemplate; // Close the appearance template.

      { ------------------------------------------------------------------------ }

      pdf.EndPage;
      // Check whether the file is compatible to PDF/A 1b
      // Note that the CMYK profile is just an example profile that can be delivered with DynaPDF.
      case (pdf.CheckConformance(ctPDFA_1b_2005, 0, nil, nil, nil)) of
         1, 3: pdf.AddOutputIntent('../../test_files/sRGB.icc');             // Gray, RGB
         2:    pdf.AddOutputIntent('../../test_files/ISOcoated_v2_bas.ICC'); // CMYK
      end;
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
end;

begin
   TestSignedPDFA;
end.

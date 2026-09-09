program attach_invoice;

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

procedure AttachInvoice;
var ef: Integer; pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      // Set the license key here if you have one
      // pdfSetLicenseKey(pdf, '');

      // We assume that the pdf invoice is already a valid PDF/A 3 file in this example.

      pdf.SetImportFlags(ifImportAsPage or ifImportAll);
      pdf.OpenImportFile('../../../test_files/test_invoice.pdf', ptOpen, '');

      pdf.ImportPDFFile(1, 1.0, 1.0);

      ef := pdf.AttachFile('../../../test_files/factur-x.xml', 'EN 16931 compliant invoice', false);
      pdf.AssociateEmbFile(adCatalog, -1, arAlternative, ef);

      {
         Note that ZUGFeRD 2.1 or higher and FacturX is identically defined in PDF. Therefore, both formats share
         the same version constants. Note also that the profiles Minimum, Basic, and Basic WL are not fully EN 16931
         compliant and hence cannot be used to create e-invoices.
      }
      pdf.SetPDFVersion(pvFacturX_Comfort);
      
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
   FreeAndNil(pdf);
end;
  
begin
   AttachInvoice;
end.

program multiple_signatures;

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

function SignFile(const PDF: TPDF; InFileName, OutFileName: String; FieldName, Reason: AnsiString; PosX: Double; VisibleSignature: Boolean): Boolean;
var filePath, outName, s: String; sig: Integer;
begin
   Result  := false;
   outName := OutFileName;
   if InFileName = OutFileName then begin
      SetLength(filePath, MAX_PATH+1);
      s := '.'; // For compatibility to Delphi 6...
      if GetTempFileName(@s[1], nil, 0, @filePath[1]) = 0 then Exit;
      filePath := PChar(filePath);
      outName  := filePath;
   end;

   PDF.CreateNewPDF(outName);

   {
      Adding multiple signatures with a demo version of LumasPDF couldn't work since a demo string would
      be added to each page that was edited or changed and this would invalidate previous signatures.
   }
   PDF.SetLicenseKey('SigDemo');

   // This flag also sets the flags ifImportAsPage | ifImportAll, and if2UseProxy | if2CopyEncryptDict to make sure that
   // anything is imported and nothing gets changed.
   PDF.SetImportFlags2(if2IncrementalUpd);
   if PDF.OpenImportFile(InFileName, ptOpen, '') < 0 then Exit;
   PDF.ImportPDFFile(1, 1.0, 1.0);

   if VisibleSignature then begin
      PDF.SetPageCoords(pcTopDown);
      PDF.EditPage(1);
         sig := PDF.CreateSigField(FieldName, -1, PosX, 30.0, 180.0, 40.0);
         PDF.SetFieldBorderWidth(sig, 0.0);
      PDF.EndPage;
   end;
   Result := PDF.CloseAndSignFile('../../../test_files/test_cert.pfx', '123456', Reason, '');
   if Result then begin
      if outName = filePath then begin
         DeleteFile(OutFileName);
         Result := MoveFileEx(PChar(outName), PChar(OutFileName), MOVEFILE_COPY_ALLOWED or MOVEFILE_WRITE_THROUGH);
      end;
   end;
end;

procedure RunSignatureTest;
var pdf: TPDF; filePath: String;
begin
   try
   	pdf := TPDF.Create;

      PDF.SetOnErrorProc(nil, @PDFError);

      // We write the output file into the current directory.
      GetDir(0, filePath);
      filePath := filePath + '\out.pdf';

      // We sign the file 4 times in this example. We add two visible and two invisible signatures.
      if SignFile(pdf, '../../../../license.PDF', filePath, 'Signature1', 'Test signature 1', 50.0, true) then begin
         if SignFile(pdf, filePath, filePath, 'Signature2', 'Test signature 2', 430.0, true) then begin
            if SignFile(pdf, filePath, filePath, '', 'Test signature 3', 0.0, false) then begin
               if SignFile(pdf, filePath, filePath, '', 'Test signature 4', 0.0, false) then begin
                  Writeln(Format('PDF file "%s" successfully created!\n', [filePath]));
                  ShellExecute(0, PChar('open'), PChar(filePath), nil, nil, SW_SHOWMAXIMIZED);
               end;
            end;
         end;
      end;
   finally
      FreeAndNil(pdf);
   end;
end;

begin
   RunSignatureTest;
end.

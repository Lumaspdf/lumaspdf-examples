program image_extraction;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  Classes,
  {$IF RTLVersion >= 23}Vcl.{$IFEND}Graphics,
  ShellAPI,
  LumasPdfApi in '..\include\LumasPdfApi.pas';

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

procedure SplitPDF;
var i, count: Integer; pdf: TPDF; outPath: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);

      pdf.SetImportFlags(ifImportAll or ifImportAsPage); // Import anything and avoid the conversion of pages to templates
      pdf.SetImportFlags2(if2UseProxy);                  // This flag reduces the memory usage.
      if pdf.OpenImportFile('../../../license.pdf', ptOpen, '') < 0 then begin
         pdf.Free;
         Exit;
      end;

      // Very important: This property makes sure that the open import file will not be closed
      // when CloseFile() is called.
      pdf.SetUseGlobalImpFiles(true);

      count := pdf.GetInPageCount;
      for i := 1 to count do begin
         outPath := Format('out/page%.4d.pdf', [i]);
         pdf.CreateNewPDF(outPath);
            pdf.Append;
               pdf.ImportPageEx(i, 1.0, 1.0);
            pdf.EndPage;
         pdf.CloseFile;
      end;
      // You should never forget to set the property back to false when finish.
      // In this example it makes no difference but if the PDF instance is used 
      // to create or import other PDF files then make sure that the parser instance
      // can be deleted.
      pdf.SetUseGlobalImpFiles(false);

      // Open the output directory
      outPath := ExpandFileName('out');
      ShellExecute(0, PChar('open'), PChar(outPath), nil, nil, SW_SHOWMAXIMIZED);
   except
      on E: Exception do begin
         Writeln(E.Message);
      end;
   end;
   if pdf <> nil then pdf.Free;
end;
  
begin
   SplitPDF;
end.

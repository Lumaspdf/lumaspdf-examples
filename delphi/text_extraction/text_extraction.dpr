program text_extraction;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  ShellAPI,
  Classes,
  LumasPdfApi in '..\include\LumasPdfApi.pas',
  pdf_to_text in 'pdf_to_text.pas';

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

procedure ExtractText();
var i: Integer; parser: CPDFToText; pdf: TPDF; outFile: String;
begin
   pdf    := nil;
   parser := nil;
   try
      pdf     := TPDF.Create;
      parser  := CPDFToText.Create(pdf);
      pdf.CreateNewPDF(''); // We do not produce a PDF file in this example
      pdf.SetOnErrorProc(nil, @ErrProc);

      // External cmaps should always be loaded when extracting text from PDF files.
      // See the description of ParseContent() for further information.
      pdf.SetCMapDir(ExpandFileName('../../../Resource/CMap'), lcmRecursive or lcmDelayed);

      // We avoid the conversion of pages to templates
      pdf.SetImportFlags(ifImportAll or ifImportAsPage);
      if pdf.OpenImportFile('../../../dynapdf_help.pdf', ptOpen, '') < 0 then begin
         pdf.Free;
         ReadLn;
         Exit;
      end;
      pdf.ImportPDFFile(1, 1.0, 1.0);
      pdf.CloseImportFile;

      // We flatten markup annotations and form fields so that we can extract the text of these objects too.
      pdf.FlattenAnnots(affMarkupAnnots);
      pdf.FlattenForm();
      
      // We write the output file into the current directory.
      GetDir(0, outFile);
      outFile := outFile + '\out.txt';
      parser.Open(outFile);

      // Note that page numbering starts at 1!
      for i := 1 to pdf.GetPageCount do begin
         pdf.EditPage(i); // Open the page
         parser.WritePageIdentifier(i);
         parser.ParsePage;
         pdf.EndPage; // Close the page
      end;
      Writeln(Format('Text successfully extracted to "%s"', [outFile]));
      ShellExecute(0, PChar('open'), PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
   except
      on E: Exception do Writeln(E.Message);
   end;
   if parser <> nil then parser.Free;
   if pdf <> nil then pdf.Free;
end;

begin
   ExtractText;
end.

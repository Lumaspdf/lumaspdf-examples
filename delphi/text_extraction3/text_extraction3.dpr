program text_extraction3;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  Classes,
  ShellAPI,
  LumasPdfApi in '..\include\LumasPdfApi.pas';

{
   Note that the LumasPdf.dll must be copied into the output directory or into a
   Windwos search path (e.g. %WINDOWS%/System32) before the application can be executed!
}

procedure WritePageIdentifier(F: TFileStream; PageNum: Integer);
var identifier: WideString;
begin
   if PageNum > 1 then begin
      // Add a new line to the output file
      F.Write(PWideChar(WideString(#13#10))^, 4);
   end;
   // Note that the page marker must be written as WideString. An Ansi string is automatically
   // converted to Unicode when passing it to a WideString variable.
   identifier := Format('%%----------------------- Page %d -----------------------------'#13#10, [PageNum]);
   F.Write(identifier[1], Length(identifier) * 2);
end;

// Error callback function.
// If the function name should not appear at the beginning of the error message set
// the flag emNoFuncNames (pdf..SetErrorMode(emNoFuncNames);). 
function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

procedure ExtractText;
var i, cnt: Integer; pdf: TPDF; f: TFileStream; outFile: String; outText: WideString;
begin
   pdf := nil;
   f   := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // We do not create a PDF file in this example

      // External cmaps should always be loaded when extracting text from PDF files.
      // This should be an absolute path to avoid issues when the active directory changes.
      pdf.SetCMapDir(ExpandFileName('../../../Resource/CMap'), lcmRecursive or lcmDelayed);

      // Import anything and don't convert pages to templates
      pdf.SetImportFlags(ifImportAll or ifImportAsPage);
      if pdf.OpenImportFile('../../../sample_multipage.pdf', ptOpen, '') < 0 then begin
         pdf.Free;
         Exit;
      end;
      pdf.ImportPDFFile(1, 1.0, 1.0);
      pdf.CloseImportFile;

      // We flatten markup annotations and form fields so that we can extract the text from these objects too.
      pdf.FlattenAnnots(affMarkupAnnots);
      pdf.FlattenForm;
      
      GetDir(0, outFile);
      outFile := outFile + '\out.txt';
      f := TFileStream.Create(outFile, fmCreate);
      // UTF-16LE BOM (Byte Order Mark)
      f.Write(PAnsiChar(#255#254)^, 2);

      cnt := pdf.GetPageCount;
      for i := 1 to cnt do begin 
         WritePageIdentifier(f, i);
         // It is not recommended to sort text on the y-axis since causes sometimes strange results.
         if pdf.ExtractText(i, tefDeleteOverlappingText or tefSortTextX, nil, outText) then begin
            if Length(outText) > 0 then f.Write(outText[1], Length(outText) * 2);
         end;
      end;
      FreeAndNil(f);
      ShellExecute(0, PChar('open'), PChar(OutFile), nil, nil, SW_SHOWMAXIMIZED); 
   except
      on E: Exception do begin
         Writeln(E.Message);
      end;
   end;
   if f   <> nil then f.Free;
   if pdf <> nil then pdf.Free;
end;
  
begin
   ExtractText;
end.

program edit_text;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  DateUtils,
  ShellAPI,
  Classes,
  LumasPdfApi in '..\include\LumasPdfApi.pas';

{
   Note that the LumasPdf.dll must be copied into the output directory or into a
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

procedure ReplaceText();
var i: Integer; pdf: TPDF; outFile: String; ctx: TPDFContentParser; content: TContent;
    curr: PTextSelection; sel: TTextSelection; searchText, replaceText: WideString;
begin
   pdf := nil;
   ctx := nil;
   try
      pdf := TPDF.Create;

      pdf.CreateNewPDF(''); // The output file is opened later
      pdf.SetOnErrorProc(nil, @ErrProc);
      // Avoid the conversion of pages to templates
      pdf.SetImportFlags(ifImportAll or ifImportAsPage);
      if pdf.OpenImportFile('../../../sample_multipage.pdf', ptOpen, '') < 0 then begin
         pdf.Free;
         ReadLn;
         Exit;
      end;
      pdf.ImportPDFFile(1, 1.0, 1.0);
      pdf.CloseImportFile;

      ctx := TPDFContentParser.Create(pdf, ofDefault, nil);
      searchText  := 'PDF'; // This string occurs of course very often in the help file
      replaceText := 'XDF'; // Just an example. Use also a longer or shorter string to see what happens...
      
      for i := 1 to pdf.GetPageCount do begin
         // The flag cpfEnableTextSelection is required. Otherwise no text can be found.
         if ctx.ParsePage(i, cpfEnableTextSelection, nil, content) then begin
            curr := nil;
            // Find and replace all occurrences of the search string
            while ctx.FindText(nil, stDefault, curr, searchText, sel) do begin
               // Set the replacement string to an empty string one time to see how surrounding text will be handled...
               // With psrSetAltFont() you can also set the preferred alternate font to output the new text if the
               // original font is not available on the system.
               ctx.ReplaceSelText(rtfDefault, sel, replaceText);
               curr := @sel;
            end;
            ctx.WriteToPage(ofDefault, nil);
         end;
      end;
      FreeAndNil(ctx);
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
      on E: Exception do begin
         // LumasPDF error messages are already handled in the error callback function.
         // We display the error message only if a non-LumasPDF error occurred.
         if E.Message <> '-1' then Writeln(E.Message);
      end;
   end;
   if ctx <> nil then ctx.Free;
   if pdf <> nil then pdf.Free;
end;

begin
   ReplaceText;
end.
 
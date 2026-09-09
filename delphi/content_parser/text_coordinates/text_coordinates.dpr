program text_coordinates;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  ShellAPI,
  Classes,
  LumasPdfApi in '..\..\include\LumasPdfApi.pas',
  pdf_text_coordinates in 'pdf_text_coordinates.pas',
  pdf_callBack in 'pdf_callback.pas';

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

procedure MarkTextCoords();
var i: Integer; pdf: TPDF; stack: TPDFParseInterface; textCoords: CTextCoordinates; outFile: String;
begin
   pdf        := nil;
   textCoords := nil;
   {
      This example draws lines under each text record of a PDF file to check whether the
      coordinate calculations are correct. To visualize how the text is stored in the PDF
      file the line color changes from blue to red or vice versa each time a new text
      record is processed.
   }
   FillChar(stack, sizeof(stack), 0);
   stack.BeginTemplate       := parseBeginTemplate;
   stack.EndTemplate         := parseEndTemplate;
   stack.MulMatrix           := parseMulMatrix;
   stack.RestoreGraphicState := parseRestoreGraphicState;
   stack.SaveGraphicState    := parseSaveGraphicState;
   stack.SetCharSpacing      := parseSetCharSpacing;
   stack.SetFont             := parseSetFont;
   stack.SetTextDrawMode     := parseSetTextDrawMode;
   stack.SetTextScale        := parseSetTextScale;
   stack.SetWordSpacing      := parseSetWordSpacing;
   stack.ShowTextArrayW      := parseShowTextArrayW;

   try
      pdf        := TPDF.Create;
      textCoords := CTextCoordinates.Create(pdf);
      pdf.SetOnErrorProc(nil, @ErrProc);
      pdf.CreateNewPDF(''); // We create no PDF file in this example

      // External cmaps should always be loaded when extracting text from PDF files.
      // See the description of ParseContent() for further information.
      pdf.SetCMapDir(ExpandFileName('../../../../Resource/CMap'), lcmRecursive or lcmDelayed);

      // We avoid the conversion of pages to templates
      pdf.SetImportFlags(ifImportAll or ifImportAsPage);
      if pdf.OpenImportFile(ExpandFileName('../../../../sample_multipage.pdf'), ptOpen, '') < 0 then begin
         Writeln('Input file "../../../../sample_multipage.pdf" not found!');
         pdf.Free;
         textCoords.Free;
         ReadLn;
         Exit;
      end;
      if pdf.ImportPDFFile(1, 1.0, 1.0) < 0 then begin
         pdf.Free;
         textCoords.Free;
         ReadLn;
         Exit;
      end;
      // We flatten markup annotations and form fields so that we can process the text from these objects too.
      pdf.FlattenAnnots(affMarkupAnnots);
      pdf.FlattenForm;

      for i := 1 to pdf.GetPageCount do begin
         pdf.EditPage(i);
         pdf.SetLineWidth(0.5);
         textCoords.Init;
         pdf.ParseContent(textCoords, stack, pfNone);
         pdf.EndPage();
      end;
      textCoords.Free;
      textCoords := nil;
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
   if textCoords <> nil then textCoords.Free;
   Readln;
end;

begin
   MarkTextCoords;
end.

program text_extraction2;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  ShellAPI,
  LumasPdfApi in '..\..\include\LumasPdfApi.pas',
  pdf_text_extraction in '..\..\util\pdf_text_extraction.pas',
  pdf_callBack in '..\..\util\pdf_callback.pas';

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

procedure FindPDFText();
var i: Integer; pdf: TPDF; stack: TPDFParseInterface; textStack: CPDFToText; outFile: String;
begin
   pdf       := nil;
   textStack := nil;
   {
      This example extracts the text of a PDF file in the same way as pdf_to_text.
      However, pdf_to_text is already a relatively large project and not so easy
      to understand.
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
      pdf       := TPDF.Create;
      textStack := CPDFToText.Create(pdf);
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
         textStack.Free;
         Exit;
      end;
      if pdf.ImportPDFFile(1, 1.0, 1.0) < 0 then begin
         pdf.Free;
         textStack.Free;
         ReadLn;
         Exit;
      end;
      // We flatten markup annotations and form fields so that we can extract the text from these objects too.
      pdf.FlattenAnnots(affMarkupAnnots);
      pdf.FlattenForm;
      // The output file must be opened before the parser is executed.
      // We write the file into the application directory.
      GetDir(0, outFile);
      outFile := outFile + '\out.txt';
      textStack.Open(outFile);
      for i := 1 to pdf.GetPageCount do begin
         pdf.EditPage(i);
         textStack.Init;
         textStack.WritePageIdentifier(i);
         pdf.ParseContent(textStack, stack, pfNone);
         pdf.EndPage();
      end;
      textStack.Close;
      Writeln(Format('Text successfully extracted to "%s"', [outFile]));
      ShellExecute(0, PChar('open'), PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
   except
      on E: Exception do Writeln(E.Message);
   end;
   if pdf <> nil then pdf.Free;
   if textStack <> nil then textStack.Free;
end;

begin
   FindPDFText;
end.

program text_search;

{$APPTYPE CONSOLE}

uses
  ShellAPI,
  SysUtils,
  Windows,
  LumasPdfApi in '..\..\include\LumasPdfApi.pas',
  pdf_callback in 'pdf_callback.pas',
  pdf_text_search in 'pdf_text_search.pas';


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

procedure FindPDFText();
var i, gs, selCount: Integer; pdf: TPDF; stack: TPDFParseInterface; textSearch: CTextSearch; g: TPDFExtGState; outFile: String;
begin
   pdf        := nil;
   selCount   := 0;
   textSearch := nil;

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
   stack.ShowTextArrayA      := parseShowTextArrayA;

   try
      pdf        := TPDF.Create;
      textSearch := CTextSearch.Create(pdf);
      pdf.SetOnErrorProc(nil, @ErrProc);
      pdf.CreateNewPDFA(''); // The output file wil be created later

      // External cmaps should always be loaded when extracting text from PDF files.
      // See the description of ParseContent() for further information.
      pdf.SetCMapDirA(ExpandFileName('../../../../Resource/CMap'), lcmRecursive or lcmDelayed);

      // We avoid the conversion of pages to templates
      pdf.SetImportFlags(ifImportAll or ifImportAsPage);
      if pdf.OpenImportFileA(ExpandFileName('../../../../dynapdf_help.pdf'), ptOpen, '') < 0 then begin
         Writeln('Input file "../../../../dynapdf_help.pdf" not found!');
         pdf.Free;
         textSearch.Free;
         ReadLn;
         Exit;
      end;
      if pdf.ImportPDFFile(1, 1.0, 1.0) < 0 then begin
         pdf.Free;
         textSearch.Free;
         ReadLn;
         Exit;
      end;
      // We flatten markup annotations and form fields so that we can search the text in these objects too.
      pdf.FlattenAnnots(affMarkupAnnots);
      pdf.FlattenForm;

      // The search text must be defined in Unicode. Delphi converts literal strings automatically.
      textSearch.SetSearchText('PDF');

      // We draw rectangles on the position where the search string was found. To make the text
      // in background visible we use the blend mode bmMultiply. Adobes Acrobat rasters a page
      // without anti-aliasing when a blend mode is used. Don't wonder that the rasterizing
      // quality is worse in comparison to normal PDF files.
      pdf.InitExtGState(g);
      g.BlendMode := bmMultiply;
      gs := pdf.CreateExtGState(g);

      for i := 1 to pdf.GetPageCount do begin
         pdf.EditPage(i);

         pdf.SetExtGState(gs);
         pdf.SetFillColor(rgb(255, 255, 0));

         textSearch.Init();
         pdf.ParseContent(textSearch, stack, pfNone);
         pdf.EndPage();
         if textSearch.GetSelCount() > 0 then begin
            Inc(selCount, textSearch.GetSelCount);
            WriteLn(Format('Found string on Page: %d %d times!', [i, textSearch.GetSelCount()]));
         end;
      end;
      textSearch.Free;
      textSearch := nil;
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
   WriteLn(Format(#10'Found string in the file %d times!', [selCount]));
   if pdf <> nil then pdf.Free;
   if textSearch <> nil then textSearch.Free;
   Readln;
end;

begin
   FindPDFText;
end.

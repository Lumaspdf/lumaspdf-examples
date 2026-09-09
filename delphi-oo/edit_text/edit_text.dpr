program edit_text;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class).
// Imports sample_multipage.pdf, replaces every "PDF" with "XDF" via the parser context.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TPDF;
  ctx: IPSR;
  i: Integer;
  dir, inFile, outFile: string;
  content: TContent;
  sel: TTextSelection;
  curr: PTextSelection;
  searchText, replaceText: WideString;
begin
  searchText := 'PDF';
  replaceText := 'XDF';
  dir := ExtractFilePath(ParamStr(0));

  pdf := TPDF.Create;
  try
    pdf.CreateNewPDFA('');
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.SetImportFlags(ifImportAll or ifImportAsPage);

    inFile := dir + 'sample_multipage.pdf';
    if pdf.OpenImportFileA(PAnsiChar(AnsiString(inFile)), ptOpen, '') < 0 then Exit;
    pdf.ImportPDFFile(1, 1.0, 1.0);
    pdf.CloseImportFile;

    ctx := pdf.CreateParserContext(ofDefault, nil);

    for i := 1 to pdf.GetPageCount do
    begin
      if pdf.ParsePage(ctx, nil, nil, i, cpfEnableTextSelection, nil, content) then
      begin
        curr := nil;
        while pdf.FindText(ctx, nil, stDefault, curr, PWideChar(searchText), Length(searchText), sel) do
        begin
          pdf.ReplaceSelText(ctx, rtfDefault, sel, PWideChar(replaceText), Length(replaceText));
          curr := @sel;
        end;
        pdf.WriteToPage(ctx, ofDefault, nil);
      end;
    end;
    psrDeleteParserContext(ctx);

    if pdf.HaveOpenDoc then
    begin
      outFile := dir + 'out.pdf';
      if not pdf.OpenOutputFileA(PAnsiChar(AnsiString(outFile))) then Exit;
    end;
    if pdf.CloseFile then
      Writeln('PDF file "' + outFile + '" successfully created!');
  finally
    pdf.Free;
  end;
end.

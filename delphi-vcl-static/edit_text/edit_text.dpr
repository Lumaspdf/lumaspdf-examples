program edit_text;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC). No LumasPdf.dll.
// Imports sample_multipage.pdf, replaces every "PDF" with "XDF" via the parser context.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Types,              // engine enums / IPSR / TContent
  Lumas.Pdf.ApiTypes,           // parser types (TTextSelection, cpfEnableTextSelection, stDefault, rtfDefault)
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore (flat API as methods)

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
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

  pdf := TLumasPDFCore.Create;
  try
    pdf.CreateNewPDFA('');
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.SetImportFlags(ifImportAll or ifImportAsPage);

    inFile := dir + 'sample_multipage.pdf';
    if pdf.OpenImportFileA(PAnsiChar(AnsiString(inFile)), ptOpen, '') < 0 then Exit;
    pdf.ImportPDFFile(1, 1.0, 1.0);
    pdf.CloseImportFile;

    ctx := pdf.PsrCreateParserContext(ofDefault, nil);

    for i := 1 to pdf.GetPageCount do
    begin
      if pdf.PsrParsePage(ctx, nil, nil, i, cpfEnableTextSelection, nil, content) then
      begin
        curr := nil;
        while pdf.PsrFindText(ctx, nil, stDefault, curr, PWideChar(searchText), Length(searchText), sel) do
        begin
          pdf.PsrReplaceSelText(ctx, rtfDefault, sel, PWideChar(replaceText), Length(replaceText));
          curr := @sel;
        end;
        pdf.PsrWriteToPage(ctx, ofDefault, nil);
      end;
    end;
    pdf.PsrDeleteParserContext(ctx);

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

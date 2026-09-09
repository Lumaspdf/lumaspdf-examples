program pdf_to_text;
// Delphi OO example -- imports a PDF and writes each page's text to out.txt.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;

const
  emNoFuncNames = $10000000; // not in wrapper enum; from LumasPdf.pas

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TPDF;
  dir, inFile, outFile, cmap: string;
  i, count: Integer;
  f: TextFile;
  txt: PAnsiChar;
begin
  dir := ExtractFilePath(ParamStr(0));
  pdf := TPDF.Create;
  try
    pdf.SetErrorMode(emNoFuncNames);
    pdf.SetOnErrorProc(nil, @ErrProc);
    cmap := dir + 'CMap';
    pdf.SetCMapDirA(PAnsiChar(AnsiString(cmap)), lcmRecursive or lcmDelayed);

    if not pdf.CreateNewPDFA('') then Exit;

    pdf.SetImportFlags(ifContentOnly or ifImportAsPage);
    inFile := dir + 'in.pdf';
    if pdf.OpenImportFileA(PAnsiChar(AnsiString(inFile)), ptOpen, '') < 0 then Exit;
    if pdf.ImportPDFFile(1, 1.0, 1.0) < 0 then Exit;
    pdf.CloseImportFile;

    outFile := dir + 'out.txt';
    AssignFile(f, outFile);
    Rewrite(f);
    try
      count := pdf.GetPageCount;
      for i := 1 to count do
      begin
        Writeln(f, Format('----- Page %d -----', [i]));
        pdf.EditPage(i);
        txt := pdf.SplitPageTextA(i);
        if txt <> nil then
          Writeln(f, string(AnsiString(txt)))
        else
          Writeln(f, '');
        pdf.EndPage;
      end;
    finally
      CloseFile(f);
    end;
    pdf.FreePDF;
    Writeln('Text written to: ' + outFile);
  finally
    pdf.Free;
  end;
end.

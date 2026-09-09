program collections;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
// Imports a cover page, creates a PDF portfolio (collection) and attaches
// three files to it.
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
  ef: Integer;
  outFile: string;
begin
  pdf := TPDF.Create;
  try
    pdf.CreateNewPDFA('');
    pdf.SetOnErrorProc(nil, @ErrProc);

    pdf.SetImportFlags(ifImportAll or ifImportAsPage);
    if pdf.OpenImportFileA('../../test_files/collection_en.pdf', Ord(ptOpen), '') < 0 then
    begin
      Writeln('Input file "../../test_files/collection_en.pdf" not found!');
      Exit;
    end;
    pdf.ImportPDFFile(1, 1.0, 1.0);
    pdf.CloseImportFile;
    pdf.CreateCollection(Ord(civTile));

    ef := pdf.AttachFileA('../../test_files/taxform.pdf', 'A PDF file...', True);
    pdf.SetColDefFile(ef);
    pdf.AttachFileA('../../test_files/fulltest.emf', 'An EMF file...', True);
    pdf.AttachFileA('../../test_files/sample.txt', 'A text file...', True);

    outFile := '';
    if pdf.HaveOpenDoc then
    begin
      outFile := ExtractFilePath(ParamStr(0)) + 'out.pdf';
      if not pdf.OpenOutputFileA(PAnsiChar(AnsiString(outFile))) then Exit;
    end;
    pdf.CloseFile;
    Writeln(Format('PDF Collection "%s" successfully created!', [outFile]));
  finally
    pdf.Free;
  end;
end.

program collections2;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
// Like collections, but adds sortable collection fields and per-item field
// values, then validates the collection.
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

    // User defined field Index so the list can be sorted in any order.
    ef := pdf.CreateCollectionFieldA(Ord(cisCustomNumber), 0, 'File index', 'Index', False, True);
    pdf.SetColSortField(ef, True);

    pdf.CreateCollectionFieldA(Ord(cisFileName), 1, 'File name', '', True, True);
    pdf.CreateCollectionFieldA(Ord(cisSize), 2, 'File size', '', True, False);
    pdf.CreateCollectionFieldA(Ord(cisModDate), 3, 'Modification date', '', True, False);

    ef := pdf.AttachFileA('../../test_files/taxform.pdf', 'A PDF file...', True);
    pdf.SetColDefFile(ef);
    pdf.CreateColItemNumber(ef, 'Index', 0.0, '');

    ef := pdf.AttachFileA('../../test_files/fulltest.emf', 'An EMF file...', True);
    pdf.CreateColItemNumber(ef, 'Index', 1.0, '');

    ef := pdf.AttachFileA('../../test_files/sample.txt', 'A text file...', True);
    pdf.CreateColItemNumber(ef, 'Index', 2.0, '');

    pdf.CheckCollection;

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

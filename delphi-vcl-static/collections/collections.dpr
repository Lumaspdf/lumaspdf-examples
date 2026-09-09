program collections;
// PURE VCL static example -- the engine is linked INTO this exe (LUMAS_STATIC,
// runtime packages OFF). NO LumasPdf.dll at run time. Wrap.Static MUST be first.
// Imports a cover page, creates a PDF portfolio (collection) and attaches
// three files to it.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Types,              // engine enums/records
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore (flat API as methods)

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
  ef: Integer;
  outFile: string;
begin
  pdf := TLumasPDFCore.Create;
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

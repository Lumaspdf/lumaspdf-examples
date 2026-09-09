program optimize;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Imports a PDF, runs Optimize() and writes the result. Wrap.Static MUST be first.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Types,              // engine enums (import/optimize flags, doc info, cmap flags)
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore (flat API as methods)

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

function OptimizeFile(pdf: TLumasPDFCore; const InFile, OutFile: AnsiString): Boolean;
var
  i, n: Integer;
  e: TPDFError;
begin
  pdf.CreateNewPDFA('');
  pdf.SetDocInfoA(diProducer, '');   // keep original producer

  pdf.SetImportFlags((ifImportAll or ifImportAsPage) and not ifPieceInfo);
  pdf.SetImportFlags2(if2UseProxy or if2DuplicateCheck or if2Normalize or if2NoResNameCheck);
  if pdf.OpenImportFileA(PAnsiChar(InFile), ptOpen, '') < 0 then Exit(False);
  pdf.ImportPDFFile(1, 1.0, 1.0);
  pdf.CloseImportFile;

  pdf.Optimize(ofInMemory or ofNewLinkNames or ofDeleteInvPaths, nil);

  FillChar(e, SizeOf(e), 0);
  e.StructSize := SizeOf(e);
  n := pdf.GetErrLogMessageCount;
  for i := 0 to n - 1 do
  begin
    pdf.GetErrLogMessage(i, e);
    if e.Msg <> nil then Writeln(string(AnsiString(e.Msg)));
  end;

  if pdf.HaveOpenDoc then
  begin
    if not pdf.OpenOutputFileA(PAnsiChar(OutFile)) then Exit(False);
    Exit(pdf.CloseFile);
  end;
  Result := False;
end;

var
  pdf: TLumasPDFCore;
  dir, outFile, inFile, cmap: string;
begin
  dir := ExtractFilePath(ParamStr(0));
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    cmap := dir + 'CMap';
    pdf.SetCMapDirA(PAnsiChar(AnsiString(cmap)), lcmDelayed or lcmRecursive);

    outFile := dir + 'out.pdf';
    inFile := dir + 'sample_multipage.pdf';
    if OptimizeFile(pdf, AnsiString(inFile), AnsiString(outFile)) then
      Writeln('PDF file "' + outFile + '" successfully created!');
  finally
    pdf.Free;
  end;
end.

program split_pdf;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Opens one import file, keeps it open across CloseFile via SetUseGlobalImpFiles,
// and writes each page into its own PDF. Mirrors examples\c\split_pdf\split_pdf.c.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST be first -- binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Types,              // if*, ptOpen
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then
    Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
  i, count: Integer;
  outPath: AnsiString;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);

    pdf.SetImportFlags(ifImportAll or ifImportAsPage);
    pdf.SetImportFlags2(if2UseProxy);

    if pdf.OpenImportFileA('license.pdf', Ord(ptOpen), '') < 0 then
      Exit;

    pdf.SetUseGlobalImpFiles(True);

    if not DirectoryExists('out') then
      CreateDir('out');

    count := pdf.GetInPageCount;
    for i := 1 to count do
    begin
      outPath := AnsiString(Format('out\page%.4d.pdf', [i]));
      pdf.CreateNewPDFA(PAnsiChar(outPath));
        pdf.Append;
          pdf.ImportPageEx(i, 1.0, 1.0);
        pdf.EndPage;
      pdf.CloseFile;
    end;

    pdf.SetUseGlobalImpFiles(False);

    Writeln('Pages written to: out');
  finally
    pdf.Free;
  end;
end.

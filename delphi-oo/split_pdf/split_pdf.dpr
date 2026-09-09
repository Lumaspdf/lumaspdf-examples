program split_pdf;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
// Mechanical port of examples\c\split_pdf\split_pdf.c
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then
    Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TPDF;
  i, count: Integer;
  outPath: AnsiString;
begin
  pdf := TPDF.Create;                          // = pdfNewPDF
  try
    pdf.SetOnErrorProc(nil, PDFError);

    pdf.SetImportFlags(ifImportAll or ifImportAsPage);
    pdf.SetImportFlags2(if2UseProxy);

    if pdf.OpenImportFileA('license.pdf', ptOpen, '') < 0 then
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
    pdf.Free;                                  // = pdfDeletePDF
  end;
end.

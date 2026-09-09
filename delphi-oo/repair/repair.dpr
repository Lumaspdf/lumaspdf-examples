program repair;
// Delphi OO example -- fix a damaged PDF with a SINGLE method using the TPDF
// wrapper: pdf.ConvertFileA(..., ctNormalize). NOT the flat API.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;
var
  pdf: TPDF;
  rc: Integer;
begin
  // Run relative paths from the exe folder so ../../test_files resolves.
  SetCurrentDir(ExtractFilePath(ParamStr(0)));
  pdf := TPDF.Create;                             // = pdfNewPDF
  try
    rc := pdf.ConvertFileA(
      '../../test_files/corrupt.pdf',             // damaged input (mangled xref)
      'repaired.pdf',
      Ord(ctNormalize), 0, nil, nil, nil, nil, nil, nil);
    Writeln(Format('ConvertFile(ctNormalize) rc=%d  (repair-mode used: %d)',
      [rc, Integer(pdf.GetInRepairMode)]));
  finally
    pdf.Free;                                     // = pdfDeletePDF
  end;
  if rc < 0 then Halt(1);
end.

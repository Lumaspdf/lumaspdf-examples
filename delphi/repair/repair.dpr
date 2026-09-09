program repair;
// Delphi (flat vendor) example -- fix a damaged PDF with a SINGLE flat method:
// pdfConvertFileA(handle, ..., ctNormalize). Uses the flat pdf* externals.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf;
var
  p: PPDF;
  rc: Integer;
begin
  // Run relative paths from the exe folder so ../../test_files resolves.
  SetCurrentDir(ExtractFilePath(ParamStr(0)));
  p := pdfNewPDF;                                 // = pdfNewPDF
  try
    rc := pdfConvertFileA(p,
      '../../test_files/corrupt.pdf',             // damaged input (mangled xref)
      'repaired.pdf',
      Ord(ctNormalize), 0, nil, nil, nil, nil, nil, nil);
    Writeln(Format('pdfConvertFile(ctNormalize) rc=%d  (repair-mode used: %d)',
      [rc, Integer(pdfGetInRepairMode(p))]));
  finally
    pdfDeletePDF(p);                              // = pdfDeletePDF
  end;
  if rc < 0 then Halt(1);
end.

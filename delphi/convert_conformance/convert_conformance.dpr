program convert_conformance;
// Delphi (flat vendor) example -- plain PDF -> PDF/A and PDF/X, each a SINGLE
// flat method call: pdfConvertFileA(handle, ...).
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf;
var
  p: PPDF;
  a, x: Integer;
begin
  // Run relative paths from the exe folder so ../../test_files resolves.
  SetCurrentDir(ExtractFilePath(ParamStr(0)));
  p := pdfNewPDF;
  try
    a := pdfConvertFileA(p, '../../test_files/plain.pdf', 'out_pdfa.pdf',
      Ord(ctPDFA_2b), 0, '../../test_files/sRGB.icc',
      '../../test_files/ISOcoated_v2_bas.ICC', nil, nil, nil, nil);
    Writeln(Format('plain -> PDF/A (ctPDFA_2b) rc=%d', [a]));
    x := pdfConvertFileA(p, '../../test_files/plain.pdf', 'out_pdfx.pdf',
      Ord(ctPDFX_4), 0, '../../test_files/sRGB.icc',
      '../../test_files/ISOcoated_v2_bas.ICC', nil, nil, nil, nil);
    Writeln(Format('plain -> PDF/X (ctPDFX_4)  rc=%d', [x]));
  finally
    pdfDeletePDF(p);
  end;
  if (a < 0) or (x < 0) then Halt(1);
end.

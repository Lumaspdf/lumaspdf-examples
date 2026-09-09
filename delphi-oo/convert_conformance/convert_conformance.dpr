program convert_conformance;
// Delphi OO example -- plain PDF -> PDF/A and PDF/X, each a SINGLE method call
// on the TPDF wrapper: pdf.ConvertFileA(...).
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;
var
  pdf: TPDF;
  a, x: Integer;
begin
  // Run relative paths from the exe folder so ../../test_files resolves.
  SetCurrentDir(ExtractFilePath(ParamStr(0)));
  pdf := TPDF.Create;
  try
    a := pdf.ConvertFileA('../../test_files/plain.pdf', 'out_pdfa.pdf',
      Ord(ctPDFA_2b), 0, '../../test_files/sRGB.icc',
      '../../test_files/ISOcoated_v2_bas.ICC', nil, nil, nil, nil);
    Writeln(Format('plain -> PDF/A (ctPDFA_2b) rc=%d', [a]));
    x := pdf.ConvertFileA('../../test_files/plain.pdf', 'out_pdfx.pdf',
      Ord(ctPDFX_4), 0, '../../test_files/sRGB.icc',
      '../../test_files/ISOcoated_v2_bas.ICC', nil, nil, nil, nil);
    Writeln(Format('plain -> PDF/X (ctPDFX_4)  rc=%d', [x]));
  finally
    pdf.Free;
  end;
  if (a < 0) or (x < 0) then Halt(1);
end.

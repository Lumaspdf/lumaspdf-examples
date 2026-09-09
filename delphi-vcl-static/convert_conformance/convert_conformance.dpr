program convert_conformance;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC, runtime
// packages OFF). NO LumasPdf.dll at run time. Wrap.Static MUST be first.
// plain PDF -> PDF/A and PDF/X, each a SINGLE vendor method call (ConvertFileA).
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Types,              // engine enums (TConformanceType: ctPDFA_2b, ctPDFX_4)
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore (flat API as methods)
var
  pdf: TLumasPDFCore;
  a, x: Integer;
begin
  pdf := TLumasPDFCore.Create;  // static mode: DllPath ignored, engine in-process
  try
    a := pdf.ConvertFileA(
      PAnsiChar(AnsiString('../../test_files/plain.pdf')),
      PAnsiChar(AnsiString('out_pdfa.pdf')),
      Ord(ctPDFA_2b), 0,
      PAnsiChar(AnsiString('../../test_files/sRGB.icc')),
      PAnsiChar(AnsiString('../../test_files/ISOcoated_v2_bas.ICC')),
      nil, nil, nil, nil);
    Writeln('plain -> PDF/A (ctPDFA_2b) rc=', a);

    x := pdf.ConvertFileA(
      PAnsiChar(AnsiString('../../test_files/plain.pdf')),
      PAnsiChar(AnsiString('out_pdfx.pdf')),
      Ord(ctPDFX_4), 0,
      PAnsiChar(AnsiString('../../test_files/sRGB.icc')),
      PAnsiChar(AnsiString('../../test_files/ISOcoated_v2_bas.ICC')),
      nil, nil, nil, nil);
    Writeln('plain -> PDF/X (ctPDFX_4)  rc=', x);

    if (a < 0) or (x < 0) then ExitCode := 1;
  finally
    pdf.Free;
  end;
end.

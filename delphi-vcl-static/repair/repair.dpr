program repair;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC, runtime
// packages OFF). NO LumasPdf.dll at run time. Wrap.Static MUST be first.
// REPAIR: fix a damaged PDF with a SINGLE vendor method -- ConvertFileA(ctNormalize).
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Types,              // engine enums (TConformanceType: ctNormalize)
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore (flat API as methods)
var
  pdf: TLumasPDFCore;
  rc: Integer;
begin
  pdf := TLumasPDFCore.Create;  // static mode: DllPath ignored, engine in-process
  try
    rc := pdf.ConvertFileA(
      PAnsiChar(AnsiString('../../test_files/corrupt.pdf')),  // 4-page damaged input (mangled xref)
      PAnsiChar(AnsiString('repaired.pdf')),
      Ord(ctNormalize), 0, nil, nil, nil, nil, nil, nil);
    Writeln('pdfConvertFile(ctNormalize) rc=', rc, '  (repair-mode used: ', Integer(pdf.GetInRepairMode), ')');
    if rc < 0 then ExitCode := 1;
  finally
    pdf.Free;
  end;
end.

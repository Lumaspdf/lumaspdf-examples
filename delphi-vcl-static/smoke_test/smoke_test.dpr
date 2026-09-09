program smoke_test;
// PURE VCL static example -- the engine is linked INTO this exe (LUMAS_STATIC,
// runtime packages OFF). NO LumasPdf.dll at run time. Wrap.Static MUST be first.
// Mechanical port of examples\c\smoke_test\smoke_test.c
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Types,              // engine enums (fsRegular, cp1252, diTitle, fmFill)
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore (flat API as methods)
var
  pdf: TLumasPDFCore;
  outFile: AnsiString;
begin
  pdf := TLumasPDFCore.Create;                 // = pdfNewPDF (static: engine in-process)
  try
    outFile := 'smoke_out.pdf';
    if not pdf.CreateNewPDFA(PAnsiChar(outFile)) then
    begin
      Writeln('CreateNewPDF failed');
      Exit;
    end;
    pdf.SetDocInfoA(diTitle, 'LumasPdf example-mirror smoke test');
    pdf.Append;
    pdf.SetFontA('Arial', fsRegular, 24.0, True, cp1252);
    pdf.WriteTextA(50, 700, 'Mirrored DynaPDF examples run on LumasPdf.dll');
    pdf.SetFillColor(255);                      // red (COLORREF, R in low byte)
    pdf.Rectangle(50, 500, 200, 100, Ord(fmFill));
    pdf.AddBookmarkA('First page', -1, 1, 0);
    pdf.EndPage;
    if not pdf.CloseFile then
    begin
      Writeln('CloseFile failed');
      Exit;
    end;
    Writeln('OK: ' + string(outFile));
  finally
    pdf.Free;                                   // = pdfDeletePDF
  end;
end.

program smoke_test;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
// Mechanical port of examples\c\smoke_test\smoke_test.c
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;
var
  pdf: TPDF;
  outFile: AnsiString;
begin
  pdf := TPDF.Create;                          // = pdfNewPDF
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
    pdf.WriteTextA(50, 700, 'Examples run on LumasPdf.dll');
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
    pdf.Free;                                  // = pdfDeletePDF
  end;
end.

program hello_world;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;
var
  pdf: TPDF;
  cr: AnsiString;
begin
  cr := #13;
  pdf := TPDF.Create;                       // = pdfNewPDF
  try
    pdf.CreateNewPDFA('');
    pdf.SetDocInfoA(diCreator, 'Delphi OO Example');
    pdf.SetDocInfoA(diTitle, 'My first PDF output');
    pdf.Append;
    pdf.SetFontA('Arial', fsItalic, 30, True, cp1252);
    pdf.WriteFTextA(taCenter, PAnsiChar('My first PDF output...' + cr + cr + AnsiString(DateTimeToStr(Now))));
    pdf.EndPage;
    pdf.OpenOutputFileA(PAnsiChar(AnsiString(ExtractFilePath(ParamStr(0)) + 'out.pdf')));
    pdf.CloseFile;
    Writeln('OK: out.pdf');
  finally
    pdf.Free;                               // = pdfDeletePDF
  end;
end.

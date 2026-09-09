program highlight_annotations;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf     in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO   in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

const
  clYellow = 65535;
  clRed    = 255;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TPDF;
  d, w: Double;
  outFile: AnsiString;
const
  text = 'Some text on a page...';
begin
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');
    pdf.SetPageCoords(Ord(pcTopDown));

    pdf.Append;
    pdf.SetFontA('Helvetica', fsRegular, 20.0, False, cp1252);

    d := pdf.GetDescent;
    w := pdf.GetTextWidthA(text);

    pdf.WriteTextA(50.0, 50.0, text);
    pdf.HighlightAnnotA(atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, 'Test app', 'Highligh Annotations', 'This is a highlight annotation');

    pdf.WriteTextA(50.0, 80.0, text);
    pdf.HighlightAnnotA(atSquiggly, 50.0, 80.0 + d, w, 20.0, clRed, 'Test app', 'Squiggly Annotations', 'This is a squiggly annotation');

    pdf.WriteTextA(50.0, 110.0, text);
    pdf.HighlightAnnotA(atStrikeOut, 50.0, 110.0 + d, w, 20.0, clRed, 'Test app', 'Strikeout Annotations', 'This is a strikeout annotation');

    pdf.WriteTextA(50.0, 140.0, text);
    pdf.HighlightAnnotA(atUnderline, 50.0, 140.0 + d, w, 20.0, clRed, 'Test app', 'Underline Annotations', 'This is a underline annotation');
    pdf.EndPage;

    if pdf.HaveOpenDoc then
    begin
      outFile := AnsiString(ExtractFilePath(ParamStr(0)) + 'out.pdf');
      if not pdf.OpenOutputFileA(PAnsiChar(outFile)) then Exit;
      if pdf.CloseFile then
        Writeln('PDF file "' + string(outFile) + '" successfully created!');
    end;
  finally
    pdf.Free;
  end;
end.

program highlight_annotations;
// PURE VCL static example -- engine linked into this exe (LUMAS_STATIC), no LumasPdf.dll.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  Lumas.Pdf.Types,
  Lumas.Pdf.Wrap.Core;

const
  clYellow = 65535;
  clRed    = 255;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
  d, w: Double;
  outFile: AnsiString;
  text: AnsiString;
begin
  text := 'Some text on a page...';
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');
    pdf.SetPageCoords(Ord(pcTopDown));

    pdf.Append;
    pdf.SetFontA('Helvetica', fsRegular, 20.0, False, cp1252);

    d := pdf.GetDescent;
    w := pdf.GetTextWidthA(PAnsiChar(text));

    pdf.WriteTextA(50.0, 50.0, PAnsiChar(text));
    pdf.HighlightAnnotA(atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, 'Test app', 'Highligh Annotations', 'This is a highlight annotation');

    pdf.WriteTextA(50.0, 80.0, PAnsiChar(text));
    pdf.HighlightAnnotA(atSquiggly, 50.0, 80.0 + d, w, 20.0, clRed, 'Test app', 'Squiggly Annotations', 'This is a squiggly annotation');

    pdf.WriteTextA(50.0, 110.0, PAnsiChar(text));
    pdf.HighlightAnnotA(atStrikeOut, 50.0, 110.0 + d, w, 20.0, clRed, 'Test app', 'Strikeout Annotations', 'This is a strikeout annotation');

    pdf.WriteTextA(50.0, 140.0, PAnsiChar(text));
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

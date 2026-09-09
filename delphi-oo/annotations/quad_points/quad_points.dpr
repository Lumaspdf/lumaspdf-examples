program quad_points;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf     in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO   in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

const
  clYellow = 65535;
  clRed    = 255;
  clBlue   = 16711680;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

procedure IncY(var points: array of TFltPoint; n: Integer; Value: Single);
var
  i: Integer;
begin
  for i := 0 to n - 1 do
    points[i].y := points[i].y + Value;
end;

var
  pdf: TPDF;
  a: Integer;
  d, w: Single;
  outFile, text: AnsiString;
  points: array[0..3] of TFltPoint;
begin
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');
    pdf.SetPageCoords(Ord(pcTopDown));

    pdf.Append;

    pdf.SaveGraphicState;

    pdf.SetGStateFlags(gfRealTopDownCoords, False);
    pdf.RotateCoords(-30.0, 50.0, 200.0);

    text := 'Some rotated text on a page...';
    pdf.SetFontA('Helvetica', fsRegular, 20.0, False, cp1252);

    d := pdf.GetDescent;
    w := pdf.GetTextWidthA(PAnsiChar(text));

    pdf.WriteTextA(0.0, 0.0, PAnsiChar(text));
    a := pdf.HighlightAnnotA(atHighlight, 50.0, 50.0 + d, w, 20.0, clYellow, 'Test app', 'Highligh Annotations', 'This is a highlight annotation');
    points[0].x := 0.0;  points[0].y := d;          { Top left corner }
    points[1].x := w;    points[1].y := d;          { Top right corner }
    points[2].x := 0.0;  points[2].y := 20.0 + d;   { Bottom left corner }
    points[3].x := w;    points[3].y := 20.0 + d;   { Bottom right corner }
    pdf.SetAnnotQuadPoints(a, @points[0], 4);

    pdf.WriteTextA(0.0, 30.0, PAnsiChar(text));
    a := pdf.HighlightAnnotA(atSquiggly, 50.0, 80.0, w, 20.0, clRed, 'Test app', 'Squiggly Annotations', 'This is a squiggly annotation');
    IncY(points, 4, 30.0);
    pdf.SetAnnotQuadPoints(a, @points[0], 4);

    pdf.WriteTextA(0.0, 60.0, PAnsiChar(text));
    a := pdf.HighlightAnnotA(atStrikeOut, 50.0, 110.0, w, 20.0, clRed, 'Test app', 'Strikeout Annotations', 'This is a strikeout annotation');
    IncY(points, 4, 30.0);
    pdf.SetAnnotQuadPoints(a, @points[0], 4);

    pdf.WriteTextA(0.0, 90.0, PAnsiChar(text));
    a := pdf.HighlightAnnotA(atUnderline, 50.0, 140.0, w, 20.0, clRed, 'Test app', 'Underline Annotations', 'This is a underline annotation');
    IncY(points, 4, 30.0);
    pdf.SetAnnotQuadPoints(a, @points[0], 4);

    text := 'Link annotations support quad points too';
    w := pdf.GetTextWidthA(PAnsiChar(text));
    pdf.WriteTextA(0.0, 120.0, PAnsiChar(text));
    a := pdf.WebLinkA(0.0, 120.0, w, 20.0, 'www.dynaforms.com');
    pdf.SetAnnotBorderWidth(a, 1.0);
    pdf.SetAnnotColor(a, fcBorderColor, csDeviceRGB, clBlue);
    points[0].x := 0.0;  points[0].y := 120.0 + d;  { Top left corner }
    points[1].x := w;    points[1].y := 120.0 + d;  { Top right corner }
    points[2].x := 0.0;  points[2].y := 140.0 + d;  { Bottom left corner }
    points[3].x := w;    points[3].y := 140.0 + d;  { Bottom right corner }
    pdf.SetAnnotQuadPoints(a, @points[0], 4);

    pdf.RestoreGraphicState;

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

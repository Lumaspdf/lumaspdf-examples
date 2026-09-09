program metafiles;
// Delphi OO example -- places three EMF metafiles centered/scaled on landscape pages
// with a red frame.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;

const
  CLR_RED = 255;
  MARGIN  = 10.0;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

procedure PlaceEMFCentered(pdf: TPDF; const MFile: AnsiString; Width, Height: Double);
var
  x, y, w, h, sx: Double;
  r: TRectL;
begin
  pdf.GetLogMetafileSizeA(PAnsiChar(MFile), r);
  w := r.Right - r.Left;
  h := r.Bottom - r.Top;
  Width := Width - 2.0 * MARGIN;
  Height := Height - 2.0 * MARGIN;
  sx := Width / w;

  if h * sx <= Height then
  begin
    x := MARGIN;
    h := h * sx;
    y := (Height - h) / 2.0;
    pdf.InsertMetafileA(PAnsiChar(MFile), x, y, Width, 0.0);
    pdf.SetStrokeColor(CLR_RED);
    pdf.Rectangle(x, y, Width, h, Ord(fmStroke));
  end
  else
  begin
    sx := Height / h;
    w := w * sx;
    x := (Width - w) / 2.0;
    y := MARGIN;
    pdf.InsertMetafileA(PAnsiChar(MFile), x, y, 0.0, Height);
    pdf.SetStrokeColor(CLR_RED);
    pdf.Rectangle(x, y, w, Height, Ord(fmStroke));
  end;
end;

var
  pdf: TPDF;
  dir, outFile: string;
  f1, f2, f3: AnsiString;
begin
  dir := ExtractFilePath(ParamStr(0));
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    if not pdf.CreateNewPDFA('') then Exit;
    pdf.SetPageCoords(Ord(pcTopDown));
    f1 := AnsiString(dir + 'coords.emf');
    f2 := AnsiString(dir + 'fulltest.emf');
    f3 := AnsiString(dir + 'gdi.emf');
    outFile := dir + 'out.pdf';

    pdf.Append; pdf.SetOrientationEx(90);
    PlaceEMFCentered(pdf, f1, pdf.GetPageWidth, pdf.GetPageHeight);
    pdf.EndPage;

    pdf.Append; pdf.SetOrientationEx(90);
    PlaceEMFCentered(pdf, f2, pdf.GetPageWidth, pdf.GetPageHeight);
    pdf.EndPage;

    pdf.Append; pdf.SetOrientationEx(90);
    PlaceEMFCentered(pdf, f3, pdf.GetPageWidth, pdf.GetPageHeight);
    pdf.EndPage;

    if pdf.HaveOpenDoc then
      if not pdf.OpenOutputFileA(PAnsiChar(AnsiString(outFile))) then Exit;
    if pdf.CloseFile then
      Writeln('PDF file "' + outFile + '" successfully created!');
  finally
    pdf.Free;
  end;
end.

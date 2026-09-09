program metafiles_gui;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC). No LumasPdf.dll.
// Loads an EMF, places it centered on a page, writes out.pdf (interactive UI dropped).
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,
  System.SysUtils,
  Lumas.Pdf.Types,
  Lumas.Pdf.ApiTypes,           // TRectL
  Lumas.Pdf.Wrap.Core;

const
  MARGIN = 10.0;

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;

procedure PlaceEMFCentered(const mFile: AnsiString; Width, Height: Double);
var
  x, y, w, h, sx: Double;
  r: TRectL;
begin
  pdf.GetLogMetafileSizeA(PAnsiChar(mFile), r);
  w := r.Right - r.Left;
  h := r.Bottom - r.Top;
  Width := Width - 2.0 * MARGIN;
  Height := Height - 2.0 * MARGIN;
  sx := Width / w;
  if h * sx <= Height then
  begin
    x := MARGIN; y := MARGIN;
    pdf.InsertMetafileA(PAnsiChar(mFile), x, y, Width, 0.0);
  end
  else
  begin
    sx := Height / h;
    w := w * sx;
    x := MARGIN + (Width - w) / 2.0;
    y := MARGIN;
    pdf.InsertMetafileA(PAnsiChar(mFile), x, y, 0.0, Height);
  end;
end;

var
  dir, outFile: string;
  inFile: AnsiString;
begin
  dir := ExtractFilePath(ParamStr(0));
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.SetCompressionFilter(Ord(cfFlate));
    pdf.SetJPEGQuality(70);

    inFile := AnsiString(dir + 'in.emf');
    outFile := dir + 'out.pdf';

    if not pdf.CreateNewPDFA('') then Exit;

    pdf.SetCompressionLevel(Ord(clNone));
    pdf.SetCompressionFilter(Ord(cfFlate));
    pdf.SetColorSpace(Ord(csDeviceRGB));
    pdf.SetMetaConvFlags(Integer(mfDefault));
    pdf.SetPageCoords(Ord(pcTopDown));
    pdf.Append;
    pdf.SetResolution(300);
    pdf.SetJPEGQuality(70);
    PlaceEMFCentered(inFile, pdf.GetPageWidth, pdf.GetPageHeight);
    pdf.EndPage;

    if pdf.HaveOpenDoc then
    begin
      if not pdf.OpenOutputFileA(PAnsiChar(AnsiString(outFile))) then Exit;
      if pdf.CloseFile then Writeln('OK: ' + outFile);
    end;
  finally
    pdf.Free;
  end;
end.

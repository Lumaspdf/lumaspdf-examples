program render_page_to_image;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Loads a PDF, imports the first page and renders it to a TIFF image file.
// Uses Winapi.Windows GetDC/GetDeviceCaps for the screen width. Wrap.Static MUST be first.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // binds every engine entry point in-process
  Winapi.Windows,
  System.SysUtils,
  Lumas.Pdf.Types,              // enums (import flags, raster/pixel/compression/image format)
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore (flat API as methods)

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
  dc: HDC;
  w: Integer;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    pdf.CreateNewPDFA('');

    pdf.SetImportFlags(ifImportAll or ifImportAsPage);
    if pdf.OpenImportFileA('../../../../sample_multipage.pdf', ptOpen, '') < 0 then
      Exit;

    pdf.Append;
      pdf.ImportPageEx(1, 1.0, 1.0);
    pdf.EndPage;

    dc := GetDC(0);
    w  := GetDeviceCaps(dc, HORZRES);
    ReleaseDC(0, dc);

    if pdf.RenderPageToImageA(1, 'out.tif', 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) then
      Writeln('TIFF image "out.tif" successfully created!');
  finally
    pdf.Free;
  end;
end.

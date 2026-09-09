program render_page_to_image;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
// Port of examples\c\rendering_engine\render_page_to_image\render_page_to_image.c
// Loads a PDF, imports the first page and renders it to a TIFF image file.
{$APPTYPE CONSOLE}
uses
  Winapi.Windows,
  System.SysUtils,
  LumasPdf     in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO   in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TPDF;
  dc: HDC;
  w: Integer;
begin
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    pdf.CreateNewPDFA('');

    pdf.SetImportFlags(ifImportAll or ifImportAsPage);
    if pdf.OpenImportFileA('../../../../dynapdf_help.pdf', ptOpen, '') < 0 then
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

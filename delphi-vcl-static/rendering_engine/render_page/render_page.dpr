program render_page;
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
  w, pageCount: Integer;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    pdf.CreateNewPDFA('');   // We create no PDF file in this example

    pdf.SetCMapDirA('..\..\..\Resource\CMap\', lcmRecursive or lcmDelayed);

    if pdf.OpenImportFileA('../../../../dynapdf_help.pdf', ptOpen, '') < 0 then
      Exit;

    pdf.SetImportFlags(ifContentOnly);
    pdf.ImportCatalogObjects;
    pdf.SetImportFlags(ifImportAll or ifImportAsPage);
    pdf.SetImportFlags2(if2UseProxy);

    pageCount := pdf.GetInPageCount;
    if pageCount < 1 then Exit;

    pdf.Append;
      pdf.ImportPageEx(1, 1.0, 1.0);
    pdf.EndPage;

    if pdf.GetPageObject(1) = nil then Exit;

    dc := GetDC(0);
    w  := GetDeviceCaps(dc, HORZRES);
    ReleaseDC(0, dc);

    if pdf.RenderPageToImageA(1, 'render_page.tif', 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) then
      Writeln('Rendered page 1 to render_page.tif');
  finally
    pdf.Free;
  end;
end.

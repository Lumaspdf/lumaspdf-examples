program render_page_ex;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
// Port of examples\c\rendering_engine\render_page_ex\render_page_ex.c
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
  w, pageCount: Integer;
begin
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    pdf.CreateNewPDFA('');

    pdf.SetCMapDirA('..\..\..\Resource\CMap\', lcmRecursive or lcmDelayed);

    if pdf.OpenImportFileA('../../../../sample_multipage.pdf', ptOpen, '') < 0 then
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

    if pdf.RenderPageToImageA(1, 'render_page_ex.tif', 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) then
      Writeln('Rendered page 1 to render_page_ex.tif');
  finally
    pdf.Free;
  end;
end.

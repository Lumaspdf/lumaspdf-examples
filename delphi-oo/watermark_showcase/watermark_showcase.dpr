// Delphi OO example -- the user-defined watermark API, feature by feature.
// Mirror of examples\cpp\watermark_showcase (see there for the full notes):
// one watermark configuration is active per document and is stamped at
// CloseFile, so each capability writes its own small PDF.
// Colors are 0xBBGGRR (COLORREF order).
program watermark_showcase;
{$APPTYPE CONSOLE}

uses
  SysUtils,
  LumasPdf,
  LumasPdfOO;

var pdf: TPDF;

function NewDoc(const FileName: string; Pages: Integer): TPDF;
var i: Integer;
begin
  Result := TPDF.Create;
  Result.CreateNewPDFA(PAnsiChar(AnsiString(FileName)));
  Result.SetDocInfoA(diTitle, PAnsiChar(AnsiString('Watermark showcase: ' + FileName)));
  for i := 1 to Pages do
  begin
    Result.Append;
    Result.SetFontA('Helvetica', fsRegular, 14.0, True, cp1252);
    Result.WriteTextA(50.0, 760.0, PAnsiChar(AnsiString(Format('Body content, page %d', [i]))));
    Result.EndPage;
  end;
end;

procedure CloseDoc(var P: TPDF; const Name: string);
begin
  if P.CloseFile then Writeln('wrote ', Name) else Writeln('FAILED ', Name);
  P.Free; P := nil;
end;

begin
  // 1 -- classic diagonal CONFIDENTIAL, under the content
  pdf := NewDoc('wm_1_diagonal.pdf', 1);
  pdf.SetWatermarkTextA('C O N F I D E N T I A L', 0.0, $0000CC, 45.0, 0.08);
  pdf.SetWatermarkIntProperty(wmpFitMode, wmfPageDiagonal);
  pdf.SetWatermarkIntProperty(wmpLayer, wmlUnder);
  pdf.SetWatermarkDblProperty(wmpMargin, 90.0);
  CloseDoc(pdf, 'wm_1_diagonal.pdf');

  // 2 -- anchored corner tag
  pdf := NewDoc('wm_2_anchored.pdf', 1);
  pdf.SetWatermarkTextA('INTERNAL USE ONLY', 11.0, $555555, 0.0, 0.9);
  pdf.SetWatermarkIntProperty(wmpAnchor, wmaBottomRight);
  pdf.SetWatermarkDblProperty(wmpOffsetX, -18.0);
  pdf.SetWatermarkDblProperty(wmpOffsetY, 18.0);
  CloseDoc(pdf, 'wm_2_anchored.pdf');

  // 3 -- typography: font, outline, shadow
  pdf := NewDoc('wm_3_styled.pdf', 1);
  pdf.SetWatermarkTextA('DRAFT', 96.0, $FF9933, 30.0, 0.5);
  pdf.SetWatermarkStrPropertyA(wmpFontName, 'Helvetica');
  pdf.SetWatermarkIntProperty(wmpFontStyle, fsBold);
  pdf.SetWatermarkIntProperty(wmpOutlineEnabled, 1);
  pdf.SetWatermarkDblProperty(wmpOutlineWidth, 1.2);
  pdf.SetWatermarkClrProperty(wmpOutlineColor, wmcsCurrent, $883311);
  pdf.SetWatermarkIntProperty(wmpShadowEnabled, 1);
  pdf.SetWatermarkDblProperty(wmpShadowDistance, 3.0);
  pdf.SetWatermarkDblProperty(wmpShadowOpacity, 0.35);
  CloseDoc(pdf, 'wm_3_styled.pdf');

  // 4 -- grid tiling
  pdf := NewDoc('wm_4_tiled.pdf', 1);
  pdf.SetWatermarkTextA('SAMPLE', 18.0, $999999, 45.0, 0.15);
  pdf.SetWatermarkIntProperty(wmpTileMode, wmtGrid);
  pdf.SetWatermarkDblProperty(wmpTileSpacingX, 140.0);
  pdf.SetWatermarkDblProperty(wmpTileSpacingY, 110.0);
  CloseDoc(pdf, 'wm_4_tiled.pdf');

  // 5 -- rounded-rect APPROVED stamp
  pdf := NewDoc('wm_5_stamp.pdf', 1);
  pdf.SetWatermarkTextA('APPROVED', 28.0, $009900, 0.0, 0.9);
  pdf.SetWatermarkIntProperty(wmpShape, wmsRoundRect);
  pdf.SetWatermarkIntProperty(wmpShapeStrokeEnabled, 1);
  pdf.SetWatermarkDblProperty(wmpShapeLineWidth, 2.0);
  pdf.SetWatermarkClrProperty(wmpShapeStrokeColor, wmcsCurrent, $009900);
  pdf.SetWatermarkDblProperty(wmpShapeCornerRadius, 10.0);
  pdf.SetWatermarkDblProperty(wmpShapePadding, 12.0);
  pdf.SetWatermarkIntProperty(wmpAnchor, wmaTopRight);
  pdf.SetWatermarkDblProperty(wmpAngle, 12.0);
  CloseDoc(pdf, 'wm_5_stamp.pdf');

  // 6 -- [page]/[pages] placeholders + page selection
  pdf := NewDoc('wm_6_pages.pdf', 4);
  pdf.SetWatermarkTextA('Copy [page] of [pages]', 16.0, $336699, 0.0, 0.8);
  pdf.SetWatermarkIntProperty(wmpAnchor, wmaBottomCenter);
  pdf.SetWatermarkIntProperty(wmpFirstPage, 2);
  pdf.SetWatermarkIntProperty(wmpPageParity, wmrEven);
  CloseDoc(pdf, 'wm_6_pages.pdf');

  Writeln('watermark showcase: 6 PDFs written');
end.

program bookmarks;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
// Demonstrates bookmark destination types plus a page link with a GoTo action.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  LumasPdf,
  LumasPdfOO;

const
  clRed    = $0000FF;
  clGreen  = $008000;
  clBlue   = $FF0000;
  clMaroon = $000080;

// Error callback (native stdcall function, address passed with @).
function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  Writeln(string(AnsiString(ErrMessage)));
  Result := 0; // We try to continue if an error occurs
end;

var
  pdf: TPDF;
  act, lnk, f, bmk, root: Integer;
  x, y: Double;
  outFile: string;
begin
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    pdf.CreateNewPDFA('');

    pdf.SetPageCoords(Ord(pcTopDown));
    pdf.SetPageHeight(500.0);
    pdf.SetPageWidth(800.0);

    pdf.Append;
      f := pdf.SetFontA('Helvetica', fsRegular, 20, False, cp1252);
      pdf.WriteTextA(50, 50, 'Bookmark destination type dtFit');
      root := pdf.AddBookmarkA('DestType dtFit', -1, 1, 1);
      pdf.SetBookmarkDest(root, Ord(dtFit), 0, 0, 0, 0);
      pdf.SetBookmarkStyle(root, fsItalic, clRed);
    pdf.EndPage;

    pdf.Append;
      pdf.ChangeFont(f);
      pdf.WriteTextA(50, 50, 'Bookmark destination type dtXY_Zoom');
      pdf.WriteTextA(50, 70, 'Zoom factor 3, Top position 50 (TopDown coordinates)');
      bmk := pdf.AddBookmarkA('DestType: dtXY_Zoom, zoom factor 3', root, 2, 0);
      pdf.SetBookmarkDest(bmk, Ord(dtXY_Zoom), 50, 50, 3, 0);
      pdf.SetBookmarkStyle(bmk, fsBold, clMaroon);
    pdf.EndPage;

    pdf.Append;
      pdf.ChangeFont(f);
      pdf.WriteTextA(50, 50, 'Bookmark destination type dtXY_Zoom');
      pdf.WriteTextA(50, 70, 'Zoom factor 0.5, Top position 50 (TopDown coordinates)');
      bmk := pdf.AddBookmarkA('DestType: dtXY_Zoom, zoom factor 0.5', root, 3, 0);
      pdf.SetBookmarkDest(bmk, Ord(dtXY_Zoom), 50, 50, 0.5, 0);
      pdf.SetBookmarkStyle(bmk, fsBold or fsItalic, clGreen);
    pdf.EndPage;

    pdf.Append;
      pdf.ChangeFont(f);
      pdf.WriteTextA(50, 50, 'Bookmark destination type dtXY_Zoom');
      pdf.WriteTextA(50, 70, 'Zoom factor not defined (unchanged), Top position 50 (TopDown coordinates)');
      bmk := pdf.AddBookmarkA('DestType: dtXY_Zoom, zoom factor unchanged', root, 4, 0);
      pdf.SetBookmarkDest(bmk, Ord(dtXY_Zoom), 50, 50, 0, 0);
      pdf.SetBookmarkStyle(bmk, fsRegular, clBlue);
    pdf.EndPage;

    pdf.Append;
      pdf.ChangeFont(f);
      pdf.WriteTextA(50, 50, 'Bookmark destination type dtFitH_Top');
      pdf.WriteTextA(50, 70, 'Top position 50 (TopDown coordinates)');
      bmk := pdf.AddBookmarkA('DestType: dtFitH_Top (50)', root, 5, 0);
      pdf.SetBookmarkDest(bmk, Ord(dtFitH_Top), 50, 0, 0, 0);
      pdf.SetBookmarkStyle(bmk, fsRegular, $FF8080);
      pdf.WriteTextA(50, 200, 'Bookmark destination type dtFitH_Top');
      pdf.WriteTextA(50, 220, 'Top position 200 (TopDown coordinates)');
      bmk := pdf.AddBookmarkA('DestType dtFitH_Top (200)', root, 5, 0);
      pdf.SetBookmarkDest(bmk, Ord(dtFitH_Top), 200, 0, 0, 0);
      pdf.SetBookmarkStyle(bmk, fsRegular, $C08080);
    pdf.EndPage;

    pdf.Append;
      pdf.ChangeFont(f);
      pdf.WriteTextA(200, 50, 'Bookmark destination type dtFitV_Left');
      pdf.WriteTextA(200, 70, 'Left position 200. FitV has no effect if the width of the page');
      pdf.WriteTextA(200, 90, 'is not greater as the height.');
      bmk := pdf.AddBookmarkA('DestType: dtFitV_Left (200)', root, 6, 0);
      pdf.SetBookmarkDest(bmk, Ord(dtFitV_Left), 200, 0, 0, 0);
      pdf.SetBookmarkStyle(bmk, fsRegular, $808FFF);
    pdf.EndPage;

    pdf.Append;
      pdf.ChangeFont(f);
      pdf.WriteTextA(50, 50, 'Bookmark destination type dtFit_Rect');
      x := (pdf.GetPageWidth - 90.0) / 2.0;
      y := (pdf.GetPageHeight - 65.0) / 2.0;

      pdf.WriteFTextExA(x, y, 90.0, -1, taCenter, 'We zoom into the rectangle');
      pdf.Rectangle(x, y, 90.0, 65.0, Ord(fmStroke));

      pdf.SetLinkHighlightMode(Ord(hmInvert));
      lnk := pdf.PageLink(x, y, 90, 65, 7);
      act := pdf.CreateGoToAction(dtFit_Rect, 7, x - 5.0, y - 5.0, x + 100.0, y + 70.0);
      pdf.AddActionToObj(Ord(otPageLink), Ord(oeOnMouseUp), act, lnk);

      bmk := pdf.AddBookmarkA('DestType: dtFit_Rect', -1, 7, 0);
      pdf.AddActionToObj(Ord(otBookmark), Ord(oeOnMouseUp), act, bmk);
      pdf.SetBookmarkStyle(bmk, fsRegular, $80FF);
    pdf.EndPage;

    pdf.SetPageFormat(Ord(pfDIN_A4));
    pdf.Append;
      pdf.ChangeFont(f);
      pdf.WriteFTextExA(50.0, 50.0, pdf.GetPageWidth - 100.0, -1.0, taLeft,
        'Destination type dtFit. This variant scales the page so that both sides fit into the viewer window.');
    pdf.EndPage;

    root := pdf.AddBookmarkA('DestType dtFit', -1, 8, 0);
    pdf.SetBookmarkDest(root, Ord(dtFit), 0, 0, 0, 0);

    bmk := pdf.AddBookmarkA('DestType: dtXY_Zoom, zoom factor 3', root, 2, 0);
    pdf.SetBookmarkDest(bmk, Ord(dtXY_Zoom), 50, 50, 3, 0);
    pdf.SetBookmarkStyle(bmk, fsBold, clMaroon);

    pdf.SetPageLayout(plOneColumn);

    if pdf.HaveOpenDoc then
    begin
      outFile := ExtractFilePath(ParamStr(0)) + 'out.pdf';
      if not pdf.OpenOutputFileA(PAnsiChar(AnsiString(outFile))) then Exit;
      if pdf.CloseFile then
        Writeln(Format('PDF file "%s" successfully created!', [outFile]));
    end;
  finally
    pdf.Free;
  end;
end.

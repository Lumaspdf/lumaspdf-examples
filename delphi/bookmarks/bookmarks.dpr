program image_extraction;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  Classes,
  {$IF RTLVersion >= 23}Vcl.{$IFEND}Graphics,
  ShellAPI,
  LumasPdfApi in '..\include\LumasPdfApi.pas';

{
   Note that the LumasPdf.dll must be copied into the output directory or into a
   Windwos search path (e.g. %WINDOWS%/System32) before the application can be executed!
}

// Error callback function.
// If the function name should not appear at the beginning of the error message set
// the flag emNoFuncNames (pdf..SetErrorMode(emNoFuncNames);). 
function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

procedure CreateBookmarks;
var act, lnk, f, bmk, root: Integer; x, y: Double; pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // The output file is opened later

      pdf.SetPageCoords(pcTopDown);

      pdf.SetPageHeight(500.0);
      pdf.SetPageWidth(800.0);

      pdf.Append;
         f := pdf.SetFont('Helvetica', fsRegular, 20, false, cp1252);
         pdf.WriteText(50, 50, 'Bookmark destination type dtFit');
         root := pdf.AddBookmark('DestType dtFit', -1, 1, true);
         pdf.SetBookmarkDest(root, dtFit, 0, 0, 0, 0);
         pdf.SetBookmarkStyle(root, fsItalic, clRed);
      pdf.EndPage;

      pdf.Append;
         pdf.ChangeFont(f);
         pdf.WriteText(50, 50, 'Bookmark destination type dtXY_Zoom');
         pdf.WriteText(50, 70, 'Zoom factor 3, Top position 50 (TopDown coordinates)');
         bmk := pdf.AddBookmark('DestType: dtXY_Zoom, zoom factor 3', root, 2, false);
         pdf.SetBookmarkDest(bmk, dtXY_Zoom, 50, 50, 3, 0);
         pdf.SetBookmarkStyle(bmk, fsBold, clMaroon);
      pdf.EndPage;

      pdf.Append;
         pdf.ChangeFont(f);
         pdf.WriteText(50, 50, 'Bookmark destination type dtXY_Zoom');
         pdf.WriteText(50, 70, 'Zoom factor 0.5, Top position 50 (TopDown coordinates)');
         bmk := pdf.AddBookmark('DestType: dtXY_Zoom, zoom factor 0.5', root, 3, false);
         pdf.SetBookmarkDest(bmk, dtXY_Zoom, 50, 50, 0.5, 0);
         pdf.SetBookmarkStyle(bmk, fsBold or fsItalic, clGreen);
      pdf.EndPage;

      pdf.Append;
         pdf.ChangeFont(f);
         pdf.WriteText(50, 50, 'Bookmark destination type dtXY_Zoom');
         pdf.WriteText(50, 70, 'Zoom factor not defined (unchanged), Top position 50 (TopDown coordinates)');
         bmk := pdf.AddBookmark('DestType: dtXY_Zoom, zoom factor unchanged', root, 4, false);
         pdf.SetBookmarkDest(bmk, dtXY_Zoom, 50, 50, 0, 0);
         pdf.SetBookmarkStyle(bmk, fsRegular, clBlue);
      pdf.EndPage;

      pdf.Append;
         pdf.ChangeFont(f);
         pdf.WriteText(50, 50, 'Bookmark destination type dtFitH_Top');
         pdf.WriteText(50, 70, 'Top position 50 (TopDown coordinates)');
         bmk := pdf.AddBookmark('DestType: dtFitH_Top (50)', root, 5, false);
         pdf.SetBookmarkDest(bmk, dtFitH_Top, 50, 0, 0, 0);
         pdf.SetBookmarkStyle(bmk, fsRegular, $00FF8080);
         pdf.WriteText(50, 200, 'Bookmark destination type dtFitH_Top');
         pdf.WriteText(50, 220, 'Top position 200 (TopDown coordinates)');
         bmk := pdf.AddBookmark('DestType dtFitH_Top (200)', root, 5, false);
         pdf.SetBookmarkDest(bmk, dtFitH_Top, 200, 0, 0, 0);
         pdf.SetBookmarkStyle(bmk, fsRegular, $00C08080);
      pdf.EndPage;

      pdf.Append;
         pdf.ChangeFont(f);
         pdf.WriteText(200, 50, 'Bookmark destination type dtFitV_Left');
         pdf.WriteText(200, 70, 'Left position 200. FitV has no effect if the width of the page');
         pdf.WriteText(200, 90, 'is not greater as the height.');
         bmk := pdf.AddBookmark('DestType: dtFitV_Left (200)', root, 6, false);
         pdf.SetBookmarkDest(bmk, dtFitV_Left, 200, 0, 0, 0);
         pdf.SetBookmarkStyle(bmk, fsRegular, $00808FFF);
      pdf.EndPage;

      pdf.Append;
         pdf.ChangeFont(f);
         pdf.WriteText(50, 50, 'Bookmark destination type dtFit_Rect');
         x := (pdf.GetPageWidth  -90.0) / 2.0;
         y := (pdf.GetPageHeight -65.0) / 2.0;

         pdf.WriteFTextEx(x, y, 90.0, -1, taCenter, 'We zoom into the rectangle');
         pdf.Rectangle(x, y, 90.0, 65.0, fmStroke);

         // We place a page link with a GoTo action on this position. The link zooms into the rectangle in the same way as the bookmark.
         pdf.SetLinkHighlightMode(hmInvert);
         lnk := pdf.PageLink(x, y, 90, 65, 7);
         act := pdf.CreateGoToAction(dtFit_Rect, 7, x - 5.0, y - 5.0, x + 100.0, y + 70.0);
         pdf.AddActionToObj(otPageLink, oeOnMouseUp, act, lnk);

         bmk := pdf.AddBookmark('DestType: dtFit_Rect', -1, 7, false);
         // The page link uses the same destination as the bookmark should use. So we add the action to the bookmark instead
         // of a bookmark destination. This saves just a little bit disk space.
         pdf.AddActionToObj(otBookmark, oeOnMouseUp, act, bmk);
         pdf.SetBookmarkStyle(bmk, fsRegular, $000080FF);
      pdf.EndPage;

      pdf.SetPageFormat(pfDIN_A4);
      pdf.Append;
         pdf.ChangeFont(f);
         pdf.WriteFTextEx(50.0, 50.0, pdf.GetPageWidth - 100.0, -1.0, taLeft, 'Destination type dtFit. This variant scales the page so that both sides fit into the viewer window.');
      pdf.EndPage;

      root := pdf.AddBookmark('DestType dtFit', -1, 8, false);
      pdf.SetBookmarkDest(root, dtFit, 0, 0, 0, 0);

      bmk := pdf.AddBookmark('DestType: dtXY_Zoom, zoom factor 3', root, 2, false);
      pdf.SetBookmarkDest(bmk, dtXY_Zoom, 50, 50, 3, 0);
      pdf.SetBookmarkStyle(bmk, fsBold, clMaroon);


      pdf.SetPageLayout(plOneColumn);
      
      // No fatal error occurred?
      if pdf.HaveOpenDoc then begin
         // We write the file into the application directory.
         GetDir(0, outFile);
         outFile := outFile + '\out.pdf.';
         if not pdf.OpenOutputFile(outFile) then begin
            pdf.Free;
            Readln;
            Exit;
         end;
         if pdf.CloseFile then begin
            Writeln(Format('PDF file "%s" successfully created!', [outFile]));
            ShellExecute(0, PChar('open'), PChar(OutFile), nil, nil, SW_SHOWMAXIMIZED);
         end;
      end;
   except
      on E: Exception do begin
         Writeln(E.Message);
      end;
   end;
   if pdf <> nil then pdf.Free;
end;
  
begin
   CreateBookmarks;
end.

program table_images;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  ShellAPI,
  LumasPdfApi in '..\..\include\LumasPdfApi.pas';

// Error callback function.
// If the function name should not appear at the beginning of the error message set
// the flag emNoFuncNames (pdf.SetErrorMode(emNoFuncNames);). 
function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // try to continue
end;

procedure TestTableImages();
var pdf: TPDF; outFile: String; fileOpened: Boolean; timeStart, fullSize: Cardinal; i, rowNum: Integer; tbl: TPDFTable; sr: TSearchRec; err: TPDFError;
begin
   fileOpened := false;
   timeStart  := GetTickCount();

   pdf := nil;
   tbl := nil;
   try
      pdf := TPDF.Create();
      pdf.SetOnErrorProc(nil, @ErrProc);

      pdf.CreateNewPDF('');

      pdf.SetPageCoords(pcTopDown);
      pdf.SetResolution(300);

      tbl := TPDFTable.Create(pdf, 100, 4, 500.0, 125.0);
      tbl.SetBoxProperty(-1, -1, tbpBorderWidth, 1.0, 1.0, 1.0, 1.0);
      tbl.SetBoxProperty(-1, -1, tbpCellPadding, 5.0, 5.0, 5.0, 5.0);
      tbl.SetGridWidth(1.0, 1.0);
      tbl.SetFlags(-1, -1, tfUseImageCS);

      if FindFirst( '../../../test_files/images/*.jpg', faAnyFile, sr) <> 0 then raise Exception.Create('Test images not found!');

      i        := 1;
      fullSize := sr.Size;
      rowNum := tbl.AddRow(125.0);
      tbl.SetCellImage(rowNum, 0, true, coCenter, coCenter, 0.0, 0.0, '../../../test_files/images/' + sr.Name, 1);

		while FindNext(sr) = 0 do begin
			if i = 4 then begin
				rowNum := tbl.AddRow(100.0);
				i := 0;
			end;
			Inc(fullSize, sr.Size);
			tbl.SetCellImage(rowNum, i, true, coCenter, coCenter, 0.0, 0.0, '../../../test_files/images/' + sr.Name, 1);
         Inc(i);
		end;
		FindClose(sr);

		pdf.Append;

		tbl.DrawTable(50.0, 50.0, 742.0);
		while tbl.HaveMore do begin
			pdf.EndPage;
			if fullSize > 104857600 then pdf.FlushPages(fpfDefault);
			pdf.Append;
			tbl.DrawTable(50.0, 50.0, 742.0);
		end;
		pdf.EndPage;


		// We draw the same table again but this time with the flag tfScaleToRect
		tbl.SetFlags(-1, -1, tfScaleToRect or tfUseImageCS);
		pdf.Append;

		pdf.SetFont('Arial', fsRegular, 12.0, true, cp1252);
		pdf.WriteText(50.0, 50.0, 'The same table but the flag tfScaleToRect was set.');

		tbl.DrawTable(50.0, 65.0, 742.0);
		while tbl.HaveMore do begin
			pdf.EndPage;
			if fullSize > 104857600 then pdf.FlushPages(fpfDefault);
			pdf.Append;
			tbl.DrawTable(50.0, 50.0, 742.0);
		end;
		pdf.EndPage;

		tbl.Free;
      tbl := nil;

		// A table stores errors and warnings in the error log
		err.StructSize := sizeof(err);
		for i := 0 to pdf.GetErrLogMessageCount - 1 do begin
			pdf.GetErrLogMessage(i, err);
			Writeln(err.Msg);
		end;

		// No fatal error occurred?
		if pdf.HaveOpenDoc then begin
			if not fileOpened then begin
				// We write the file into the application directory.
				GetDir(0, outFile);
				outFile := outFile + '\out.pdf';
				if not pdf.OpenOutputFile(outFile) then begin
					pdf.Free;
					Readln;
					Exit;
				end;
			end;
			if pdf.CloseFile then begin
            timeStart := GetTickCount() - timeStart;
            Writeln(Format('Processing time: %d ms', [timeStart]));
            ShellExecute(0, PChar('open'), PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
			end;
		end;
   except
      on E: Exception do Writeln(E.Message);
   end;
   if tbl <> nil then tbl.Free;
   if pdf <> nil then pdf.Free;
end;

begin
   TestTableImages;
end.

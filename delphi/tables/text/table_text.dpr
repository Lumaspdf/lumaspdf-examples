program table_text;

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

procedure TestTableText();
var pdf: TPDF; outFile, text: String; timeStart: Cardinal; i, rowNum: Integer; tbl: TPDFTable; err: TPDFError;
begin
   timeStart  := GetTickCount();

   pdf := nil;
   tbl := nil;
   try
      pdf := TPDF.Create();
      pdf.SetOnErrorProc(nil, @ErrProc);

      pdf.CreateNewPDF('');

      pdf.SetPageCoords(pcTopDown);

      tbl := TPDFTable.Create(pdf, 3, 3, 500.0, 100.0);
      tbl.SetBoxProperty(-1, -1, tbpBorderWidth, 1.0, 1.0, 1.0, 1.0);
      tbl.SetFont(-1, -1, 'Arial', fsRegular, true, cp1252); 
      tbl.SetFont(-1, 1, 'Arial', fsBold, true, cp1252);
      tbl.SetGridWidth(1.0, 1.0);

      text := 'The cell alignment can be set for text, images, and templates...';

      // -1.0 means use the default row height as specified in the CreateTable() call.
      rowNum := tbl.AddRow(-1.0);
      tbl.SetCellText(rowNum, 0, taLeft, coTop, text);
      tbl.SetCellText(rowNum, 1, taCenter, coTop, text);
      tbl.SetCellText(rowNum, 2, taRight, coTop, text);

      rowNum := tbl.AddRow(-1.0);
      tbl.SetCellText(rowNum, 0, taLeft, coCenter, text);
      tbl.SetCellText(rowNum, 1, taCenter, coCenter, text);
      tbl.SetCellText(rowNum, 2, taRight, coCenter, text);

      rowNum := tbl.AddRow(-1.0);
      tbl.SetCellText(rowNum, 0, taLeft, coBottom, text);
      tbl.SetCellText(rowNum, 1, taCenter, coBottom, text);
      tbl.SetCellText(rowNum, 2, taRight, coBottom, text);

      // Draw the table now
      pdf.Append;
      tbl.DrawTable(50.0, 50.0, 742.0);
      while tbl.HaveMore do begin
         pdf.EndPage;
         pdf.Append;
         tbl.DrawTable(50.0, 50.0, 742.0);
      end;
      pdf.EndPage;


      // Let's change the cell orientation to see what happens...
      tbl.SetCellOrientation(-1, -1, 90);
      pdf.Append;
      pdf.SetFont('Arial', fsRegular, 12.0, true, cp1252);
      pdf.WriteText(50.0, 50.0, 'The same table but the cell orientation was changed to 90 degrees.');

      tbl.DrawTable(50.0, 65.0, 742.0);
      while tbl.HaveMore do begin
         pdf.EndPage;
         pdf.Append;
         tbl.DrawTable(50.0, 50.0, 737.0);
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
         // We write the file into the application directory.
         GetDir(0, outFile);
         outFile := outFile + '\out.pdf';
         if not pdf.OpenOutputFile(outFile) then begin
            pdf.Free;
            Readln;
            Exit;
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
  TestTableText;
end.
 
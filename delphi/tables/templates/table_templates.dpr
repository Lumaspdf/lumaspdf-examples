program table_templates;

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

procedure TestTableTemplates();
var pdf: TPDF; outFile: String; timeStart: Cardinal; i, pageCount, tmpl, rowNum: Integer; tbl: TPDFTable; err: TPDFError;
begin
   timeStart  := GetTickCount();

   pdf := nil;
   tbl := nil;
   try
      pdf := TPDF.Create();
      pdf.SetOnErrorProc(nil, @ErrProc);

      pdf.CreateNewPDF('');

      pdf.SetPageCoords(pcTopDown);

      pdf.SetImportFlags2(if2UseProxy); // Reduce the memory usage

      pdf.OpenImportFile('../../../../dynapdf_help.pdf', ptOpen, '');

      pageCount := pdf.GetInPageCount;
      if pageCount < 1 then raise Exception.Create('Help file not found!');

      tbl := TPDFTable.Create(pdf, pageCount div 4 + 1, 2, 512.12, 0.0);
      tbl.SetBoxProperty(-1, -1, tbpBorderWidth, 1.0, 1.0, 1.0, 1.0);
      tbl.SetBoxProperty(-1, -1, tbpCellPadding, 5.0, 5.0, 5.0, 5.0);
      tbl.SetGridWidth(1.0, 1.0);
      tbl.SetFlags(-1, -1, tfScaleToRect);

      pdf.SetPageFormat(pfUS_Letter);

      rowNum := 0;
      for i := 1 to pageCount do begin
         tmpl := pdf.ImportPage(i);
         if (i and 1) <> 0 then rowNum := tbl.AddRow(335.0);
         tbl.SetCellTemplate(rowNum, (i-1) and 1, true, coCenter, coCenter, tmpl, 0.0, 0.0);
      end;

      // Draw the table now
      pdf.Append;
      tbl.DrawTable(50.0, 50.0, 742.0);
      while tbl.HaveMore do begin
         pdf.EndPage;
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
  TestTableTemplates;
end.

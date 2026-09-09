program table_images;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Lays every *.jpg in test_files\images into a 4-column table (one image per cell,
// native image colour space), draws it, then redraws with tfScaleToRect + caption.
// Uses TLumasPDFTableCore (helper CORE class). Mirrors examples\c\tables\images\table_images.c.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST be first -- binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Types,              // fsRegular, cp1252, pcTopDown, fpfDefault, TPDFError
  Lumas.Pdf.ApiTypes,           // coCenter (TCellAlign), tbpBorderWidth/tbpCellPadding
  Lumas.Pdf.Wrap.Core,          // TLumasPDFCore
  Lumas.Pdf.Wrap.Classes;       // TLumasPDFTableCore

// Table flags missing from the wrapper enum (from dynapdf.pas):
const
  tfScaleToRect = $8;
  tfUseImageCS  = $10;

function ErrProc(const Data: Pointer; ErrCode: Integer;
  const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then
    Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

var
  pdf: TLumasPDFCore;
  tbl: TLumasPDFTableCore;
  imgDir, full: AnsiString;
  sr: TSearchRec;
  i, rowNum, res: Integer;
  fullSize: Int64;
  err: TPDFError;
begin
  imgDir := '..\..\..\..\test_files\images\';

  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');

    pdf.SetPageCoords(Ord(pcTopDown));
    pdf.SetResolution(300);

    tbl := TLumasPDFTableCore.Create(pdf.TblCreateTable(100, 4, 500.0, 125.0));
    try
      tbl.SetBoxProperty(-1, -1, tbpBorderWidth, 1.0, 1.0, 1.0, 1.0);
      tbl.SetBoxProperty(-1, -1, tbpCellPadding, 5.0, 5.0, 5.0, 5.0);
      tbl.SetGridWidth(1.0, 1.0);
      tbl.SetFlags(-1, -1, tfUseImageCS);

      res := FindFirst(string(imgDir) + '*.jpg', faAnyFile, sr);
      if res <> 0 then
      begin
        Writeln('Test images not found!');
        tbl.DeleteTable;
        Exit;
      end;

      i := 1;
      fullSize := sr.Size;
      rowNum := tbl.AddRow(125.0);
      full := imgDir + AnsiString(sr.Name);
      tbl.SetCellImageA(rowNum, 0, True, coCenter, coCenter, 0.0, 0.0, PAnsiChar(full), 1);

      while FindNext(sr) = 0 do
      begin
        if i = 4 then begin rowNum := tbl.AddRow(100.0); i := 0; end;
        Inc(fullSize, sr.Size);
        full := imgDir + AnsiString(sr.Name);
        tbl.SetCellImageA(rowNum, i, True, coCenter, coCenter, 0.0, 0.0, PAnsiChar(full), 1);
        Inc(i);
      end;
      FindClose(sr);

      pdf.Append;
      tbl.DrawTable(50.0, 50.0, 742.0);
      while tbl.HaveMore do
      begin
        pdf.EndPage;
        if fullSize > 104857600 then pdf.FlushPages(fpfDefault);
        pdf.Append;
        tbl.DrawTable(50.0, 50.0, 742.0);
      end;
      pdf.EndPage;

      // Draw the same table again but this time with tfScaleToRect
      tbl.SetFlags(-1, -1, tfScaleToRect or tfUseImageCS);
      pdf.Append;
      pdf.SetFontA('Arial', fsRegular, 12.0, True, cp1252);
      pdf.WriteTextA(50.0, 50.0, 'The same table but the flag tfScaleToRect was set.');
      tbl.DrawTable(50.0, 65.0, 742.0);
      while tbl.HaveMore do
      begin
        pdf.EndPage;
        if fullSize > 104857600 then pdf.FlushPages(fpfDefault);
        pdf.Append;
        tbl.DrawTable(50.0, 50.0, 742.0);
      end;
      pdf.EndPage;

      tbl.DeleteTable;
    finally
      tbl.Free;
    end;

    err.StructSize := SizeOf(err);
    for i := 0 to pdf.GetErrLogMessageCount - 1 do
      if pdf.GetErrLogMessage(i, err) and (err.Msg <> nil) then
        Writeln(string(AnsiString(err.Msg)));

    if pdf.HaveOpenDoc then
    begin
      if not pdf.OpenOutputFileA('out.pdf') then Exit;
      if pdf.CloseFile then Writeln('Done: out.pdf');
    end;
  finally
    pdf.Free;
  end;
end.

program table_templates;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Imports every page of dynapdf_help.pdf as a template and lays them out two per row in
// a table (tfScaleToRect), drawing across as many pages as needed. Uses TLumasPDFTableCore.
// Mirrors examples\c\tables\templates\table_templates.c.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST be first -- binds every engine entry point in-process
  System.SysUtils,
  Lumas.Pdf.Types,              // pcTopDown, if2UseProxy, ptOpen, pfUS_Letter, TPDFError
  Lumas.Pdf.ApiTypes,           // coCenter (TCellAlign), tbpBorderWidth/tbpCellPadding
  Lumas.Pdf.Wrap.Core,          // TLumasPDFCore
  Lumas.Pdf.Wrap.Classes;       // TLumasPDFTableCore

// Table flag missing from the wrapper enum (from dynapdf.pas):
const
  tfScaleToRect = $8;

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
  i, pageCount, tmpl, rowNum: Integer;
  err: TPDFError;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @ErrProc);
    pdf.CreateNewPDFA('');

    pdf.SetPageCoords(Ord(pcTopDown));
    pdf.SetImportFlags2(if2UseProxy);

    pdf.OpenImportFileA('..\..\..\..\dynapdf_help.pdf', Ord(ptOpen), '');

    pageCount := pdf.GetInPageCount;
    if pageCount < 1 then
    begin
      Writeln('Help file not found!');
      Exit;
    end;

    tbl := TLumasPDFTableCore.Create(pdf.TblCreateTable(pageCount div 4 + 1, 2, 512.12, 0.0));
    try
      tbl.SetBoxProperty(-1, -1, tbpBorderWidth, 1.0, 1.0, 1.0, 1.0);
      tbl.SetBoxProperty(-1, -1, tbpCellPadding, 5.0, 5.0, 5.0, 5.0);
      tbl.SetGridWidth(1.0, 1.0);
      tbl.SetFlags(-1, -1, tfScaleToRect);

      pdf.SetPageFormat(Ord(pfUS_Letter));

      rowNum := 0;
      for i := 1 to pageCount do
      begin
        tmpl := pdf.ImportPage(i);
        if (i and 1) <> 0 then rowNum := tbl.AddRow(335.0);
        tbl.SetCellTemplate(rowNum, (i - 1) and 1, True, coCenter, coCenter, tmpl, 0.0, 0.0);
      end;

      pdf.Append;
      tbl.DrawTable(50.0, 50.0, 742.0);
      while tbl.HaveMore do
      begin
        pdf.EndPage;
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

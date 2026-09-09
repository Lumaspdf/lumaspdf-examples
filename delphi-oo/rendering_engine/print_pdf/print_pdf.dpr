program print_pdf;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF class), NOT the flat API.
// Port of examples\c\rendering_engine\print_pdf\print_pdf.c
// Loads a PDF, imports the first page and prints it. A printer is chosen via the
// standard Print dialog (PrintDlg). This opens the Windows print dialog (needs a
// printer/UI) -> compile-only in automated runs.
{$APPTYPE CONSOLE}
uses
  Winapi.Windows,
  Winapi.CommDlg,
  System.SysUtils,
  LumasPdf     in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO   in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

function GetPrinterDC: HDC;
var pd: TPrintDlgA;
begin
  FillChar(pd, SizeOf(pd), 0);
  pd.lStructSize := SizeOf(pd);
  pd.Flags := PD_RETURNDC or PD_HIDEPRINTTOFILE or PD_DISABLEPRINTTOFILE or PD_NOSELECTION;
  if PrintDlgA(pd) then
    Result := pd.hDC
  else
  begin
    Writeln('Cancelled!');
    Result := 0;
  end;
end;

var
  pdf: TPDF;
  dc: HDC;
begin
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    pdf.CreateNewPDFA('');

    pdf.SetImportFlags(ifImportAll or ifImportAsPage);
    if pdf.OpenImportFileA('../../../../dynapdf_help.pdf', ptOpen, '') < 0 then
      Exit;

    pdf.Append;
    pdf.ImportPageEx(1, 1.0, 1.0);
    pdf.EndPage;

    pdf.ApplyAppEvent(aePrint, False);

    dc := GetPrinterDC;
    if dc <> 0 then
    begin
      if pdf.PrintPDFFileA('', 'Test Print', dc,
           pffDefault or pffAutoRotateAndCenter or pffShrinkToPrintArea, nil, nil) then
        Writeln('Page 1 successfully printed');
      DeleteDC(dc);
    end;
  finally
    pdf.Free;
  end;
end.

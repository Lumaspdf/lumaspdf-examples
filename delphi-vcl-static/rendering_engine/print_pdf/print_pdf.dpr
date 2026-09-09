program print_pdf;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Loads a PDF, imports the first page and prints it via the standard Print dialog.
// Needs a printer/UI -> compile-only in automated runs. Wrap.Static MUST be first.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // binds every engine entry point in-process
  Winapi.Windows,
  Winapi.CommDlg,
  System.SysUtils,
  Lumas.Pdf.Types,              // enums (import/print flags, app events)
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore (flat API as methods)

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
  pdf: TLumasPDFCore;
  dc: HDC;
begin
  pdf := TLumasPDFCore.Create;
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

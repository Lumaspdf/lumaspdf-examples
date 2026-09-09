program image_extraction;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  Classes,
  {$IF RTLVersion >= 23}Vcl.{$IFEND}Graphics,
  CommDlg,
  LumasPdfApi in '..\..\include\LumasPdfApi.pas';

{
   Note that the dynapdf.dll must be copied into the output directory or into a
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

function GetPrinterDC(): HDC;
var pd: TPrintDlg;
begin
   FillChar(pd, SizeOf(pd), 0);
   pd.lStructSize := SizeOf(pd);
   pd.Flags := PD_RETURNDC or PD_HIDEPRINTTOFILE or PD_DISABLEPRINTTOFILE or PD_NOSELECTION;
   if PrintDlg(pd) = TRUE then
      Result := pd.hDC
   else begin
      WriteLn('Cancelled!'#13);
      Result := 0;
   end;
end;

procedure PrintPage;
var pdf: TPDF; dc: HDC;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      pdf.CreateNewPDF(''); // We create no PDF file in this example

      // Import anything and don't convert pages to templates
      pdf.SetImportFlags(ifImportAll or ifImportAsPage);
      if pdf.OpenImportFile('../../../../dynapdf_help.pdf', ptOpen, '') < 0 then begin
         pdf.Free;
         Exit;
      end;
      
      // We print only the first page in this example.
      pdf.Append;
         pdf.ImportPageEx(1, 1.0, 1.0);
      pdf.EndPage;

      // If the file contains layers then ApplyAppEvent() makes sure that the same result will be printed
      // that Adobe's Acrobat would print. However, you can also print the view or export state if you want.
      // The help file doesn't contain layers and this command does just nothing but, in a real world
      // application ApplyAppEvent() should be called.
      pdf.ApplyAppEvent(aePrint, false);

      dc := GetPrinterDC();
      if dc <> 0 then begin
         if pdf.PrintPDFFile('', 'Test Print', dc, pffDefault or pffAutoRotateAndCenter or pffShrinkToPrintArea, nil, nil) then
            WriteLn('Page 1 successfully printed'#13);
         DeleteDC(dc);
      end;
   except
      on E: Exception do begin
         Writeln(E.Message);
      end;
   end;
   if pdf <> nil then pdf.Free;
end;
  
begin
   PrintPage;
end.

program image_extraction;

{$APPTYPE CONSOLE}

uses
  Windows,
  SysUtils,
  Classes,
  {$IF RTLVersion >= 23}Vcl.{$IFEND}Graphics,
  ShellAPI,
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

procedure RenderPageToImage;
var w: Integer; pdf: TPDF; dc: HDC; filePath: String;
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
      
      // We render only the first page in this example.
      pdf.Append;
         pdf.ImportPageEx(1, 1.0, 1.0);
      pdf.EndPage;

      dc := GetDC(0);
      w  := GetDeviceCaps(dc, HORZRES);
      ReleaseDC(0, dc);

      filePath := ExpandFileName('out.tif');
      if pdf.RenderPageToImage(1, filePath, 0, w, 0, rfDefault, pxfRGB, cfLZW, ifmTIFF) then begin
         Writeln(Format('TIFF image "%s" successfully created!', [filePath]));
         ShellExecute(0, PChar('open'), PChar(filePath), nil, nil, SW_SHOWMAXIMIZED);
      end;
   except
      on E: Exception do begin
         Writeln(E.Message);
      end;
   end;
   if pdf <> nil then pdf.Free;
end;
  
begin
   RenderPageToImage;
end.

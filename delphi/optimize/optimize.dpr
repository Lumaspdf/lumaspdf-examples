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
   Note that the dynapdf.dll must be copied into the output directory or into a
   Windwos search path (e.g. %WINDOWS%/System32) before the application can be executed!
}

// Error callback function.
// Note that the error callback function is often called to output warnings if something must be changed or if the file contained errors.
// The function should normally return zero and fill an error log with the error messages. Any other return value breaks processing and no
// PDF file will be created but this is usually not what we want.
function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // Return zero to continue
end;

function FontNotFoundProc(const Data, PDFFont: Pointer; const FontName: PAnsiChar; Style: TFStyle; StdFontIndex: Integer; IsSymbolFont: LongBool): Integer; stdcall;
var pdf: TPDF;
begin
   pdf := TPDF(Data);
   if pdf.WeightFromStyle(Style) < 500 then
      Style := Style and $0F or fsRegular;

   Result := pdf.ReplaceFont(PDFFont, 'Arial', Style, true);
end;

function ReplaceICCProfileProc(const Data: Pointer; ProfileType: TICCProfileType; ColorSpace: Integer): Integer; stdcall;
var pdf: TPDF;
begin
   pdf := TPDF(Data);
   // The most important ICC profiles are available free of charge from Adobe. Just seach for "Adobe icc profiles".

   // A gray profile is optional
   case ProfileType of
      ictRGB:  Result := pdf.ReplaceICCProfile(ColorSpace, '../../test_files/sRGB.icc');
      ictCMYK: Result := pdf.ReplaceICCProfile(ColorSpace, '../../test_files/ISOcoated_v2_bas.ICC');
      else     Result := pdf.ReplaceICCProfile(ColorSpace, '../../test_files/sRGB.icc');  // A gray, RGB, or CMYK profile can be used here
   end;
end;

function Optimize(const PDF: TPDF; const InFile: String; const OutFile: String): Boolean;
var i, retval: Integer; e: TPDFError; 
begin
   Result := false;
   PDF.CreateNewPDF('');           // The output file is opened later
   PDF.SetDocInfo(diProducer, ''); // No need to override the original producer

   // The flag ifImportAsPage makes sure that pages will not be converted to templates.
   // We don't import a piece info dictionary here since this dictionary contains private data that
   // is only usable in the application that created the data. InDesign, for example, stores original
   // images and document files in this dictionary, if external resources were placed on a page.
   PDF.SetImportFlags((ifImportAll or ifImportAsPage) and not ifPieceInfo);
   // The flag if2UseProxy reduces the memory usage. The duplicate check is optional but recommended.
   // The resource name check can be omitted when we optimize a PDF file.
   PDF.SetImportFlags2(if2UseProxy or if2DuplicateCheck or if2Normalize or if2NoResNameCheck);
   retval := PDF.OpenImportFile(InFile, ptOpen, '');
   if retval < 0 then begin
      if PDF.IsWrongPwd(retval) then
         WriteLn('File is encrypted!');
      PDF.FreePDF;
      Exit;
   end;
   PDF.ImportPDFFile(1, 1.0, 1.0);
   PDF.CloseImportFile;

   PDF.Optimize(ofInMemory or ofNewLinkNames or ofDeleteInvPaths, nil);

   FillChar(e, SizeOf(e), 0);
   e.StructSize := SizeOf(e);
   for i := 0 to PDF.GetErrLogMessageCount -1 do begin
      PDF.GetErrLogMessage(i, e);
      Writeln(e.Msg);
   end;

   // No fatal error occurred?
   if PDF.HaveOpenDoc then begin
      // We write the file into the application directory.
      if not PDF.OpenOutputFile(OutFile) then begin
         PDF.Free;
         Readln;
         Exit;
      end;
      Result := PDF.CloseFile;
   end;
end;

procedure Convert();
var pdf: TPDF; filePath: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);
      
      pdf.SetCMapDir(ExpandFileName('../../../Resource/CMap'), lcmDelayed or lcmRecursive);
      // To improve the conversion speed process as much files as possible with one PDF instance.
      filePath := ExpandFileName('out.pdf');
      if Optimize(pdf, ExpandFileName('../../../dynapdf_help.pdf'), filePath) then begin
         Writeln(Format('PDF file "%s" successfully created!', [filePath]));
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
   Convert;
end.


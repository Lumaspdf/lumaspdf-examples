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
   Note that the LumasPdf.dll must be copied into the output directory or into a
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
      ictRGB:  Result := pdf.ReplaceICCProfile(ColorSpace, '../../../test_files/sRGB.icc');
      ictCMYK: Result := pdf.ReplaceICCProfile(ColorSpace, '../../../test_files/ISOcoated_v2_bas.ICC');
      else     Result := pdf.ReplaceICCProfile(ColorSpace, '../../../test_files/gray.icc');
   end;
end;

function ConvertFile(const PDF: TPDF; ConvType: TConformanceType; const InFile: String; const OutFile: String): Boolean;
var i, retval, convFlags: Integer; e: TPDFError;
begin
   Result := false;
   PDF.CreateNewPDF('');           // The output file is opened later
   PDF.SetDocInfo(diProducer, ''); // No need to override the original producer
   
   case ConvType of
      ctNormalize:    convFlags := coAllowDeviceSpaces;                                               // For normalization it is not required to convert device spaces to ICC based color spaces.
      ctPDFA_1b_2005: convFlags := coDefault or coFlattenLayers;                                      // Presentations are not prohibited in PDF/A 1.
      ctPDFA_2b,
      ctPDFA_2u:      convFlags := coDefault or coDeletePresentation;
   else
      // ctPDFA_3b, ctPDFA_4, ctPDFA_4e, ctPDFA_4f, ctZUGFeRD_Basic, ctZUGFeRD_Comfort, ctZUGFeRD_Extended, ctZUGFeRD2_xxx, ctFacturX_xxx
      convFlags := (coDefault or coDeletePresentation) and not coDeleteEmbeddedFiles; // Embedded files are allowed in PDF/A 3 and PDF/A 4.
   end;

   // These flags require some processing time but they are very useful.
   convFlags := convFlags or coCheckImages;
   convFlags := convFlags or coRepairDamagedImages;
   
   if ConvType <> ctNormalize then begin
      // The flag ifPrepareForPDFA is required. The flag ifImportAsPage makes sure that pages will not be converted to templates.
      PDF.SetImportFlags(ifImportAll or ifImportAsPage or ifPrepareForPDFA);
      // The flag if2UseProxy reduces the memory usage. The duplicate check is optional but recommended.
      PDF.SetImportFlags2(if2UseProxy or if2DuplicateCheck);
   end else begin
      PDF.SetImportFlags(ifImportAll or ifImportAsPage);
      PDF.SetImportFlags2(if2UseProxy or if2DuplicateCheck or if2Normalize);
   end;
   retval := PDF.OpenImportFile(InFile, ptOpen, '');
   if retval < 0 then begin
      if PDF.IsWrongPwd(retval) then
         WriteLn('File is encrypted!');
      PDF.FreePDF;
      Exit;
   end;
   PDF.ImportPDFFile(1, 1.0, 1.0);
   PDF.CloseImportFile;

   retval := PDF.CheckConformance(ConvType, TCheckOptions(convFlags), PDF, @FontNotFoundProc, @ReplaceICCProfileProc);
   case retval of
      1: PDF.AddOutputIntent('../../../test_files/sRGB.icc');
      2: PDF.AddOutputIntent('../../../test_files/ISOcoated_v2_bas.ICC'); // The CMYK profile is just an example profile that can be delivered with the classic API.
      3: PDF.AddOutputIntent('../../../test_files/gray.icc');             // A gray, RGB, or CMYK profile can be used here.
   end;

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

      pdf.SetCMapDir(ExpandFileName('../../../../Resource/CMap'), lcmDelayed or lcmRecursive);
      // To improve the conversion speed process as much files as possible with one PDF instance.
      filePath := ExpandFileName('out.pdf');

      {
         To create a ZUGFeRD invoice attach the required XML invoice here and set the conversion type to the ZUGFeRD profile that you need.

         Example (ZUGFeRD 2.1):
         pdf.AttachFile('c:/invoices/test/factur-x.xml', 'ZUGFeRD 2.1 Rechnung', true);
         if ConvertFile(pdf, ctFacturX_Comfort, ExpandFileName('../../../../sample_multipage.pdf'), filePath) then begin
            Writeln(Format('PDF file "%s" successfully created!', [filePath]));
            ShellExecute(0, PChar('open'), PChar(filePath), nil, nil, SW_SHOWMAXIMIZED);
         end;

         The file name of the XML invoice must be ZUGFeRD-invoice.xml. If the file has another name than rename it or use AttachFileEx() instead.
      }
      
      if ConvertFile(pdf, ctPDFA_3b, ExpandFileName('../../../../sample_multipage.pdf'), filePath) then begin
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


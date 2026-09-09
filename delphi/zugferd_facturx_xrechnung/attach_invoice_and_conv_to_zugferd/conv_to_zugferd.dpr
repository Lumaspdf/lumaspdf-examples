program conv_to_zugferd;

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

function ConvertFile(const PDF: TPDF; ConvType: TConformanceType; const InFile, Invoice, OutFile: String): Boolean;
var ef, retval, convFlags: Integer;
begin
   Result := false;
   PDF.CreateNewPDF('');           // The output file is opened later
   PDF.SetDocInfo(diProducer, ''); // No need to override the original producer
   
   case ConvType of
      ctFacturX_Comfort, ctFacturX_Extended, ctFacturX_XRechnung: convFlags := coDefault_PDFA_3;
   else
      Exit; // We create e-invoices in this example and nothing else.
   end;

   PDF.CreateNewPDF('');                         // The output file will be created later
   PDF.SetDocInfo(TDocumentInfo.diProducer, ''); // No need to override the original producer

   // These flags require some processing time but they are very useful.
   convFlags := coCheckImages Or coRepairDamagedImages;

   // The flag ifPrepareForPDFA is required. The flag ifImportAsPage makes sure that pages are not converted to templates.
   PDF.SetImportFlags(ifImportAll Or ifImportAsPage Or ifPrepareForPDFA);
   // The flag if2UseProxy reduces the memory usage.
   PDF.SetImportFlags2(if2UseProxy);

   PDF.OpenImportFile(InFile, ptOpen, '');
   PDF.ImportPDFFile(1, 1.0, 1.0);
   PDF.CloseImportFile();

   {
      The invoice should be the first attachment if further files must be attached.
      If the file name of the invoice is not factur-x.xml (case sensitive!) then use AttachFileEx() instead.
      In the case of the German XRechnung the file name must be "xrechnung.xml".
   }

   ef := PDF.AttachFile(Invoice, 'EN 16931 compliant invoice', false);
   if ConvType <> ctFacturX_XRechnung then
      PDF.AssociateEmbFile(adCatalog, -1, arAlternative, ef)
   else
      PDF.AssociateEmbFile(adCatalog, -1, arSource, ef);

   // An invoice should not use CMYK colors since a CMYK ICC profile must be embedded in this case and such a profile is pretty large!
   // Note that this code requires the PDF/A Extension for DynaPDF.
   retval := PDF.CheckConformance(ConvType, TCheckOptions(convFlags), PDF, @FontNotFoundProc, @ReplaceICCProfileProc);
   case retval of
      1: PDF.AddOutputIntent('../../../test_files/sRGB.icc');
      2: PDF.AddOutputIntent('../../../test_files/ISOcoated_v2_bas.ICC'); // The CMYK profile is just an example profile that can be delivered with DynaPDF.
      3: PDF.AddOutputIntent('../../../test_files/gray.icc');             // A gray, RGB, or CMYK profile can be used here.
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
var pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);

      // Non embedded CID fonts depend usually on the availability of external cmaps.
      // So, external cmaps should be loaded if possible.
      pdf.SetCMapDir(ExpandFileName('../../../Resource/CMap'), lcmDelayed or lcmRecursive);

      outFile := ExpandFileName('out.pdf');

      // The profiles Minimum, Basic, and Basic WL are not EN 16931 compliant and hence cannot be used to create e-invoices.
      if ConvertFile(pdf, ctFacturX_Comfort, '../../../test_files/test_invoice.pdf', '../../../test_files/factur-x.xml', outFile) then begin
         Writeln(Format('PDF file "%s" successfully created!', [outFile]));
         ShellExecute(0, PChar('open'), PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
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

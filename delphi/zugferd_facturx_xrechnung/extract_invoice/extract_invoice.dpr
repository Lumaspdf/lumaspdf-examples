program extract_invoice;

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

// Helper functions

procedure SetColorConsole(AColor:TColor);
begin
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE);
  case AColor of
    clRed:    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 12);
    clGreen:  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 10);
    clYellow: SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 14);
    clWhite:  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
  end;
end;

function GetFileBuffer(FileName: String; var BufSize: Integer): PByte;
var strm: TFileStream;
begin
   strm := nil;
   try
      strm    := TFileStream.Create(FileName, fmOpenRead);
      BufSize := strm.Size;
      GetMem(Result, BufSize);
      strm.Read(Result^, BufSize);
   finally
      FreeAndNil(strm);
   end;
end;

// Error callback function.
// If the function name should not appear at the beginning of the error message set
// the flag emNoFuncNames (pdf..SetErrorMode(emNoFuncNames);). 
function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   Writeln(ErrMessage);
   Result := 0; // We try to continue if an error occurs
end;

function HaveEInvoice(const PDF: TPDF; const InFileName: String): Boolean;
var ef: Integer; info: TPDFVersionInfo; fs: TPDFFileSpec;
begin
   Result := false;
   FillChar(info, sizeof(info), 0);
   info.StructSize := sizeof(info);

   PDF.CreateNewPDF('');
   // We need the document info or metadata and embedded files only
   PDF.SetImportFlags(ifDocInfo Or ifEmbeddedFiles);
   PDF.SetImportFlags2(if2UseProxy);
   try
      if PDF.OpenImportFile(InFileName, ptOpen, '') < 0 then Exit;

      // Other stuff can be ignored
      PDF.ImportCatalogObjects();

      if not PDF.GetPDFVersionEx(info) then Exit;

      if (info.PDFAVersion <> 3) Or (info.FXDocName = nil) then Exit;
      // Be careful with PAnsiChar. The typecast to AnsiString is required since Delphi tries to determine the string format otherwise
      // and this causes often a buffer overrun!
      ef := PDF.FindEmbeddedFile(WideString(AnsiString(info.FXDocName)));
      if ef < 0 then begin
         SetColorConsole(clRed);
         WriteLn(Format('Invoice %s not found!\n', [info.FXDocName]));
         Exit;
      end;
      if ef <> 0 then begin
         SetColorConsole(clYellow);
         WriteLn('Warning: The invoice should be the first file attachment. This might cause unnecessary problems.\n');
      end;
      FillChar(fs, sizeof(fs), 0);
      Result := PDF.GetEmbeddedFile(ef, fs, true) and (fs.BufSize > 0);
   finally
      PDF.FreePDF();
   end;
end;

function CreateInvoice(const PDF: TPDF; FacturX: Boolean; const InvoiceName, OutFile: String): Boolean;
var ef, bufSize: Integer; buffer: PByte;
begin
   Result := false;
   PDF.CreateNewPDF('');           // The output file is opened later
   PDF.SetDocInfo(diProducer, ''); // No need to override the original producer
   
   try
      if PDF.OpenImportFile('../../../test_files/test_invoice.pdf', ptOpen, '') < 0 then Exit;

      PDF.ImportPDFFile(1, 1.0, 1.0);

      {
         The test invoice has the file name factur-x.xml but we must be able to override the name
         since the German XRechnung requires the name xrechnung.xml. With AttachFileEx() we can
         specify the file name. So, this is the right function for this test.
      }
   
      bufSize := 0;
      buffer  := GetFileBuffer('../../../test_files/factur-x.xml', bufSize);
      ef      := PDF.AttachFileEx(buffer, bufSize, InvoiceName, 'EN 19631 compliant invoice', false);
      if buffer <> nil then FreeMem(buffer);

      {
         Note that ZUGFeRD 2.1 or higher and FacturX is identically defined in PDF. Therefore, both formats share
         the same version constants. Note also that the profiles Minimum, Basic, and Basic WL are not fully EN 16931
         compliant, and therefore cannot be used to create e-invoices.
      }
      if FacturX then begin
         PDF.SetPDFVersion(pvFacturX_Comfort);
         PDF.AssociateEmbFile(adCatalog, -1, arAlternative, ef);
      end else begin
         PDF.SetPDFVersion(pvFacturX_XRechnung);
         PDF.AssociateEmbFile(adCatalog, -1, arSource, ef);
      end;

      // No fatal error occurred?
      if PDF.HaveOpenDoc and PDF.OpenOutputFile(OutFile) then
         Result := PDF.CloseFile;
   finally
      PDF.FreePDF();
   end;
end;

procedure Convert();
var pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      pdf.SetOnErrorProc(nil, @PDFError);

      // We write the test files into the application directory.
      GetDir(0, outFile);
      outFile := outFile + '\out.pdf.';

      // Test cases:
      // - ZUGFeRD or FacturX
      // - XRechnung -> The invoice name must be xrechnung.xml
      if not CreateInvoice(pdf, true,  'factur-x.xml',  outFile) Or not HaveEInvoice(pdf, outFile)
      Or not CreateInvoice(pdf, false, 'xrechnung.xml', outFile) Or not HaveEInvoice(pdf, outFile) then begin
         SetColorConsole(clRed);
         WriteLn('XML Invoice not found!');
      end else begin
         SetColorConsole(clGreen);
         WriteLn('All tests passed!');
      end;
   except
      on E: Exception do begin
         Writeln(E.Message);
      end;
   end;
   FreeAndNil(pdf);
   ReadLn;
end;
  
begin
   Convert;
end.

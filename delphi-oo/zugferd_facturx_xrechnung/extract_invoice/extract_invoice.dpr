program extract_invoice;
// Delphi OO example -- uses the LumasPdfOO wrapper (TPDF), NOT the flat API.
// Creates FacturX and XRechnung invoices (attaching factur-x.xml from a memory
// buffer via AttachFileEx) and verifies the embedded e-invoice can be found and
// extracted again.
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  LumasPdf     in '..\..\..\..\wrappers\delphi\LumasPdf.pas',
  LumasPdfOO   in '..\..\..\..\wrappers\delphi\LumasPdfOO.pas';

const
  clRed    = $FF;
  clGreen  = $8000;
  clYellow = $FFFF;
  clWhite  = $FFFFFF;

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

procedure SetColorConsole(AColor: LongInt);
var h: THandle;
begin
  h := GetStdHandle(STD_OUTPUT_HANDLE);
  SetConsoleTextAttribute(h, 7);
  case AColor of
    clRed:    SetConsoleTextAttribute(h, 12);
    clGreen:  SetConsoleTextAttribute(h, 10);
    clYellow: SetConsoleTextAttribute(h, 14);
    clWhite:  SetConsoleTextAttribute(h, 15);
  end;
end;

function GetFileBuffer(const FileName: string): TBytes;
var fs: TFileStream;
begin
  Result := nil;
  if not FileExists(FileName) then Exit;
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, fs.Size);
    if fs.Size > 0 then fs.ReadBuffer(Result[0], fs.Size);
  finally
    fs.Free;
  end;
end;

function HaveEInvoice(pdf: TPDF; const InFileName: PAnsiChar): Boolean;
var
  ef: Integer;
  info: TPDFVersionInfo;
  fs: TPDFFileSpec;
begin
  Result := False;
  FillChar(info, SizeOf(info), 0);
  info.StructSize := SizeOf(info);

  pdf.CreateNewPDFA('');
  pdf.SetImportFlags(ifDocInfo or ifEmbeddedFiles);
  pdf.SetImportFlags2(if2UseProxy);
  try
    if pdf.OpenImportFileA(InFileName, ptOpen, '') < 0 then Exit;
    pdf.ImportCatalogObjects;

    if not pdf.GetPDFVersionEx(info) then Exit;
    if (info.PDFAVersion <> 3) or (info.FXDocName = nil) then Exit;

    ef := pdf.FindEmbeddedFileA(info.FXDocName);
    if ef < 0 then
    begin
      SetColorConsole(clRed);
      Writeln('Invoice ' + string(AnsiString(info.FXDocName)) + ' not found!');
      Exit;
    end;
    if ef <> 0 then
    begin
      SetColorConsole(clYellow);
      Writeln('Warning: The invoice should be the first file attachment.');
    end;
    FillChar(fs, SizeOf(fs), 0);
    if pdf.GetEmbeddedFile(ef, fs, True) then
      Result := fs.BufSize > 0;
  finally
    pdf.FreePDF;
  end;
end;

function CreateInvoice(pdf: TPDF; FacturX: Boolean; const InvoiceName, OutFile: PAnsiChar): Boolean;
var
  ef: Integer;
  buffer: TBytes;
begin
  Result := False;
  pdf.CreateNewPDFA('');
  pdf.SetDocInfoA(diProducer, '');
  try
    if pdf.OpenImportFileA('../../../test_files/test_invoice.pdf', ptOpen, '') < 0 then Exit;
    pdf.ImportPDFFile(1, 1.0, 1.0);

    buffer := GetFileBuffer('../../../test_files/factur-x.xml');
    if (buffer <> nil) and (Length(buffer) > 0) then
      ef := pdf.AttachFileExA(@buffer[0], Length(buffer), InvoiceName, 'EN 19631 compliant invoice', False)
    else
      ef := pdf.AttachFileExA(nil, 0, InvoiceName, 'EN 19631 compliant invoice', False);

    if FacturX then
    begin
      pdf.SetPDFVersion(pvFacturX_Comfort);
      pdf.AssociateEmbFile(adCatalog, -1, arAlternative, ef);
    end
    else
    begin
      pdf.SetPDFVersion(pvFacturX_XRechnung);
      pdf.AssociateEmbFile(adCatalog, -1, arSource, ef);
    end;

    if pdf.HaveOpenDoc then
      if pdf.OpenOutputFileA(OutFile) then
        Result := pdf.CloseFile;
  finally
    pdf.FreePDF;
  end;
end;

const
  outFile = 'out.pdf';
var
  pdf: TPDF;
begin
  pdf := TPDF.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);

    if (not CreateInvoice(pdf, True, 'factur-x.xml', outFile)) or (not HaveEInvoice(pdf, outFile)) or
       (not CreateInvoice(pdf, False, 'xrechnung.xml', outFile)) or (not HaveEInvoice(pdf, outFile)) then
    begin
      SetColorConsole(clRed);
      Writeln('XML Invoice not found!');
    end
    else
    begin
      SetColorConsole(clGreen);
      Writeln('All tests passed!');
    end;
  finally
    pdf.Free;
  end;
end.

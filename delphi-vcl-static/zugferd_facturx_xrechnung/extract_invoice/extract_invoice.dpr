program extract_invoice;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Creates FacturX and XRechnung invoices (attaching factur-x.xml from a memory buffer
// via AttachFileEx) and verifies the embedded e-invoice can be found and extracted.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST be first
  Winapi.Windows,               // GetStdHandle / SetConsoleTextAttribute
  System.SysUtils,
  System.Classes,
  Lumas.Pdf.Types,              // if*, ptOpen, ad*/ar*, pv*, di*
  Lumas.Pdf.ApiTypes,           // TPDFVersionInfo, TPDFFileSpec
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore

const
  clRed    = $0000FF;
  clGreen  = $008000;
  clYellow = $00FFFF;
  clWhite  = $FFFFFF;

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

procedure SetColorConsole(AColor: Longint);
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

function GetFileBuffer(const FileName: string; out BufSize: Cardinal): TBytes;
var fs: TFileStream;
begin
  Result := nil;
  BufSize := 0;
  if not FileExists(FileName) then Exit;
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    if fs.Size <= 0 then Exit;
    SetLength(Result, fs.Size);
    fs.ReadBuffer(Result[0], fs.Size);
    BufSize := Cardinal(fs.Size);
  finally
    fs.Free;
  end;
end;

function HaveEInvoice(pdf: TLumasPDFCore; const InFileName: string): Boolean;
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

  if pdf.OpenImportFileA(PAnsiChar(AnsiString(InFileName)), Ord(ptOpen), '') < 0 then
  begin
    pdf.FreePDF; Exit;
  end;
  pdf.ImportCatalogObjects;

  if not pdf.GetPDFVersionEx(info) then begin pdf.FreePDF; Exit; end;
  if (info.PDFAVersion <> 3) or (info.FXDocName = nil) then begin pdf.FreePDF; Exit; end;

  ef := pdf.FindEmbeddedFileA(info.FXDocName);
  if ef < 0 then
  begin
    SetColorConsole(clRed);
    Writeln('Invoice ' + string(AnsiString(info.FXDocName)) + ' not found!');
    pdf.FreePDF; Exit;
  end;
  if ef <> 0 then
  begin
    SetColorConsole(clYellow);
    Writeln('Warning: The invoice should be the first file attachment.');
  end;
  FillChar(fs, SizeOf(fs), 0);
  if pdf.GetEmbeddedFile(Cardinal(ef), fs, True) then
    Result := fs.BufSize > 0;
  pdf.FreePDF;
end;

function CreateInvoice(pdf: TLumasPDFCore; FacturX: Boolean; const InvoiceName, OutFile: string): Boolean;
var
  ef: Integer;
  bufSize: Cardinal;
  buffer: TBytes;
  pBuf: Pointer;
begin
  Result := False;
  pdf.CreateNewPDFA('');
  pdf.SetDocInfoA(diProducer, '');

  if pdf.OpenImportFileA('../../../test_files/test_invoice.pdf', Ord(ptOpen), '') < 0 then
  begin
    pdf.FreePDF; Exit;
  end;
  pdf.ImportPDFFile(1, 1.0, 1.0);

  buffer := GetFileBuffer('../../../test_files/factur-x.xml', bufSize);
  if (buffer <> nil) and (bufSize > 0) then pBuf := @buffer[0] else pBuf := nil;
  ef := pdf.AttachFileExA(pBuf, bufSize, PAnsiChar(AnsiString(InvoiceName)), 'EN 19631 compliant invoice', False);

  if FacturX then
  begin
    pdf.SetPDFVersion(pvFacturX_Comfort);
    pdf.AssociateEmbFile(adCatalog, -1, arAlternative, Cardinal(ef));
  end
  else
  begin
    pdf.SetPDFVersion(pvFacturX_XRechnung);
    pdf.AssociateEmbFile(adCatalog, -1, arSource, Cardinal(ef));
  end;

  if pdf.HaveOpenDoc then
    if pdf.OpenOutputFileA(PAnsiChar(AnsiString(OutFile))) then
      Result := pdf.CloseFile;
  pdf.FreePDF;
end;

const
  outFile = 'out.pdf';
var
  pdf: TLumasPDFCore;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);

    if (not CreateInvoice(pdf, True,  'factur-x.xml', outFile)) or (not HaveEInvoice(pdf, outFile)) or
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
    SetColorConsole(clWhite);
  finally
    pdf.Free;
  end;
end.

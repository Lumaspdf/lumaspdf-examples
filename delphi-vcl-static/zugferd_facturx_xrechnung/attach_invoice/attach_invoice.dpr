program attach_invoice;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Imports an existing PDF/A-3 invoice, attaches factur-x.xml, associates it with the
// catalog and sets the FacturX Comfort PDF version.
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST be first
  System.SysUtils,
  Lumas.Pdf.Types,              // if*, ptOpen, adCatalog, arAlternative, pvFacturX_Comfort
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

const
  outFile = 'out.pdf';
var
  pdf: TLumasPDFCore;
  ef: Integer;
begin
  pdf := TLumasPDFCore.Create;
  try
    pdf.SetOnErrorProc(nil, @PDFError);
    pdf.CreateNewPDFA('');

    pdf.SetImportFlags(ifImportAsPage or ifImportAll);
    pdf.OpenImportFileA('../../../test_files/test_invoice.pdf', Ord(ptOpen), '');
    pdf.ImportPDFFile(1, 1.0, 1.0);

    ef := pdf.AttachFileA('../../../test_files/factur-x.xml', 'EN 16931 compliant invoice', False);
    pdf.AssociateEmbFile(adCatalog, -1, arAlternative, Cardinal(ef));

    pdf.SetPDFVersion(pvFacturX_Comfort);

    if pdf.HaveOpenDoc then
    begin
      if not pdf.OpenOutputFileA(outFile) then Exit;
      if pdf.CloseFile then Writeln('PDF file "' + outFile + '" successfully created!');
    end;
  finally
    pdf.Free;
  end;
end.

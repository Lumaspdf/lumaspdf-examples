program conv_to_zugferd;
// PURE VCL static example -- engine linked INTO this exe (LUMAS_STATIC), no LumasPdf.dll.
// Converts a PDF to PDF/A-3 (FacturX Comfort), attaches factur-x.xml and adds an
// output intent. Uses font-not-found and ICC-profile replacement callbacks (native).
{$APPTYPE CONSOLE}
uses
  Lumas.Pdf.Wrap.Static,        // MUST be first
  System.SysUtils,
  Lumas.Pdf.Types,              // ct*, ict*, if*, ptOpen, ad*/ar*, di*, TFStyle, TICCProfileType
  Lumas.Pdf.Wrap.Core;          // TLumasPDFCore

const
  coDefault_PDFA_3        = $50EF7F;   // not exported as a const; its computed value
  coCheckImages_v         = $00800000;
  coRepairDamagedImages_v = $02000000;

var
  gPDF: TLumasPDFCore;                 // used by the native callbacks (static: engine in-process)

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
  if ErrMessage <> nil then Writeln(string(AnsiString(ErrMessage)));
  Result := 0;
end;

// WeightFromStyle: (Style and $7FF00000) shr 20; +$800 if high bit set.
function WeightFromStyle(Style: Cardinal): Integer;
begin
  Result := Integer((Style and $7FF00000) div $100000);
  if (Style and $80000000) <> 0 then Inc(Result, $800);
end;

function FontNotFoundProc(const Data, PDFFont: Pointer; const FontName: PAnsiChar;
                          Style: TFStyle; StdFontIndex: Integer; IsSymbolFont: LongBool): Integer; stdcall;
var s: Integer;
begin
  s := Style;
  if WeightFromStyle(Cardinal(s)) < 500 then s := (s and $F) or fsRegular;
  Result := gPDF.ReplaceFontA(PDFFont, 'Arial', s, True);
end;

function ReplaceICCProfileProc(const Data: Pointer; ProfileType: TICCProfileType; ColorSpace: Integer): Integer; stdcall;
begin
  case ProfileType of
    ictRGB:  Result := gPDF.ReplaceICCProfileA(Cardinal(ColorSpace), '../../../test_files/sRGB.icc');
    ictCMYK: Result := gPDF.ReplaceICCProfileA(Cardinal(ColorSpace), '../../../test_files/ISOcoated_v2_bas.ICC');
  else       Result := gPDF.ReplaceICCProfileA(Cardinal(ColorSpace), '../../../test_files/gray.icc');
  end;
end;

function ConvertFile(pdf: TLumasPDFCore; ConvType: Integer; const InFile, Invoice, OutFile: PAnsiChar): Boolean;
var
  ef, retval: Integer;
  convFlags: Cardinal;
begin
  Result := False;
  pdf.CreateNewPDFA('');
  pdf.SetDocInfoA(diProducer, '');

  case ConvType of
    Ord(ctFacturX_Comfort), Ord(ctFacturX_Extended), Ord(ctFacturX_XRechnung):
      convFlags := coDefault_PDFA_3;
  else
    Exit;   // We create e-invoices in this example and nothing else.
  end;

  pdf.CreateNewPDFA('');
  pdf.SetDocInfoA(diProducer, '');

  convFlags := coCheckImages_v or coRepairDamagedImages_v;

  pdf.SetImportFlags(ifImportAll or ifImportAsPage or ifPrepareForPDFA);
  pdf.SetImportFlags2(if2UseProxy);

  pdf.OpenImportFileA(InFile, Ord(ptOpen), '');
  pdf.ImportPDFFile(1, 1.0, 1.0);
  pdf.CloseImportFile;

  ef := pdf.AttachFileA(Invoice, 'EN 16931 compliant invoice', False);
  if ConvType <> Ord(ctFacturX_XRechnung) then
    pdf.AssociateEmbFile(adCatalog, -1, arAlternative, Cardinal(ef))
  else
    pdf.AssociateEmbFile(adCatalog, -1, arSource, Cardinal(ef));

  retval := pdf.CheckConformance(ConvType, convFlags, nil, @FontNotFoundProc, @ReplaceICCProfileProc);
  case retval of
    1: pdf.AddOutputIntentA('../../../test_files/sRGB.icc');
    2: pdf.AddOutputIntentA('../../../test_files/ISOcoated_v2_bas.ICC');
    3: pdf.AddOutputIntentA('../../../test_files/gray.icc');
  end;

  if pdf.HaveOpenDoc then
  begin
    if not pdf.OpenOutputFileA(OutFile) then Exit;
    Result := pdf.CloseFile;
  end;
end;

const
  outFile = 'out.pdf';
begin
  gPDF := TLumasPDFCore.Create;
  try
    gPDF.SetOnErrorProc(nil, @PDFError);
    gPDF.SetCMapDirA('../../../Resource/CMap', lcmDelayed or lcmRecursive);

    if ConvertFile(gPDF, Ord(ctFacturX_Comfort), '../../../test_files/test_invoice.pdf',
                   '../../../test_files/factur-x.xml', outFile) then
      Writeln('PDF file "' + outFile + '" successfully created!');
  finally
    gPDF.Free;
  end;
end.
